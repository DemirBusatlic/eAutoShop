using eAutoShop.Worker.Interfaces;
using eAutoShop.Model.Model;
using eAutoShop.Model.Request;
using eAutoShop.Services.Database;
using eAutoShop.Services.Helpers;
using Microsoft.EntityFrameworkCore;
using System.Globalization;
using System.Text;

namespace eAutoShop.Worker.Services
{
    public class GenerateProductReportService : IGenerateProductReportService
    {
        private readonly AutoShopContext _context;
        private readonly RabbitMQService _rabbitMQService;
        private readonly ILogger<GenerateProductReportService> _logger;
        private readonly string _reportsPath;

        public GenerateProductReportService(AutoShopContext context,RabbitMQService rabbitMQService,IConfiguration configuration,ILogger<GenerateProductReportService> logger)
        {
            _context = context;
            _rabbitMQService = rabbitMQService;
            _logger = logger;
            _reportsPath = configuration["REPORTS_PATH"] ?? "Reports";

            Directory.CreateDirectory(_reportsPath);
        }

        public async Task GenerateReport(ProductReportRequest request)
        {
            const string fileName = "product_report.csv";

            var filePath = InvalidateReport(fileName);

            var query = _context.Products
                .Include(x => x.ProductCategory)
                .Include(x => x.OrderItems)
                .ThenInclude(x => x.Order)
                .AsQueryable();

            if (request.ProductCategoryId != null)
            {
                query = query.Where(
                    x => x.ProductCategoryId ==
                         request.ProductCategoryId);
            }

            if (request.ProductId != null)
            {
                query = query.Where(
                    x => x.Id == request.ProductId);
            }

            var products = await query.ToListAsync();

            if (!products.Any())
            {
                await SendNotification(
                    request.Username,
                    "productreport",
                    "Nema proizvoda za generisanje izvještaja.");

                return;
            }

            var csvReport = new StringBuilder();

            csvReport.AppendLine(
                CreateCsvRow(
                    "ProductId",
                    "ProductName",
                    "Category",
                    "Price",
                    "Discount",
                    "DiscountedPrice",
                    "TotalSold",
                    "TotalRevenue"));

            foreach (var product in products)
            {
                var orderItems = product.OrderItems
                    .Where(
                        x => x.Order.State ==
                             OrderStates.Completed)
                    .AsEnumerable();

                if (request.StartDate != null)
                {
                    orderItems = orderItems.Where(
                        x => x.Order.OrderDate.Date >=
                             request.StartDate.Value.Date);
                }

                if (request.EndDate != null)
                {
                    orderItems = orderItems.Where(
                        x => x.Order.OrderDate.Date <=
                             request.EndDate.Value.Date);
                }

                var totalSold = orderItems.Sum(x => x.Quantity);

                var totalRevenue = orderItems.Sum(
                    x => x.TotalItemPriceDiscounted);

                csvReport.AppendLine(
                    CreateCsvRow(
                        product.Id,
                        product.Name,
                        product.ProductCategory?.Name ??
                            "Bez kategorije",
                        product.Price,
                        product.Discount,
                        product.DiscountedPrice,
                        totalSold,
                        totalRevenue.ToString(
                            "F2",
                            CultureInfo.InvariantCulture)));
            }

            _logger.LogInformation(
                "Generisanje izvještaja na putanji {FilePath}.",
                filePath);

            await WriteReportAtomically(
                filePath,
                csvReport.ToString());

            await SendNotification(
                request.Username,
                "productreport",
                "Izvještaj za proizvode je uspješno generisan.");
        }

