using eAutoShop.Model.Request;

namespace eAutoShop.HelperApi.Interfaces
{
    public interface IGenerateProductReportService
    {
        Task GenerateReport(ProductReportRequest request);
        Task GenerateTopSellingProductsReport(ProductReportRequest request);
        Task GenerateMonthlyRevenueReport(ReportRequest request);
        Task GenerateSalesByCategoryReport(ReportRequest request);
        Task GenerateTopCustomersReport(ReportRequest request);
    }
}
