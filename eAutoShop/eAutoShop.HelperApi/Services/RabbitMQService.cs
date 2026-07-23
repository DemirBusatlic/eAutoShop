using System.Text;
using System.Text.Json;
using RabbitMQ.Client;
using eAutoShop.Model.Model;

public class RabbitMQService : IDisposable
{
    private readonly IConnection _connection;

    public RabbitMQService(IConnectionFactory connectionFactory)
    {
        _connection = connectionFactory.CreateConnectionAsync().GetAwaiter().GetResult();
    }

    public async Task SendReportNotification(ReportNotificationModel notification)
    {
        var message = JsonSerializer.Serialize(notification);
        var body = Encoding.UTF8.GetBytes(message);

        await using var channel = await _connection.CreateChannelAsync();

        await channel.QueueDeclareAsync(
            queue: "report_ready",
            durable: true,
            exclusive: false,
            autoDelete: false,
            arguments: null);

        await channel.BasicPublishAsync(
            exchange: "",
            routingKey: "report_ready",
            body: body);
    }

    public void Dispose()
    {
        _connection.Dispose();
    }
}

