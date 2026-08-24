using eAutoShop.Model.Exceptions;
using eAutoShop.Model.Model;
using eAutoShop.Model.Request;
using eAutoShop.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace eAutoShop.Api.Controllers
{
    [Authorize(Roles = "customer")]
    [ApiController]
    [Route("[controller]")]
    public class PaymentController : ControllerBase
    {
        private readonly IStripeService _stripeService;

        public PaymentController(IStripeService stripeService)
        {
            _stripeService = stripeService;
        }

        [HttpPost("CreatePaymentIntent")]
        public async Task<PaymentIntentResponse> CreatePaymentIntent(
            PaymentCreateRequest request)
        {
            var customerId = GetCustomerId();

            return await _stripeService.CreatePaymentIntent(
                request.OrderId,
                customerId);
        }

        [HttpPost("VerifyPayment/{orderId:int}")]
        public async Task<OrderModel> VerifyPayment(int orderId)
        {
            var customerId = GetCustomerId();

            return await _stripeService.VerifyPayment(
                orderId,
                customerId);
        }

        private int GetCustomerId()
        {
            var value = User.FindFirst(
                ClaimTypes.NameIdentifier)?.Value;

            if (!int.TryParse(value, out var customerId))
            {
                throw new UserException("Unauthorized.");
            }

            return customerId;
        }
    }
}
