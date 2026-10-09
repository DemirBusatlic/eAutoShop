using eAutoShop.Model.Model;
using eAutoShop.Worker.Interfaces;
using RabbitMQ.Client;
using RabbitMQ.Client.Events;
using System.Net.Mail;
using System.Text;
using System.Text.Json;

namespace eAutoShop.Worker.Services
{
    public class PasswordResetEmailListener : BackgroundService
    {
        private const string QueueName = "password_reset_email";
        private const int MaximumAttempts = 3;

        private readonly IConnectionFactory _connectionFactory;
        private readonly IServiceProvider _serviceProvider;
        private readonly ILogger<PasswordResetEmailListener> _logger;

        private IConnection? _connection;
        private IChannel? _channel;

        public PasswordResetEmailListener(IConnectionFactory connectionFactory, IServiceProvider serviceProvider, ILogger<PasswordResetEmailListener> logger)
        {
            _connectionFactory = connectionFactory;
            _serviceProvider = serviceProvider;
            _logger = logger;
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            _connection = await _connectionFactory.CreateConnectionAsync(stoppingToken);

            _channel = await _connection.CreateChannelAsync(cancellationToken: stoppingToken);

            await _channel.QueueDeclareAsync(
                queue: QueueName,
                durable: true,
                exclusive: false,
                autoDelete: false,
                arguments: null,
                cancellationToken: stoppingToken);

            await _channel.BasicQosAsync(
                prefetchSize: 0,
                prefetchCount: 1,
                global: false,
                cancellationToken: stoppingToken);

            var consumer = new AsyncEventingBasicConsumer(_channel);

            consumer.ReceivedAsync += async (_, eventArgs) =>
            {
                await HandleMessage(eventArgs, stoppingToken);
            };

            await _channel.BasicConsumeAsync(
                queue: QueueName,
                autoAck: false,
                consumer: consumer,
                cancellationToken: stoppingToken);

            try
            {
                await Task.Delay(Timeout.Infinite, stoppingToken);
            }
            catch (OperationCanceledException)
                when (stoppingToken.IsCancellationRequested){}
        }

        private async Task HandleMessage(BasicDeliverEventArgs eventArgs, CancellationToken stoppingToken)
        {
            if (_channel == null)
            {
                return;
            }

            PasswordResetEmailModel notification;

            try
            {
                var body = eventArgs.Body.ToArray();
                var json = Encoding.UTF8.GetString(body);

                notification =JsonSerializer.Deserialize<PasswordResetEmailModel>(json)?? throw new JsonException("Password reset email message is empty.");
            }
            catch (Exception exception)
            {
                _logger.LogError(exception, "Invalid password reset email message.");

                await _channel.BasicNackAsync(
                    deliveryTag: eventArgs.DeliveryTag,
                    multiple: false,
                    requeue: false);

                return;
            }

            for (var attempt = 1; attempt <= MaximumAttempts; attempt++)
            {
                try
                {
                    using var scope = _serviceProvider.CreateScope();

                    var emailService =scope.ServiceProvider.GetRequiredService<IEmailService>();

                    await emailService.SendPasswordResetEmail(notification);

                    await _channel.BasicAckAsync(deliveryTag: eventArgs.DeliveryTag, multiple: false);

                    _logger.LogInformation("Password reset email sent to {Email}.", notification.Email);

                    return;
                }
                catch (SmtpFailedRecipientException exception)
                {
                    _logger.LogError(exception, "Password reset email recipient {Email} was rejected.", notification.Email);

                    await _channel.BasicNackAsync(
                        deliveryTag: eventArgs.DeliveryTag,
                        multiple: false,
                        requeue: false);

                    return;
                }
                catch (Exception exception)
                {
                    _logger.LogWarning(
                        exception,
                        "Password reset email attempt {Attempt}/{MaximumAttempts} failed for {Email}.",
                        attempt,
                        MaximumAttempts,
                        notification.Email);

                    if (attempt < MaximumAttempts)
                    {
                        var delay = TimeSpan.FromSeconds(Math.Pow(2, attempt - 1));

                        await Task.Delay(delay, stoppingToken);
                    }
                }
            }

            _logger.LogError("Password reset email could not be sent to {Email}. " +"The message will be returned to the queue.", notification.Email);

            await Task.Delay(TimeSpan.FromSeconds(10), stoppingToken);

            await _channel.BasicNackAsync(deliveryTag: eventArgs.DeliveryTag,multiple: false, requeue: true);
        }

        public override void Dispose()
        {
            _channel?.Dispose();
            _connection?.Dispose();

            base.Dispose();
        }
    }
}