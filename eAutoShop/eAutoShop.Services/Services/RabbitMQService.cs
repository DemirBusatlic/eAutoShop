using eAutoShop.Model.Request;
using RabbitMQ.Client;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Text.Json;
using System.Threading.Tasks;

namespace eAutoShop.Services.Services
{
    namespace eAutoShop.Services.Database
    {
        public class RabbitMQService : IDisposable
        {
            private readonly IConnection _connection;

            public RabbitMQService(IConnectionFactory connectionFactory)
            {
                _connection = connectionFactory
                    .CreateConnectionAsync()
                    .GetAwaiter()
                    .GetResult();
            }

            public async Task SendReportGenerationRequest(ProductReportRequest reportRequest)
            {
                await using var channel = await _connection.CreateChannelAsync();

                await channel.QueueDeclareAsync(
                    queue: "generate_product_report",
                    durable: true,
                    exclusive: false,
                    autoDelete: false,
                    arguments: null);

                var message = JsonSerializer.Serialize(reportRequest);
                var body = Encoding.UTF8.GetBytes(message);

                await channel.BasicPublishAsync(
                    exchange: "",
                    routingKey: "generate_product_report",
                    body: body);
            }

            public async Task SendTopSellingProductsReportRequest(ProductReportRequest reportRequest)
            {
                await using var channel = await _connection.CreateChannelAsync();

                await channel.QueueDeclareAsync(
                    queue: "generate_top_selling_products_report",
                    durable: true,
                    exclusive: false,
                    autoDelete: false,
                    arguments: null);

                var message = JsonSerializer.Serialize(reportRequest);
                var body = Encoding.UTF8.GetBytes(message);

                await channel.BasicPublishAsync(
                    exchange: "",
                    routingKey: "generate_top_selling_products_report",
                    body: body);
            }

            public async Task SendSalesByCategoryReportRequest(ReportRequest reportRequest)
            {
                await using var channel = await _connection.CreateChannelAsync();

                await channel.QueueDeclareAsync(
                    queue: "generate_sales_by_category_report",
                    durable: true,
                    exclusive: false,
                    autoDelete: false,
                    arguments: null);

                var message = JsonSerializer.Serialize(reportRequest);
                var body = Encoding.UTF8.GetBytes(message);

                await channel.BasicPublishAsync(
                    exchange: "",
                    routingKey: "generate_sales_by_category_report",
                    body: body);
            }

            public async Task SendMonthlyRevenueReportRequest(ReportRequest reportRequest)
            {
                await using var channel = await _connection.CreateChannelAsync();

                await channel.QueueDeclareAsync(
                    queue: "generate_monthly_revenue_report",
                    durable: true,
                    exclusive: false,
                    autoDelete: false,
                    arguments: null);

                var message = JsonSerializer.Serialize(reportRequest);
                var body = Encoding.UTF8.GetBytes(message);

                await channel.BasicPublishAsync(
                    exchange: "",
                    routingKey: "generate_monthly_revenue_report",
                    body: body);
            }

            public async Task SendTopCustomersReportRequest(ReportRequest reportRequest)
            {
                await using var channel = await _connection.CreateChannelAsync();

                await channel.QueueDeclareAsync(
                    queue: "generate_top_customers_report",
                    durable: true,
                    exclusive: false,
                    autoDelete: false,
                    arguments: null);

                var message = JsonSerializer.Serialize(reportRequest);
                var body = Encoding.UTF8.GetBytes(message);

                await channel.BasicPublishAsync(
                    exchange: "",
                    routingKey: "generate_top_customers_report",
                    body: body);
            }

            public void Dispose()
            {
                _connection.Dispose();
            }
        }
    }
    }
