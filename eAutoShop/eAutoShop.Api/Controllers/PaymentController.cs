using eAutoShop.Model.Model;
using eAutoShop.Model.Request;
using eAutoShop.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace eAutoShop.Api.Controllers
{
    [Authorize]
    [ApiController]
    [Route("[controller]")]
    public class PaymentController : ControllerBase
    {
        private readonly IStripeService _stripeService;

        public PaymentController(IStripeService stripeService)
        {
            _stripeService = stripeService;
        }

        [HttpPost("ConfirmPayment")]
        public async Task<IActionResult> ConfirmPayment([FromBody] PaymentCreateRequest request)
        {
            string? username = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

            request.Username = username;

            var confirmation = await _stripeService.ConfirmPayment(request);

            return Ok(confirmation);
        }

        [HttpPost("CreatePaymentIntent")]
        public async Task<PaymentIntentResponse> CreatePaymentIntent([FromBody] PaymentCreateRequest request)
        {
            string? username = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

            request.Username = username;

            var intent = await _stripeService.CreatePaymentIntent(request);

            return intent;
        }
    }
}
