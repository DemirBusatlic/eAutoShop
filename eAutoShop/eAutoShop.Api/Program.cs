using eAutoShop.Api.Filters;
using eAutoShop.Api.RabbitMQListener;
using eAutoShop.Api.SignalR;
using eAutoShop.Model.Utilities;
using eAutoShop.Model.Model;
using eAutoShop.Services;
using eAutoShop.Services.Mapping;
using eAutoShop.Services.Database;
using eAutoShop.Services.Interfaces;
using eAutoShop.Services.Services;
using eAutoShop.Services.Services.eAutoShop.Services.Database;
using eAutoShop.Services.StateMachineService.AppointmentStateMachine;
using eAutoShop.Services.StateMachineService.AutoShopServiceStateMachine;
using eAutoShop.Services.StateMachineService.OrderStateMachine;
using eAutoShop.Services.StateMachineService.ProductStateMachine;
using Mapster;
using MapsterMapper;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using RabbitMQ.Client;
using ServiceStack.Text;
using Stripe;
using System.Globalization;
using System.IdentityModel.Tokens.Jwt;
using System.Text;


var builder = WebApplication.CreateBuilder(args);

builder.Services.AddHttpContextAccessor();


var stripeSecretKey = Environment.GetEnvironmentVariable("STRIPE_SECRET_KEY");
var stripePublishableKey = Environment.GetEnvironmentVariable("STRIPE_PUBLISHABLE_KEY");
var jwtSecretFromEnv = Environment.GetEnvironmentVariable("JWT_SECRET_KEY");

builder.Services.AddScoped<IRoleService, RoleService>();
builder.Services.AddScoped<ICityService, CityService>();
builder.Services.AddScoped<IUserService, UserService>();
builder.Services.AddScoped<ICarModelService, CarModelService>();
builder.Services.AddScoped<IProductCategoryService, ProductCategoryService>();
builder.Services.AddScoped<IProductService, ProductsService>();
builder.Services.AddScoped<IOrderItemService, OrderItemService>();
builder.Services.AddScoped<IOrderService, OrderService>();
builder.Services.AddScoped<IAutoShopServiceService, AutoShopServiceService>();
builder.Services.AddScoped<IServiceTypeService, ServiceTypeService>();
builder.Services.AddScoped<IAppointmentDetailService, AppointmentDetailService>();
builder.Services.AddScoped<IAppointmentService, AppointmentService>();
builder.Services.AddScoped<IStaffReviewService, StaffReviewService>();
builder.Services.AddScoped<IProductReviewService, ProductReviewService>();
builder.Services.AddScoped<IStripeService, StripeService>();
builder.Services.AddScoped<IReportService, ReportService>();

builder.Services.AddScoped<IRecommenderTrainService, RecommenderTrainService>();
builder.Services.AddScoped<IRecommenderPredictService, RecommenderPredictService>();



builder.Services.AddScoped<BaseProductState>();
builder.Services.AddScoped<InitialProductState>();
builder.Services.AddScoped<DraftProductState>();
builder.Services.AddScoped<ActiveProductState>();

builder.Services.AddScoped<BaseOrderState>();
builder.Services.AddScoped<InitialOrderState>();
builder.Services.AddScoped<CancelledOrderState>();
builder.Services.AddScoped<AcceptedOrderState>();
builder.Services.AddScoped<CompletedOrderState>();
builder.Services.AddScoped<MissingPaymentOrderState>();
builder.Services.AddScoped<OnHoldOrderState>();
builder.Services.AddScoped<PaymentFailedOrderState>();
builder.Services.AddScoped<RejectedOrderState>();

builder.Services.AddScoped<BaseAutoShopServiceState>();
builder.Services.AddScoped<InitialAutoShopServiceState>();
builder.Services.AddScoped<DraftAutoShopServiceState>();
builder.Services.AddScoped<ActiveAutoShopServiceState>();
builder.Services.AddScoped<HiddenAutoShopServiceState>();

builder.Services.AddScoped<BaseAppointmentState>();
builder.Services.AddScoped<InitialAppointmentState>();
builder.Services.AddScoped<PendingAppointmentState>();
builder.Services.AddScoped<ConfirmedAppointmentState>();
builder.Services.AddScoped<OngoingAppointmentState>();
builder.Services.AddScoped<RejectedAppointmentState>();
builder.Services.AddScoped<CancelledAppointmentState>();
builder.Services.AddScoped<CompletedAppointmentState>();

builder.Services.AddSignalR();
builder.Services.AddScoped<NotificationService>();
builder.Services.AddScoped<ReportNotificationService>();

builder.Services.AddSingleton<IConnectionFactory>(sp =>
{
    var hostName = Environment.GetEnvironmentVariable("RABBITMQ_HOST") ?? builder.Configuration["RabbitMQ:HostName"];
    var userName = Environment.GetEnvironmentVariable("RABBITMQ_USERNAME") ?? builder.Configuration["RabbitMQ:UserName"];
    var password = Environment.GetEnvironmentVariable("RABBITMQ_PASSWORD") ?? builder.Configuration["RabbitMQ:Password"];

    return new ConnectionFactory()
    {
        HostName = hostName,
        UserName = userName,
        Password = password,
        RequestedHeartbeat = TimeSpan.FromSeconds(60),
        AutomaticRecoveryEnabled = true
    };
});

