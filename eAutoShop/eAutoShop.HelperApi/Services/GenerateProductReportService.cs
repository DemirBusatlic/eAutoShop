using eAutoShop.HelperApi.Interfaces;
using eAutoShop.Model.Model;
using eAutoShop.Model.Request;
using eAutoShop.Services.Database;
using Microsoft.EntityFrameworkCore;
using System.Text;

namespace eAutoShop.HelperApi.Services
{

    public class GenerateProductReportService : IGenerateProductReportService
    {
        private readonly AutoShopContext _context;
        private readonly RabbitMQService _rabbitMQService;

        public GenerateProductReportService(AutoShopContext context, RabbitMQService rabbitMQService)
        {
            _context = context;
            _rabbitMQService = rabbitMQService;
        }

        public async Task GenerateReport(ProductReportRequest request)
        {
            var query = _context.Products.Include(x => x.ProductCategory).Include(x => x.OrderItems).ThenInclude(x => x.Order).AsQueryable();

            if (request.ProductCategoryId != null)
            {
                query = query.Where(x => x.ProductCategoryId == request.ProductCategoryId);
            }

            if (request.ProductId != null)
            {
                query = query.Where(x => x.Id == request.ProductId);
            }

            var products = await query.ToListAsync();

            if (!products.Any())
            {
                await _rabbitMQService.SendReportNotification(new ReportNotificationModel
                {
                    Username = request.Username!,
                    NotificationType = "productreport",
                    Message = "Nema proizvoda za generisanje izvještaja."
                });

                return;
            }

            var csvReport = new StringBuilder();

            csvReport.AppendLine("ProductId,ProductName,Category,Price,Discount,DiscountedPrice,TotalSold,TotalRevenue");

            foreach (var product in products)
            {
                var orderItems = product.OrderItems;

                if (request.StartDate != null)
                {
                    orderItems = orderItems
                        .Where(x => x.Order != null && x.Order.OrderDate.Date >= request.StartDate.Value.Date)
                        .ToList();
                }

                if (request.EndDate != null)
                {
                    orderItems = orderItems
                        .Where(x => x.Order != null && x.Order.OrderDate.Date <= request.EndDate.Value.Date)
                        .ToList();
                }

                var totalSold = orderItems.Sum(x => x.Quantity);
                var totalRevenue = orderItems.Sum(x => x.TotalItemPriceDiscounted);

                csvReport.AppendLine(
                    $"{product.Id},{product.Name},{product.ProductCategory?.Name},{product.Price},{product.Discount},{product.DiscountedPrice},{totalSold},{totalRevenue:F2}");
            }

            var sharedVolumePath = "Reports";

            if (!Directory.Exists(sharedVolumePath))
            {
                Directory.CreateDirectory(sharedVolumePath);
            }

            var fileName = "product_report.csv";
            var filePath = Path.Combine(sharedVolumePath, fileName);
            Console.WriteLine(filePath);

            await File.WriteAllTextAsync(filePath, csvReport.ToString());

            await _rabbitMQService.SendReportNotification(new ReportNotificationModel
            {
                Username = request.Username!,
                NotificationType = "productreport",
                Message = "Izvještaj za proizvode je uspješno generisan."
            });
        }

