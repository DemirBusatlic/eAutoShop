using eAutoShop.Model.Request;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace eAutoShop.Services.Interfaces
{
    public interface IReportService
    {
        Task GenerateProductReport(ProductReportRequest request);
        Task<byte[]> GetProductReport();

        Task GenerateTopSellingProductsReport(ProductReportRequest request);
        Task<byte[]> GetTopSellingProductsReport();

        Task GenerateSalesByCategoryReport(ReportRequest request);
        Task<byte[]> GetSalesByCategoryReport();

        Task GenerateMonthlyRevenueReport(ReportRequest request);
        Task<byte[]> GetMonthlyRevenueReport();

        Task GenerateTopCustomersReport(ReportRequest request);
        Task<byte[]> GetTopCustomersReport();
    }
}
