using eAutoShop.Model.Model;
using eAutoShop.Model.Request;
using eAutoShop.Model.Utilities;
using eAutoShop.Services.Interfaces;
using Microsoft.Extensions.Options;
using Stripe;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace eAutoShop.Services.Services
{
    public class StripeService : IStripeService
    {
        private readonly StripeSettings _stripeSettings;

        public StripeService(IOptions<StripeSettings> stripeSettings)
        {
            _stripeSettings = stripeSettings.Value;
            StripeConfiguration.ApiKey = _stripeSettings.SecretKey;
        }

        public async Task CreateRefundAsync(string paymentIntentId)
        {
            var refundService = new RefundService();

            var options = new RefundCreateOptions
            {
                PaymentIntent = paymentIntentId
            };

            await refundService.CreateAsync(options);
        }

        public async Task<PaymentResponse> ConfirmPayment(PaymentCreateRequest request)
        {
            var intentOptions = new PaymentIntentCreateOptions
            {
                Amount = request.TotalAmount,
                Currency = "eur",
                PaymentMethodTypes = new List<string> { "card" },
                Metadata = new Dictionary<string, string>
            {
                { "order_id", request.OrderId?.ToString() ?? "" },
                { "username", request.Username ?? "" }
            }
            };

            var service = new PaymentIntentService();

            var intent = await service.CreateAsync(intentOptions);

            var confirmOptions = new PaymentIntentConfirmOptions
            {
                PaymentMethod = request.PaymentMethodId
            };

            var response = new PaymentResponse
            {
                PaymentIntentId = intent.Id
            };

            try
            {
                var confirmation = await service.ConfirmAsync(intent.Id, confirmOptions);
                response.Message = confirmation.Status;
            }
            catch (StripeException ex)
            {
                response.Message = ex.StripeError?.Message ?? "Greška prilikom obrade plaćanja.";
            }
            catch (Exception ex)
            {
                response.Message = $"Neočekivana greška: {ex.Message}";
            }

            return response;
        }

        public async Task<PaymentIntentResponse> CreatePaymentIntent(PaymentCreateRequest request)
        {
            var metadata = new Dictionary<string, string>();

            if (!string.IsNullOrWhiteSpace(request.Username))
            {
                metadata.Add("username", request.Username);
            }

            if (request.OrderId.HasValue)
            {
                metadata.Add("order_id", request.OrderId.Value.ToString());
            }

            if (request.AppointmentId.HasValue)
            {
                metadata.Add("appointment_id", request.AppointmentId.Value.ToString());
            }

            var options = new PaymentIntentCreateOptions
            {
                Amount = request.TotalAmount,
                Currency = "eur",
                PaymentMethodTypes = new List<string> { "card" },
                CaptureMethod = "automatic",
                Metadata = metadata
            };

            var service = new PaymentIntentService();

            var paymentIntent = await service.CreateAsync(options);

            return new PaymentIntentResponse
            {
                PaymentIntentId = paymentIntent.Id,
                ClientSecret = paymentIntent.ClientSecret
            };
        }
    }
}
