using eAutoShop.Model.Request;
using RabbitMQ.Client;
using System;
using System.Text;
using System.Text.Json;
using System.Threading.Tasks;

namespace eAutoShop.Services.Services
{
    namespace eAutoShop.Services.Database
    {
        public class RabbitMQService : IAsyncDisposable
        {
            private readonly Lazy<Task<IConnection>> _connectionTask;

            public RabbitMQService(IConnectionFactory connectionFactory)
            {
                _connectionTask = new Lazy<Task<IConnection>>(
                    () => connectionFactory.CreateConnectionAsync()
                );
            }

            public Task SendReportGenerationRequest(
                ProductReportRequest reportRequest)
            {
                return SendMessage(
                    queue: "generate_product_report",
                    request: reportRequest);
            }

            public Task SendTopSellingProductsReportRequest(
                ProductReportRequest reportRequest)
            {
                return SendMessage(
                    queue: "generate_top_selling_products_report",
                    request: reportRequest);
            }

            public Task SendSalesByCategoryReportRequest(
                ReportRequest reportRequest)
            {
                return SendMessage(
                    queue: "generate_sales_by_category_report",
                    request: reportRequest);
            }

            public Task SendMonthlyRevenueReportRequest(
                ReportRequest reportRequest)
            {
                return SendMessage(
                    queue: "generate_monthly_revenue_report",
                    request: reportRequest);
            }

            public Task SendTopCustomersReportRequest(
                ReportRequest reportRequest)
            {
                return SendMessage(
                    queue: "generate_top_customers_report",
                    request: reportRequest);
            }

            private async Task SendMessage<TRequest>(
                string queue,
                TRequest request)
            {
                var connection = await _connectionTask.Value;

                await using var channel =
                    await connection.CreateChannelAsync();

                await channel.QueueDeclareAsync(
                    queue: queue,
                    durable: true,
                    exclusive: false,
                    autoDelete: false,
                    arguments: null);

                var message = JsonSerializer.Serialize(request);
                var body = Encoding.UTF8.GetBytes(message);

                await channel.BasicPublishAsync(
                    exchange: "",
                    routingKey: queue,
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
    }
}