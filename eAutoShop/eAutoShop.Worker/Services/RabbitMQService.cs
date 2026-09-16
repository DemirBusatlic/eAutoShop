using System.Text;
using System.Text.Json;
using eAutoShop.Model.Model;
using RabbitMQ.Client;

public class RabbitMQService : IAsyncDisposable
{
    private readonly Lazy<Task<IConnection>> _connectionTask;

    public RabbitMQService(IConnectionFactory connectionFactory)
    {
        _connectionTask = new Lazy<Task<IConnection>>(() => connectionFactory.CreateConnectionAsync());
    }

    public async Task SendReportNotification(ReportNotificationModel notification)
    {
        var connection = await _connectionTask.Value;

        await using var channel = await connection.CreateChannelAsync();

        await channel.QueueDeclareAsync(
            queue: "report_ready",
            durable: true,
            exclusive: false,
            autoDelete: false,
            arguments: null);

        var message = JsonSerializer.Serialize(notification);
        var body = Encoding.UTF8.GetBytes(message);

        await channel.BasicPublishAsync(
            exchange: "",
            routingKey: "report_ready",
            body: body);
    }

    public async ValueTask DisposeAsync()
    {
        if (!_connectionTask.IsValueCreated)
        {
            return;
        }

        var connection = await _connectionTask.Value;
        await connection.DisposeAsync();
    }
}