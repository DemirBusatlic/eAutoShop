using eAutoShop.Worker.Interfaces;
using eAutoShop.Worker.Services;
using eAutoShop.Services.Database;
using Microsoft.EntityFrameworkCore;
using RabbitMQ.Client;

var builder = Host.CreateApplicationBuilder(args);

builder.Services.AddScoped<IGenerateProductReportService, GenerateProductReportService>();

builder.Services.AddSingleton<IConnectionFactory>(sp =>
{
    var hostName = Environment.GetEnvironmentVariable("RABBITMQ_HOST") ?? builder.Configuration["RabbitMQ:HostName"] ?? "localhost";

    var userName = Environment.GetEnvironmentVariable("RABBITMQ_USERNAME") ?? builder.Configuration["RabbitMQ:UserName"] ?? "guest";

    var password = Environment.GetEnvironmentVariable("RABBITMQ_PASSWORD") ?? builder.Configuration["RabbitMQ:Password"] ?? "guest";

    return new ConnectionFactory
    {
        HostName = hostName,
        UserName = userName,
        Password = password,
        RequestedHeartbeat = TimeSpan.FromSeconds(60),
        AutomaticRecoveryEnabled = true
    };
});

builder.Services.AddSingleton<RabbitMQService>();
builder.Services.AddHostedService<RabbitMqListener>();

var connectionString = builder.Configuration.GetConnectionString("DefaultConnection");

builder.Services.AddDbContext<AutoShopContext>(options => options.UseSqlServer(connectionString));

var host = builder.Build();
host.Run();
