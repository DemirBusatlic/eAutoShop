using eAutoShop.Model.Request;
using eAutoShop.Services.Database;
using eAutoShop.Services.Interfaces;
using eAutoShop.Services.Services.eAutoShop.Services.Database;
using MapsterMapper;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace eAutoShop.Services.Services
{
    public class ReportService : IReportService
    {
        private readonly AutoShopContext _context;
        private readonly RabbitMQService _rabbitMQService;

        private readonly string _sharedVolumePath;

        public ReportService(AutoShopContext context, RabbitMQService rabbitMQService, IConfiguration configuration)
        {
            _context = context;
            _rabbitMQService = rabbitMQService;
            _sharedVolumePath = configuration["REPORTS_PATH"] ?? "Reports";

            Directory.CreateDirectory(_sharedVolumePath);
        }

        public async Task GenerateProductReport(ProductReportRequest request)
        {
            await _rabbitMQService.SendReportGenerationRequest(request);
        }

        public async Task<byte[]> GetProductReport()
        {
            return await GetReportFile("product_report.csv");
        }

        public async Task GenerateTopSellingProductsReport(ProductReportRequest request)
        {
            await _rabbitMQService.SendTopSellingProductsReportRequest(request);
        }

        public async Task<byte[]> GetTopSellingProductsReport()
        {
            return await GetReportFile("top_selling_products_report.csv");
        }

        public async Task GenerateSalesByCategoryReport(ReportRequest request)
        {
            await _rabbitMQService.SendSalesByCategoryReportRequest(request);
        }

        public async Task<byte[]> GetSalesByCategoryReport()
        {
            return await GetReportFile("sales_by_category_report.csv");
        }

        public async Task GenerateMonthlyRevenueReport(ReportRequest request)
        {
            await _rabbitMQService.SendMonthlyRevenueReportRequest(request);
        }

        public async Task<byte[]> GetMonthlyRevenueReport()
        {
            return await GetReportFile("monthly_revenue_report.csv");
        }

        public async Task GenerateTopCustomersReport(ReportRequest request)
        {
            await _rabbitMQService.SendTopCustomersReportRequest(request);
        }

        public async Task<byte[]> GetTopCustomersReport()
        {
            return await GetReportFile("top_customers_report.csv");
        }

        private async Task<byte[]> GetReportFile(string fileName)
        {
            var reportFilePath = Path.Combine(_sharedVolumePath, fileName);

            if (File.Exists(reportFilePath))
            {
                return await File.ReadAllBytesAsync(reportFilePath);
            }

            return Array.Empty<byte>();
        }
    }
}
