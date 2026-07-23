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
        private readonly IConnectionFactory _connectionFactory;
        private readonly IServiceProvider _serviceProvider;

        private IConnection? _connection;
        private IChannel? _channel;

        public RabbitMqListener(
            IConnectionFactory connectionFactory,
            IServiceProvider serviceProvider)
        {
            _connectionFactory = connectionFactory;
            _serviceProvider = serviceProvider;
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            _connection = await _connectionFactory.CreateConnectionAsync(stoppingToken);
            _channel = await _connection.CreateChannelAsync(cancellationToken: stoppingToken);

            await _channel.QueueDeclareAsync(
                queue: "report_ready",
                durable: true,
                exclusive: false,
                autoDelete: false,
                arguments: null,
                cancellationToken: stoppingToken);

            var consumer = new AsyncEventingBasicConsumer(_channel);

            consumer.ReceivedAsync += async (sender, ea) =>
            {
                var body = ea.Body.ToArray();
                var message = Encoding.UTF8.GetString(body);

                var notification = JsonSerializer.Deserialize<ReportNotificationModel>(message);

                if (notification == null)
                    return;

                using var scope = _serviceProvider.CreateScope();

                var reportNotificationService =
                    scope.ServiceProvider.GetRequiredService<ReportNotificationService>();

                await reportNotificationService.SendServiceNotification(
                    notification.Username,
                    notification.NotificationType,
                    notification.Message);
            };

            await _channel.BasicConsumeAsync(
                queue: "report_ready",
                autoAck: true,
                consumer: consumer,
                cancellationToken: stoppingToken);
        }

        public override void Dispose()
        {
            _channel?.Dispose();
            _connection?.Dispose();
            base.Dispose();
        }
    }
}