        public async Task GenerateTopSellingProductsReport(
    ProductReportRequest request)
        {
            const string fileName =
                "top_selling_products_report.csv";

            var filePath = InvalidateReport(fileName);

            var query = _context.OrderItems
                .Include(x => x.Product)
                .ThenInclude(x => x.ProductCategory)
                .Include(x => x.Order)
                .Where(
                    x => x.Order.State ==
                         OrderStates.Completed)
                .AsQueryable();

            if (request.StartDate != null)
            {
                query = query.Where(
                    x => x.Order.OrderDate.Date >=
                         request.StartDate.Value.Date);
            }

            if (request.EndDate != null)
            {
                query = query.Where(
                    x => x.Order.OrderDate.Date <=
                         request.EndDate.Value.Date);
            }

            if (request.ProductCategoryId != null)
            {
                query = query.Where(
                    x => x.Product.ProductCategoryId ==
                         request.ProductCategoryId);
            }

            if (request.ProductId != null)
            {
                query = query.Where(
                    x => x.ProductId == request.ProductId);
            }

            var data = await query
                .GroupBy(x => new
                {
                    x.ProductId,
                    ProductName = x.Product.Name,
                    CategoryName =
                        x.Product.ProductCategory != null
                            ? x.Product.ProductCategory.Name
                            : "Bez kategorije"
                })
                .Select(group => new
                {
                    group.Key.ProductId,
                    group.Key.ProductName,
                    group.Key.CategoryName,
                    TotalSold = group.Sum(x => x.Quantity),
                    TotalRevenue = group.Sum(
                        x => x.TotalItemPriceDiscounted)
                })
                .OrderByDescending(x => x.TotalSold)
                .Take(10)
                .ToListAsync();

            if (!data.Any())
            {
                await SendNotification(
                    request.Username,
                    "topsellingproductsreport",
                    "Nema podataka za generisanje izvještaja.");

                return;
            }

            var csvReport = new StringBuilder();

            csvReport.AppendLine(
                CreateCsvRow(
                    "ProductId",
                    "ProductName",
                    "Category",
                    "TotalSold",
                    "TotalRevenue"));

            foreach (var item in data)
            {
                csvReport.AppendLine(
                    CreateCsvRow(
                        item.ProductId,
                        item.ProductName,
                        item.CategoryName,
                        item.TotalSold,
                        item.TotalRevenue.ToString(
                            "F2",
                            CultureInfo.InvariantCulture)));
            }

            _logger.LogInformation(
                "Generisanje izvještaja na putanji {FilePath}.",
                filePath);

            await WriteReportAtomically(
                filePath,
                csvReport.ToString());

            await SendNotification(
                request.Username,
                "topsellingproductsreport",
                "Izvještaj najprodavanijih proizvoda je uspješno generisan.");
        }

        public async Task GenerateSalesByCategoryReport(
     ReportRequest request)
        {
            const string fileName =
                "sales_by_category_report.csv";

            var filePath = InvalidateReport(fileName);

            var query = _context.OrderItems
                .Include(x => x.Product)
                .ThenInclude(x => x.ProductCategory)
                .Include(x => x.Order)
                .Where(
                    x => x.Order.State ==
                         OrderStates.Completed)
                .AsQueryable();

            if (request.StartDate != null)
            {
                query = query.Where(
                    x => x.Order.OrderDate.Date >=
                         request.StartDate.Value.Date);
            }

            if (request.EndDate != null)
            {
                query = query.Where(
                    x => x.Order.OrderDate.Date <=
                         request.EndDate.Value.Date);
            }

            var data = await query
                .GroupBy(x => new
                {
                    CategoryId =
                        x.Product.ProductCategoryId,
                    CategoryName =
                        x.Product.ProductCategory != null
                            ? x.Product.ProductCategory.Name
                            : "Bez kategorije"
                })
                .Select(group => new
                {
                    group.Key.CategoryId,
                    group.Key.CategoryName,
                    TotalSold = group.Sum(x => x.Quantity),
                    TotalRevenue = group.Sum(
                        x => x.TotalItemPriceDiscounted)
                })
                .OrderByDescending(x => x.TotalRevenue)
                .ToListAsync();

            if (!data.Any())
            {
                await SendNotification(
                    request.Username,
                    "salesbycategoryreport",
                    "Nema podataka za generisanje izvještaja.");

                return;
            }

            var csvReport = new StringBuilder();

            csvReport.AppendLine(
                CreateCsvRow(
                    "CategoryId",
                    "CategoryName",
                    "TotalSold",
                    "TotalRevenue"));

            foreach (var item in data)
            {
                csvReport.AppendLine(
                    CreateCsvRow(
                        item.CategoryId,
                        item.CategoryName,
                        item.TotalSold,
                        item.TotalRevenue.ToString(
                            "F2",
                            CultureInfo.InvariantCulture)));
            }

            _logger.LogInformation(
                "Generisanje izvještaja na putanji {FilePath}.",
                filePath);

            await WriteReportAtomically(
                filePath,
                csvReport.ToString());

            await SendNotification(
                request.Username,
                "salesbycategoryreport",
                "Izvještaj prodaje po kategorijama je uspješno generisan.");
        }

        public async Task GenerateMonthlyRevenueReport(
       ReportRequest request)
        {
            const string fileName =
                "monthly_revenue_report.csv";

            var filePath = InvalidateReport(fileName);

            var utcToday = DateTime.UtcNow.Date;

            var startDate =
                request.StartDate?.Date ??
                utcToday.AddMonths(-1);

            var endDate =
                request.EndDate?.Date ??
                utcToday;

            var orders = await _context.Orders
                .Where(
                    x => x.State == OrderStates.Completed &&
                         x.OrderDate.Date >= startDate &&
                         x.OrderDate.Date <= endDate)
                .ToListAsync();

            if (!orders.Any())
            {
                await SendNotification(
                    request.Username,
                    "monthlyrevenuereport",
                    "Nema narudžbi za generisanje mjesečnog izvještaja.");

                return;
            }

            var csvReport = new StringBuilder();

            csvReport.AppendLine(
                CreateCsvRow(
                    "Date",
                    "Revenue"));

            for (var date = startDate;
                 date <= endDate;
                 date = date.AddDays(1))
            {
                var dailyRevenue = orders
                    .Where(
                        x => x.OrderDate.Date == date.Date)
                    .Sum(x => x.TotalAmount);

                csvReport.AppendLine(
                    CreateCsvRow(
                        date.ToString(
                            "yyyy-MM-dd",
                            CultureInfo.InvariantCulture),
                        dailyRevenue.ToString(
                            "F2",
                            CultureInfo.InvariantCulture)));
            }

            _logger.LogInformation(
                "Generisanje izvještaja na putanji {FilePath}.",
                filePath);

            await WriteReportAtomically(
                filePath,
                csvReport.ToString());

            await SendNotification(
                request.Username,
                "monthlyrevenuereport",
                "Mjesečni izvještaj prihoda je uspješno generisan.");
        }

