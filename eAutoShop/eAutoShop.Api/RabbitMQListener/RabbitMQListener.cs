using eAutoShop.Api.SignalR;
using eAutoShop.Model.Model;
using RabbitMQ.Client;
using RabbitMQ.Client.Events;
using System.Text;
using System.Text.Json;

namespace eAutoShop.Api.RabbitMQListener
{
    public class RabbitMqListener : BackgroundService
    {
        private const string QueueName = "report_ready";
        private const int MaxProcessingAttempts = 3;

        private readonly IConnectionFactory _connectionFactory;
        private readonly IServiceProvider _serviceProvider;
        private readonly ILogger<RabbitMqListener> _logger;

        private IConnection? _connection;
        private IChannel? _channel;

        public RabbitMqListener(IConnectionFactory connectionFactory, IServiceProvider serviceProvider, ILogger<RabbitMqListener> logger)
        {
            _connectionFactory = connectionFactory;
            _serviceProvider = serviceProvider;
            _logger = logger;
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            _connection =await _connectionFactory.CreateConnectionAsync(stoppingToken);

            _channel =await _connection.CreateChannelAsync(cancellationToken: stoppingToken);

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

            var consumer =new AsyncEventingBasicConsumer(_channel);

            consumer.ReceivedAsync += async (_, eventArgs) =>
            {
                await ProcessMessageAsync(eventArgs, stoppingToken);
            };

            await _channel.BasicConsumeAsync(
                queue: QueueName,
                autoAck: false,
                consumer: consumer,
                cancellationToken: stoppingToken);

            try
            {
                await Task.Delay(Timeout.Infinite,stoppingToken);
            }
            catch (OperationCanceledException)
                when (stoppingToken.IsCancellationRequested)
            {
                _logger.LogInformation("Zaustavlja se report_ready RabbitMQ consumer.");
            }
        }

        private async Task ProcessMessageAsync(BasicDeliverEventArgs eventArgs, CancellationToken stoppingToken)
        {
            if (_channel == null)
            {
                return;
            }

            ReportNotificationModel? notification;

            try
            {
                var message = Encoding.UTF8.GetString(eventArgs.Body.Span);

                notification =JsonSerializer.Deserialize<ReportNotificationModel>(message);
            }
            catch (JsonException exception)
            {
                _logger.LogError(exception,"Neispravna JSON poruka primljena iz queuea {QueueName}.",QueueName);

                await _channel.BasicNackAsync(
                    deliveryTag: eventArgs.DeliveryTag,
                    multiple: false,
                    requeue: false,
                    cancellationToken: stoppingToken);

                return;
            }

            if (notification == null || string.IsNullOrWhiteSpace(notification.Username) || string.IsNullOrWhiteSpace(notification.NotificationType) || string.IsNullOrWhiteSpace(notification.Message))
            {
                _logger.LogError("Neispravna report_ready poruka. " + "Obavezna polja nisu popunjena.");

                await _channel.BasicNackAsync(
                    deliveryTag: eventArgs.DeliveryTag,
                    multiple: false,
                    requeue: false,
                    cancellationToken: stoppingToken);

                return;
            }

            for (var attempt = 1; attempt <= MaxProcessingAttempts; attempt++)
            {
                try
                {
                    using var scope = _serviceProvider.CreateScope();

                    var reportNotificationService = scope.ServiceProvider.GetRequiredService<ReportNotificationService>();

                    await reportNotificationService.SendServiceNotification(
                            notification.Username,
                            notification.NotificationType,
                            notification.Message);

                    await _channel.BasicAckAsync(
                        deliveryTag: eventArgs.DeliveryTag,
                        multiple: false,
                        cancellationToken: stoppingToken);

                    _logger.LogInformation("report_ready poruka je uspješno obrađena " + "i potvrđena za korisnika {Username}.", notification.Username);

                    return;
                }
                catch (OperationCanceledException)
                    when (stoppingToken.IsCancellationRequested)
                {
                    _logger.LogInformation("Obrada report_ready poruke je prekinuta " + "zbog zaustavljanja aplikacije.");

                    return;
                }
                catch (Exception exception)
                {
                    if (attempt < MaxProcessingAttempts)
                    {
                        var delay =TimeSpan.FromSeconds(Math.Pow(2, attempt - 1));

                        _logger.LogWarning(exception, "Pokušaj {Attempt}/{MaxAttempts} slanja " + "report notifikacije nije uspio. " + "Novi pokušaj za {DelaySeconds} sekundi.", attempt, MaxProcessingAttempts, delay.TotalSeconds);

                        await Task.Delay(delay, stoppingToken);

                        continue;
                    }

                    var shouldRequeue = !eventArgs.Redelivered;

                    _logger.LogError(exception, shouldRequeue? "Slanje report notifikacije nije uspjelo " + "nakon {MaxAttempts} pokušaja. " + "Poruka će jednom biti vraćena u queue." : "Slanje report notifikacije nije uspjelo " + "ni nakon ponovnog dostavljanja. " + "Poruka neće biti ponovo vraćena u queue.", MaxProcessingAttempts);

                    await _channel.BasicNackAsync(
                        deliveryTag: eventArgs.DeliveryTag,
                        multiple: false,
                        requeue: shouldRequeue,
                        cancellationToken: stoppingToken);

                    return;
                }
            }
        }

        public override void Dispose()
        {
            _channel?.Dispose();
            _connection?.Dispose();

            base.Dispose();
        }
    }
}