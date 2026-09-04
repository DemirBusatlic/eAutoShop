using eAutoShop.Model.Exceptions;
using eAutoShop.Model.Model;
using eAutoShop.Model.Request;
using eAutoShop.Services.Database;
using MapsterMapper;
using Microsoft.Extensions.DependencyInjection;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace eAutoShop.Services.StateMachineService.OrderStateMachine
{
    public static class OrderStates
    {
        public const string Initial = "initial";
        public const string MissingPayment = "missingpayment";
        public const string OnHold = "onhold";
        public const string Accepted = "accepted";
        public const string Rejected = "rejected";
        public const string Cancelled = "cancelled";
        public const string PaymentFailed = "paymentfailed";
        public const string Completed = "completed";
    }

    public class BaseOrderState
    {
        protected readonly AutoShopContext _context;
        protected readonly IMapper _mapper;
        protected readonly IServiceProvider _serviceProvider;

        public BaseOrderState(AutoShopContext context, IMapper mapper, IServiceProvider serviceProvider)
        {
            _context = context;
            _mapper = mapper;
            _serviceProvider = serviceProvider;
        }

        public virtual Task<OrderModel> Insert(OrderInsertRequest request)
        {
            throw new UserException("Action not allowed.");
        }

        public virtual Task<OrderModel> Update(Order entity, OrderUpdateRequest request)
        {
            throw new UserException("Action not allowed.");
        }

        public virtual Task<OrderModel> Accept(Order entity, OrderAcceptRequest orderAccept)
        {
            throw new UserException("Action not allowed.");
        }

        public virtual Task<OrderModel> Reject(Order entity)
        {
            throw new UserException("Action not allowed.");
        }


        public virtual Task<OrderModel> Cancel(Order entity)
        {
            throw new UserException("Action not allowed.");
        }

        public virtual Task<OrderModel> Resend(Order entity)
        {
            throw new UserException("Action not allowed.");
        }

        public virtual Task<OrderModel> SoftDelete(Order entity, string role)
        {
            throw new UserException("Action not allowed.");
        }

        public virtual Task<OrderModel> Complete(Order entity)
        {
            throw new UserException("Action not allowed.");
        }

        public virtual Task<List<string>> AllowedActions()
        {
            return Task.FromResult(new List<string>());
        }

        public BaseOrderState CreateState(string? state)
        {
            var key = state?.Trim().ToLowerInvariant();

            return key switch
            {
                null or OrderStates.Initial =>
                    _serviceProvider.GetRequiredService<InitialOrderState>(),

                OrderStates.MissingPayment =>
                    _serviceProvider.GetRequiredService<MissingPaymentOrderState>(),

                OrderStates.OnHold =>
                    _serviceProvider.GetRequiredService<OnHoldOrderState>(),

                OrderStates.Accepted =>
                    _serviceProvider.GetRequiredService<AcceptedOrderState>(),

                OrderStates.Rejected =>
                    _serviceProvider.GetRequiredService<RejectedOrderState>(),

                OrderStates.Cancelled =>
                    _serviceProvider.GetRequiredService<CancelledOrderState>(),

                OrderStates.PaymentFailed =>
                    _serviceProvider.GetRequiredService<PaymentFailedOrderState>(),

                OrderStates.Completed =>
                    _serviceProvider.GetRequiredService<CompletedOrderState>(),

                _ => throw new UserException("State not supported.")
            };
        }
    }
}
