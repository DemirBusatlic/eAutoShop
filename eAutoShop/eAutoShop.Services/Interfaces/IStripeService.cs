using eAutoShop.Model.Model;
using eAutoShop.Model.Request;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace eAutoShop.Services.Interfaces
{
    public interface IStripeService
    {
        Task<PaymentResponse> ConfirmPayment(PaymentCreateRequest request);

        Task<PaymentIntentResponse> CreatePaymentIntent(PaymentCreateRequest request);

        Task CreateRefundAsync(string paymentIntentId);
    }
}
