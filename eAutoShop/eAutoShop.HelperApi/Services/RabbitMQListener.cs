using eAutoShop.HelperApi.Interfaces;
using eAutoShop.Model.Request;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using RabbitMQ.Client;
using RabbitMQ.Client.Events;
using System.Text;
using System.Text.Json;

namespace eAutoShop.HelperApi.Services
{
    public class RabbitMqListener : BackgroundService
    {
        private readonly IConnectionFactory _connectionFactory;
        private readonly IServiceProvider _serviceProvider;

        private IConnection? _connection;
        private IChannel? _channel;

        public RabbitMqListener(IConnectionFactory connectionFactory,IServiceProvider serviceProvider)
        {
            _connectionFactory = connectionFactory;
            _serviceProvider = serviceProvider;
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            _connection = await _connectionFactory.CreateConnectionAsync(stoppingToken);
            _channel = await _connection.CreateChannelAsync(cancellationToken: stoppingToken);

            await _channel.QueueDeclareAsync(
                queue: "generate_product_report",
                durable: true,
                exclusive: false,
                autoDelete: false,
                arguments: null,
                cancellationToken: stoppingToken);

            await _channel.QueueDeclareAsync(
                queue: "generate_top_selling_products_report",
                durable: true,
                exclusive: false,
                autoDelete: false,
                arguments: null,
                cancellationToken: stoppingToken);

            await _channel.QueueDeclareAsync(
                queue: "generate_monthly_revenue_report",
                durable: true,
                exclusive: false,
                autoDelete: false,
                arguments: null,
                cancellationToken: stoppingToken);

            await _channel.QueueDeclareAsync(
                queue: "generate_sales_by_category_report",
                durable: true,
                exclusive: false,
                autoDelete: false,
                arguments: null,
                cancellationToken: stoppingToken);

            await _channel.QueueDeclareAsync(
                queue: "generate_top_customers_report",
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

                var reportRequest = JsonSerializer.Deserialize<ReportRequest>(message);
                var productreportRequest= JsonSerializer.Deserialize<ProductReportRequest>(message);

                if (reportRequest == null)
                    return;

                using var scope = _serviceProvider.CreateScope();

                var generateReportService =
                    scope.ServiceProvider.GetRequiredService<IGenerateProductReportService>();

                if (ea.RoutingKey == "generate_product_report")
                {
                    var request = JsonSerializer.Deserialize<ProductReportRequest>(message);

                    if (request == null)
                        return;

                    await generateReportService.GenerateReport(request);
                }
                else if (ea.RoutingKey == "generate_top_selling_products_report")
                {
                    var request = JsonSerializer.Deserialize<ProductReportRequest>(message);

                    if (request == null)
                        return;

                    await generateReportService.GenerateTopSellingProductsReport(request);
                }
                else if (ea.RoutingKey == "generate_monthly_revenue_report")
                {
                    var request = JsonSerializer.Deserialize<ReportRequest>(message);

                    if (request == null)
                        return;

                    await generateReportService.GenerateMonthlyRevenueReport(request);
                }
                else if (ea.RoutingKey == "generate_sales_by_category_report")
                {
                    var request = JsonSerializer.Deserialize<ReportRequest>(message);

                    if (request == null)
                        return;

                    await generateReportService.GenerateSalesByCategoryReport(request);
                }
                else if (ea.RoutingKey == "generate_top_customers_report")
                {
                    var request = JsonSerializer.Deserialize<ReportRequest>(message);

                    if (request == null)
                        return;

                    await generateReportService.GenerateTopCustomersReport(request);
                }
            };

            await _channel.BasicConsumeAsync(
                queue: "generate_product_report",
                autoAck: true,
                consumer: consumer,
                cancellationToken: stoppingToken);

            await _channel.BasicConsumeAsync(
                queue: "generate_top_selling_products_report",
                autoAck: true,
                consumer: consumer,
                cancellationToken: stoppingToken);

            await _channel.BasicConsumeAsync(
                queue: "generate_monthly_revenue_report",
                autoAck: true,
                consumer: consumer,
                cancellationToken: stoppingToken);

            await _channel.BasicConsumeAsync(
                queue: "generate_sales_by_category_report",
                autoAck: true,
                consumer: consumer,
                cancellationToken: stoppingToken);

            await _channel.BasicConsumeAsync(
                queue: "generate_top_customers_report",
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
