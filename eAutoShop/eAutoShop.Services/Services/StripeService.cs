using eAutoShop.Model.Exceptions;
using eAutoShop.Model.Model;
using eAutoShop.Model.Request;
using eAutoShop.Model.Utilities;
using eAutoShop.Services.Database;
using eAutoShop.Services.Interfaces;
using eAutoShop.Services.StateMachineService.OrderStateMachine;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
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
        private readonly AutoShopContext _context;
        private readonly IMapper _mapper;

        public StripeService(IOptions<StripeSettings> stripeSettings,AutoShopContext context,IMapper mapper)
        {
            _stripeSettings = stripeSettings.Value;
            _context = context;
            _mapper = mapper;

            StripeConfiguration.ApiKey = _stripeSettings.SecretKey;
        }

        public async Task CreateRefundAsync(string paymentIntentId,string idempotencyKey)
        {
            if (string.IsNullOrWhiteSpace(paymentIntentId))
            {
                throw new UserException(
                    "Payment intent does not exist.");
            }

            var refundService = new RefundService();

            var refund = await refundService.CreateAsync(
                new RefundCreateOptions
                {
                    PaymentIntent = paymentIntentId
                },
                new RequestOptions
                {
                    IdempotencyKey = idempotencyKey
                });

            if (refund.Status != "succeeded" &&
                refund.Status != "pending")
            {
                throw new UserException(
                    "Refund was not successful.");
            }
        }


        public async Task<PaymentIntentResponse> CreatePaymentIntent(int orderId, int customerId)
        {
            var order = await _context.Orders
                .FirstOrDefaultAsync(x => x.Id == orderId)
                ?? throw new UserException("Order not found.");

            if (order.CustomerId != customerId)
            {
                throw new UserException(
                    "You cannot pay for another user's order.");
            }

            if (order.State == OrderStates.OnHold ||
                order.State == OrderStates.Accepted ||
                order.State == OrderStates.Completed)
            {
                throw new UserException("Order is already paid.");
            }

            if (order.State != OrderStates.MissingPayment)
            {
                throw new UserException(
                    "Payment is not allowed for this order.");
            }

            var paymentIntentService = new PaymentIntentService();

            // Ako već postoji, ne kreiramo drugi.
            if (!string.IsNullOrWhiteSpace(order.PaymentIntentId))
            {
                var existingIntent = await paymentIntentService.GetAsync(
                    order.PaymentIntentId);

                return new PaymentIntentResponse
                {
                    PaymentIntentId = existingIntent.Id,
                    ClientSecret = existingIntent.ClientSecret
                };
            }

            var amountInCents = (long)Math.Round(
                order.TotalAmount * 100,
                MidpointRounding.AwayFromZero);

            if (amountInCents <= 0)
            {
                throw new UserException("Invalid order amount.");
            }

            var options = new PaymentIntentCreateOptions
            {
                Amount = amountInCents,
                Currency = "eur",
                PaymentMethodTypes = new List<string> { "card" },
                CaptureMethod = "automatic",
                Metadata = new Dictionary<string, string>
        {
            { "order_id", order.Id.ToString() },
            { "customer_id", customerId.ToString() }
        }
            };

            var requestOptions = new RequestOptions
            {
                IdempotencyKey = $"order-payment-{order.Id}"
            };

            var paymentIntent = await paymentIntentService.CreateAsync(
                options,
                requestOptions);

            order.PaymentIntentId = paymentIntent.Id;
            await _context.SaveChangesAsync();

            return new PaymentIntentResponse
            {
                PaymentIntentId = paymentIntent.Id,
                ClientSecret = paymentIntent.ClientSecret
            };
        }

        public async Task<OrderModel> VerifyPayment(int orderId,int customerId)
        {
            var order = await _context.Orders.Include(x => x.Customer).Include(x => x.City).FirstOrDefaultAsync(x => x.Id == orderId)?? throw new UserException("Order not found.");

            if (order.CustomerId != customerId)
            {
                throw new UserException(
                    "You cannot verify another user's payment.");
            }

            // Idempotentnost: ponovljeni poziv vraća isti rezultat.
            if (order.State == OrderStates.OnHold ||
                order.State == OrderStates.Accepted ||
                order.State == OrderStates.Completed)
            {
                return _mapper.Map<OrderModel>(order);
            }

            if (string.IsNullOrWhiteSpace(order.PaymentIntentId))
            {
                throw new UserException(
                    "Payment intent does not exist.");
            }

            var service = new PaymentIntentService();
            var intent = await service.GetAsync(order.PaymentIntentId);

            var expectedAmount = (long)Math.Round(
                order.TotalAmount * 100,
                MidpointRounding.AwayFromZero);

            if (intent.Status != "succeeded")
            {
                throw new UserException(
                    "Payment has not been completed.");
            }

            if (intent.Amount != expectedAmount)
            {
                throw new UserException(
                    "Paid amount does not match the order amount.");
            }

            if (!string.Equals(
                    intent.Currency,
                    "eur",
                    StringComparison.OrdinalIgnoreCase))
            {
                throw new UserException("Invalid payment currency.");
            }

            if (!intent.Metadata.TryGetValue(
                    "order_id",
                    out var metadataOrderId) ||
                metadataOrderId != order.Id.ToString())
            {
                throw new UserException(
                    "Payment does not belong to this order.");
            }

            if (!intent.Metadata.TryGetValue(
                    "customer_id",
                    out var metadataCustomerId) ||
                metadataCustomerId != customerId.ToString())
            {
                throw new UserException(
                    "Payment does not belong to this customer.");
            }

            order.State = OrderStates.OnHold;

            await _context.SaveChangesAsync();

            return _mapper.Map<OrderModel>(order);
        }
    }
}
