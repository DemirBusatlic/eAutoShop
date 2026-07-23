using eAutoShop.Model.Request;
using eAutoShop.Services.Interfaces;
using eAutoShop.Services.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Stripe;
using System.Security.Claims;

namespace eAutoShop.Api.Controllers
{
   [Authorize(Roles = "manager,salesperson, technician")]
[ApiController]
[Route("[controller]")]
public class ReportController : ControllerBase
{
    private readonly IReportService _reportService;

    public ReportController(IReportService reportService)
    {
        _reportService = reportService;
    }

    [HttpPost("GenerateProductReport")]
    public async Task<IActionResult> GenerateProductReport([FromBody] ProductReportRequest request)
    {
        SetUserData(request);

        await _reportService.GenerateProductReport(request);

        return Ok();
    }

    [HttpGet("GetProductReport")]
    public async Task<IActionResult> GetProductReport()
    {
        var report = await _reportService.GetProductReport();

        if (report == null || report.Length == 0)
            return NotFound();

        return File(report, "text/csv", "product_report.csv");
    }

    [HttpPost("GenerateTopSellingProductsReport")]
    public async Task<IActionResult> GenerateTopSellingProductsReport([FromBody] ProductReportRequest request)
    {
        SetUserData(request);

        await _reportService.GenerateTopSellingProductsReport(request);

        return Ok();
    }

    [HttpGet("GetTopSellingProductsReport")]
    public async Task<IActionResult> GetTopSellingProductsReport()
    {
        var report = await _reportService.GetTopSellingProductsReport();

        if (report == null || report.Length == 0)
            return NotFound();

        return File(report, "text/csv", "top_selling_products_report.csv");
    }

    [HttpPost("GenerateSalesByCategoryReport")]
    public async Task<IActionResult> GenerateSalesByCategoryReport([FromBody] ReportRequest request)
    {
        SetUserData(request);

        await _reportService.GenerateSalesByCategoryReport(request);

        return Ok();
    }

    [HttpGet("GetSalesByCategoryReport")]
    public async Task<IActionResult> GetSalesByCategoryReport()
    {
        var report = await _reportService.GetSalesByCategoryReport();

        if (report == null || report.Length == 0)
            return NotFound();

        return File(report, "text/csv", "sales_by_category_report.csv");
    }

    [HttpPost("GenerateMonthlyRevenueReport")]
    public async Task<IActionResult> GenerateMonthlyRevenueReport([FromBody] ReportRequest request)
    {
        SetUserData(request);

        await _reportService.GenerateMonthlyRevenueReport(request);

        return Ok();
    }

    [HttpGet("GetMonthlyRevenueReport")]
    public async Task<IActionResult> GetMonthlyRevenueReport()
    {
        var report = await _reportService.GetMonthlyRevenueReport();

        if (report == null || report.Length == 0)
            return NotFound();

        return File(report, "text/csv", "monthly_revenue_report.csv");
    }

    [HttpPost("GenerateTopCustomersReport")]
    public async Task<IActionResult> GenerateTopCustomersReport([FromBody] ReportRequest request)
    {
        SetUserData(request);

        await _reportService.GenerateTopCustomersReport(request);

        return Ok();
    }

    [HttpGet("GetTopCustomersReport")]
    public async Task<IActionResult> GetTopCustomersReport()
    {
        var report = await _reportService.GetTopCustomersReport();

        if (report == null || report.Length == 0)
            return NotFound();

        return File(report, "text/csv", "top_customers_report.csv");
    }

    private void SetUserData(ReportRequest request)
    {
        request.Username = User.FindFirst(ClaimTypes.Name)?.Value;
        request.Role = User.FindFirst(ClaimTypes.Role)?.Value;
    }
}
}