        public async Task GenerateTopSellingProductsReport(ProductReportRequest request)
        {
            var query = _context.OrderItems
                .Include(x => x.Product)
                .ThenInclude(x => x.ProductCategory)
                .Include(x => x.Order)
                .AsQueryable();

            if (request.StartDate != null)
            {
                query = query.Where(x => x.Order != null &&
                    x.Order.OrderDate.Date >= request.StartDate.Value.Date);
            }

            if (request.EndDate != null)
            {
                query = query.Where(x => x.Order != null &&
                    x.Order.OrderDate.Date <= request.EndDate.Value.Date);
            }

            if (request.ProductCategoryId != null)
            {
                query = query.Where(x => x.Product.ProductCategoryId == request.ProductCategoryId);
            }

            if (request.ProductId != null)
            {
                query = query.Where(x => x.ProductId == request.ProductId);
            }

            var data = await query
                .GroupBy(x => new
                {
                    x.ProductId,
                    ProductName = x.Product.Name,
                    CategoryName = x.Product.ProductCategory.Name
                })
                .Select(g => new
                {
                    g.Key.ProductId,
                    g.Key.ProductName,
                    g.Key.CategoryName,
                    TotalSold = g.Sum(x => x.Quantity),
                    TotalRevenue = g.Sum(x => x.TotalItemPriceDiscounted)
                })
                .OrderByDescending(x => x.TotalSold)
                .Take(10)
                .ToListAsync();

            if (!data.Any())
            {
                await _rabbitMQService.SendReportNotification(new ReportNotificationModel
                {
                    Username = request.Username!,
                    NotificationType = "topsellingproductsreport",
                    Message = "Nema podataka za generisanje izvještaja."
                });

                return;
            }

            var csvReport = new StringBuilder();

            csvReport.AppendLine("ProductId,ProductName,Category,TotalSold,TotalRevenue");

            foreach (var item in data)
            {
                csvReport.AppendLine(
                    $"{item.ProductId},{item.ProductName},{item.CategoryName},{item.TotalSold},{item.TotalRevenue:F2}");
            }

            var sharedVolumePath = "Reports";

            if (!Directory.Exists(sharedVolumePath))
            {
                Directory.CreateDirectory(sharedVolumePath);
            }

            var fileName = "top_selling_products_report.csv";
            var filePath = Path.Combine(sharedVolumePath, fileName);

            await File.WriteAllTextAsync(filePath, csvReport.ToString());

            await _rabbitMQService.SendReportNotification(new ReportNotificationModel
            {
                Username = request.Username!,
                NotificationType = "topsellingproductsreport",
                Message = "Izvještaj najprodavanijih proizvoda je uspješno generisan."
            });
        }

        public async Task GenerateSalesByCategoryReport(ReportRequest request)
        {
            var query = _context.OrderItems
                .Include(x => x.Product)
                .ThenInclude(x => x.ProductCategory)
                .Include(x => x.Order)
                .AsQueryable();

            if (request.StartDate != null)
            {
                query = query.Where(x => x.Order != null &&
                    x.Order.OrderDate.Date >= request.StartDate.Value.Date);
            }

            if (request.EndDate != null)
            {
                query = query.Where(x => x.Order != null &&
                    x.Order.OrderDate.Date <= request.EndDate.Value.Date);
            }

            var data = await query
                .GroupBy(x => new
                {
                    CategoryId = x.Product.ProductCategoryId,
                    CategoryName = x.Product.ProductCategory.Name
                })
                .Select(g => new
                {
                    g.Key.CategoryId,
                    g.Key.CategoryName,
                    TotalSold = g.Sum(x => x.Quantity),
                    TotalRevenue = g.Sum(x => x.TotalItemPriceDiscounted)
                })
                .OrderByDescending(x => x.TotalRevenue)
                .ToListAsync();

            if (!data.Any())
            {
                await _rabbitMQService.SendReportNotification(new ReportNotificationModel
                {
                    Username = request.Username!,
                    NotificationType = "salesbycategoryreport",
                    Message = "Nema podataka za generisanje izvještaja."
                });

                return;
            }

            var csvReport = new StringBuilder();
            csvReport.AppendLine("CategoryId,CategoryName,TotalSold,TotalRevenue");

            foreach (var item in data)
            {
                csvReport.AppendLine(
                    $"{item.CategoryId},{item.CategoryName},{item.TotalSold},{item.TotalRevenue:F2}");
            }

            var sharedVolumePath = "Reports";

            if (!Directory.Exists(sharedVolumePath))
            {
                Directory.CreateDirectory(sharedVolumePath);
            }

            var fileName = "sales_by_category_report.csv";
            var filePath = Path.Combine(sharedVolumePath, fileName);

            await File.WriteAllTextAsync(filePath, csvReport.ToString());

            await _rabbitMQService.SendReportNotification(new ReportNotificationModel
            {
                Username = request.Username!,
                NotificationType = "salesbycategoryreport",
                Message = "Izvještaj prodaje po kategorijama je uspješno generisan."
            });
        }
        public async Task GenerateMonthlyRevenueReport(ReportRequest request)
        {
            var startDate = request.StartDate?.Date ?? DateTime.Now.AddMonths(-1).Date;
            var endDate = request.EndDate?.Date ?? DateTime.Now.Date;

            var orders = await _context.Orders
                .Where(x => x.OrderDate.Date >= startDate &&
                            x.OrderDate.Date <= endDate)
                .ToListAsync();

            if (!orders.Any())
            {
                await _rabbitMQService.SendReportNotification(new ReportNotificationModel
                {
                    Username = request.Username!,
                    NotificationType = "monthlyrevenuereport",
                    Message = "Nema narudžbi za generisanje mjesečnog izvještaja."
                });

                return;
            }

            var csvReport = new StringBuilder();
            csvReport.AppendLine("Date,Revenue");

            for (var date = startDate; date <= endDate; date = date.AddDays(1))
            {
                var dailyRevenue = orders
                    .Where(x => x.OrderDate.Date == date.Date)
                    .Sum(x => x.TotalAmount);

                csvReport.AppendLine($"{date:yyyy-MM-dd},{dailyRevenue:F2}");
            }

            var sharedVolumePath = "Reports";

            if (!Directory.Exists(sharedVolumePath))
            {
                Directory.CreateDirectory(sharedVolumePath);
            }

            var fileName = "monthly_revenue_report.csv";
            var filePath = Path.Combine(sharedVolumePath, fileName);

            await File.WriteAllTextAsync(filePath, csvReport.ToString());

            await _rabbitMQService.SendReportNotification(new ReportNotificationModel
            {
                Username = request.Username!,
                NotificationType = "monthlyrevenuereport",
                Message = "Mjesečni izvještaj prihoda je uspješno generisan."
            });
        }