builder.Services.AddHostedService<RabbitMqListener>();
builder.Services.AddSingleton<RabbitMQService>();

var key = !string.IsNullOrWhiteSpace(jwtSecretFromEnv)
    ? jwtSecretFromEnv
    : builder.Configuration["JwtSettings:Secret"];

if (string.IsNullOrWhiteSpace(key))
{
    throw new Exception("JWT secret nije definisan (ni ENV ni appsettings)");
}

var keyBytes = Encoding.ASCII.GetBytes(key);


builder.Services.AddScoped<IAuthTokenService, AuthTokenService>(provider =>
{
    var context = provider.GetRequiredService<AutoShopContext>();
    var mapper = provider.GetRequiredService<IMapper>();
    return new AuthTokenService(key, context, mapper);
});

builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
})
.AddJwtBearer(options =>
{
    options.RequireHttpsMetadata = false;
    options.SaveToken = true;
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuerSigningKey = true,
        IssuerSigningKey = new SymmetricSecurityKey(keyBytes),
        ValidateIssuer = false,
        ValidateAudience = false
    };
    options.Events = new JwtBearerEvents
    {
        OnTokenValidated = async context =>
        {
            var authService = context.HttpContext.RequestServices
                .GetRequiredService<IAuthTokenService>();

            var authHeader = context.HttpContext.Request.Headers["Authorization"].FirstOrDefault();

            if (string.IsNullOrWhiteSpace(authHeader))
            {
                context.Fail("Missing Authorization header.");
                return;
            }

            var token = authHeader.StartsWith("Bearer ", StringComparison.OrdinalIgnoreCase)
                ? authHeader.Substring("Bearer ".Length).Trim()
                : authHeader;

            if (string.IsNullOrWhiteSpace(token))
            {
                context.Fail("Invalid token.");
                return;
            }

            if (await authService.IsTokenRevoked(token))
            {
                context.Fail("Session expired.");
            }
        },



    OnMessageReceived = context =>
        {
            var accessToken = context.Request.Query["access_token"];

            var path = context.HttpContext.Request.Path;
            if (!string.IsNullOrEmpty(accessToken) &&
            (path.StartsWithSegments("/chathub") || path.StartsWithSegments("/reportNotificationHub") || path.StartsWithSegments("/notificationHub")))
            {
                context.Token = accessToken;
            }

            return Task.CompletedTask;
        }
    };
});
builder.Services.AddControllers(x =>
{
    x.Filters.Add<ErrorFilter>();
});

if (!string.IsNullOrEmpty(stripeSecretKey) && !string.IsNullOrEmpty(stripePublishableKey))
{
    builder.Services.Configure<StripeSettings>(options =>
    {
        options.SecretKey = stripeSecretKey;
        options.PublishableKey = stripePublishableKey;
    });
}
else
{
    builder.Services.Configure<StripeSettings>(builder.Configuration.GetSection("Stripe"));
}

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Name = "Authorization",
        Type = SecuritySchemeType.Http,
        Scheme = "bearer",
        BearerFormat = "JWT",
        In = ParameterLocation.Header
    });

    c.AddSecurityRequirement(new OpenApiSecurityRequirement
    {
        {
            new OpenApiSecurityScheme
            {
                Reference = new OpenApiReference
                {
                    Type = ReferenceType.SecurityScheme,
                    Id = "Bearer"
                }
            },
            Array.Empty<string>()
        }
    });
});
builder.Configuration.AddEnvironmentVariables();

var connectionString = builder.Configuration.GetConnectionString("DefaultConnection");
builder.Services.AddDbContext<AutoShopContext>(options =>
    options.UseSqlServer(connectionString));

TypeAdapterConfig.GlobalSettings.Scan(typeof(OrderMappingConfig).Assembly);

builder.Services.AddSingleton(TypeAdapterConfig.GlobalSettings);

builder.Services.AddScoped<IMapper, ServiceMapper>();

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();

app.UseAuthentication();

app.UseAuthorization();

app.MapControllers();
app.MapHub<NotificationHub>("/notificationHub");
app.MapHub<ReportNotificationHub>("/reportNotificationHub");

var stripeSettings = app.Services.GetRequiredService<IOptions<StripeSettings>>().Value;
StripeConfiguration.ApiKey = stripeSettings.SecretKey;

using (var scope = app.Services.CreateScope())
{
    try
    {
        var recommenderTrainService = scope.ServiceProvider
            .GetRequiredService<IRecommenderTrainService>();

        recommenderTrainService.TrainProductsModel();

        app.Logger.LogInformation(
            "Model preporuka je uspješno treniran."
        );
    }
    catch (Exception ex)
    {
        app.Logger.LogWarning(
            ex,
            "Model preporuka nije treniran. API će nastaviti s radom."
        );
    }
}



app.Run();
