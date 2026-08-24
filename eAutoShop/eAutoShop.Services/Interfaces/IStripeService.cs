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
        Task<PaymentIntentResponse> CreatePaymentIntent(int orderId,int customerId);

        Task<OrderModel> VerifyPayment(int orderId,int customerId);

        Task CreateRefundAsync(string paymentIntentId,string idempotencyKey);
    }
}