        public async Task GenerateTopCustomersReport(ReportRequest request)
        {
            var query = _context.Orders
                .Include(x => x.Customer)
                .AsQueryable();

            if (request.StartDate != null)
            {
                query = query.Where(x => x.OrderDate.Date >= request.StartDate.Value.Date);
            }

            if (request.EndDate != null)
            {
                query = query.Where(x => x.OrderDate.Date <= request.EndDate.Value.Date);
            }

            var data = await query
                .Where(x => x.CustomerId != null)
                .GroupBy(x => new
                {
                    x.CustomerId,
                    x.Customer.Username,
                    CustomerName = x.Customer.Name + " " + x.Customer.Surname
                })
                .Select(g => new
                {
                    g.Key.CustomerId,
                    g.Key.Username,
                    g.Key.CustomerName,
                    OrdersCount = g.Count(),
                    TotalSpent = g.Sum(x => x.TotalAmount)
                })
                .OrderByDescending(x => x.TotalSpent)
                .Take(2)
                .ToListAsync();

            if (!data.Any())
            {
                await _rabbitMQService.SendReportNotification(new ReportNotificationModel
                {
                    Username = request.Username!,
                    NotificationType = "topcustomersreport",
                    Message = "Nema kupaca za generisanje izvještaja."
                });

                return;
            }

            var csvReport = new StringBuilder();
            csvReport.AppendLine("CustomerId,Username,CustomerName,OrdersCount,TotalSpent");

            foreach (var item in data)
            {
                csvReport.AppendLine(
                    $"{item.CustomerId},{item.Username},{item.CustomerName},{item.OrdersCount},{item.TotalSpent:F2}");
            }

            var sharedVolumePath = "Reports";

            if (!Directory.Exists(sharedVolumePath))
            {
                Directory.CreateDirectory(sharedVolumePath);
            }

            var fileName = "top_customers_report.csv";
            var filePath = Path.Combine(sharedVolumePath, fileName);

            await File.WriteAllTextAsync(filePath, csvReport.ToString());

            await _rabbitMQService.SendReportNotification(new ReportNotificationModel
            {
                Username = request.Username!,
                NotificationType = "topcustomersreport",
                Message = "Izvještaj top kupaca je uspješno generisan."
            });
        }
    }
}