        public async Task GenerateTopCustomersReport(
         ReportRequest request)
        {
            const string fileName =
                "top_customers_report.csv";

            var filePath = InvalidateReport(fileName);

            var query = _context.Orders
                .Where(
                    x => x.State == OrderStates.Completed)
                .AsQueryable();

            if (request.StartDate != null)
            {
                query = query.Where(
                    x => x.OrderDate.Date >=
                         request.StartDate.Value.Date);
            }

            if (request.EndDate != null)
            {
                query = query.Where(
                    x => x.OrderDate.Date <=
                         request.EndDate.Value.Date);
            }

            var data = await query
                .Where(
                    x => x.CustomerId != null &&
                         x.Customer != null)
                .GroupBy(x => new
                {
                    x.CustomerId,
                    Username = x.Customer!.Username,
                    CustomerName =
                        x.Customer!.Name +
                        " " +
                        x.Customer!.Surname
                })
                .Select(group => new
                {
                    group.Key.CustomerId,
                    group.Key.Username,
                    group.Key.CustomerName,
                    OrdersCount = group.Count(),
                    TotalSpent = group.Sum(
                        x => x.TotalAmount)
                })
                .OrderByDescending(x => x.TotalSpent)
                .Take(2)
                .ToListAsync();

            if (!data.Any())
            {
                await SendNotification(
                    request.Username,
                    "topcustomersreport",
                    "Nema kupaca za generisanje izvještaja.");

                return;
            }

            var csvReport = new StringBuilder();

            csvReport.AppendLine(
                CreateCsvRow(
                    "CustomerId",
                    "Username",
                    "CustomerName",
                    "OrdersCount",
                    "TotalSpent"));

            foreach (var item in data)
            {
                csvReport.AppendLine(
                    CreateCsvRow(
                        item.CustomerId,
                        item.Username,
                        item.CustomerName,
                        item.OrdersCount,
                        item.TotalSpent.ToString(
                            "F2",
                            CultureInfo.InvariantCulture)));
            }

            _logger.LogInformation(
                "Generisanje izvještaja na putanji {FilePath}.",
                filePath);

            await WriteReportAtomically(
                filePath,
                csvReport.ToString());

            await SendNotification(
                request.Username,
                "topcustomersreport",
                "Izvještaj top kupaca je uspješno generisan.");
        }

        private string InvalidateReport(string fileName)
        {
            var filePath = Path.Combine(_reportsPath, fileName);

            if (File.Exists(filePath))
            {
                File.Delete(filePath);
            }

            return filePath;
        }

        private static string CreateCsvRow(params object?[] values)
        {
            return string.Join(",", values.Select(EscapeCsvField));
        }

        private static string EscapeCsvField(object? value)
        {
            var text = Convert.ToString(
                value,
                CultureInfo.InvariantCulture) ?? string.Empty;

            if (text.Contains('"'))
            {
                text = text.Replace("\"", "\"\"");
            }

            if (text.Contains(',') ||
                text.Contains('"') ||
                text.Contains('\r') ||
                text.Contains('\n'))
            {
                return $"\"{text}\"";
            }

            return text;
        }

        private static async Task WriteReportAtomically(
            string filePath,
            string content)
        {
            var temporaryPath =
                $"{filePath}.{Guid.NewGuid():N}.tmp";

            try
            {
                await File.WriteAllTextAsync(
                    temporaryPath,
                    content,
                    new UTF8Encoding(
                        encoderShouldEmitUTF8Identifier: true));

                File.Move(
                    temporaryPath,
                    filePath,
                    overwrite: true);
            }
            finally
            {
                if (File.Exists(temporaryPath))
                {
                    File.Delete(temporaryPath);
                }
            }
        }
        private async Task SendNotification(string? username,string notificationType,string message)
        {
            if (string.IsNullOrWhiteSpace(username))
            {
                throw new InvalidOperationException("Korisničko ime za slanje obavijesti nije definisano.");
            }

            await _rabbitMQService.SendReportNotification(new ReportNotificationModel
                {
                    Username = username,
                    NotificationType = notificationType,
                    Message = message
                });
        }
    }
}