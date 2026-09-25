using eAutoShop.Model.Exceptions;
using eAutoShop.Model.Model;
using eAutoShop.Model.Request;
using eAutoShop.Services.Database;
using eAutoShop.Services.Helpers;
using eAutoShop.Services.Interfaces;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace eAutoShop.Services.StateMachineService.OrderStateMachine
{
    public class OnHoldOrderState : BaseOrderState
    {
        public OnHoldOrderState(AutoShopContext context, IMapper mapper, IServiceProvider serviceProvider) : base(context, mapper, serviceProvider)
        {
        }

        public override async Task<OrderModel> Update(Order entity, OrderUpdateRequest request)
        {
            if (!string.IsNullOrWhiteSpace(request.ShippingAddress))
            {
                entity.ShippingAddress = request.ShippingAddress;
            }

            if (!string.IsNullOrWhiteSpace(request.ShippingPostalCode))
            {
                entity.PostalCode = request.ShippingPostalCode;
            }

            entity.CityId = request.CityId ?? throw new UserException("City is required.");

            await _context.SaveChangesAsync();

            return _mapper.Map<OrderModel>(entity);
        }

        public override async Task<OrderModel> Accept(Order entity, OrderAcceptRequest orderAccept, string actorUsername)
        {
            if (orderAccept.ShippingDate <= DateTime.UtcNow)
            {
                throw new UserException("Shipping date must be in the future.");
            }

            var now = DateTime.UtcNow;

            entity.AcceptedBy = actorUsername;
            entity.AcceptedAt = now;
            entity.ShippingDate = orderAccept.ShippingDate;
            entity.State = OrderStates.Accepted;

            await _context.SaveChangesAsync();

            return _mapper.Map<OrderModel>(entity);
        }

        public override async Task<OrderModel> Reject(Order entity, string reason, string actorUsername)
        {
            if (string.IsNullOrWhiteSpace(reason))
            {
                throw new UserException("Rejection reason is required.");
            }

            reason = reason.Trim();

            if (reason.Length > 500)
            {
                throw new UserException("Rejection reason can contain at most 500 characters.");
            }

            if (string.IsNullOrWhiteSpace(entity.PaymentIntentId))
            {
                throw new UserException("Payment intent does not exist.");
            }

            await _serviceProvider.GetRequiredService<IStripeService>().CreateRefundAsync(entity.PaymentIntentId, $"order-refund-{entity.Id}");

            var now = DateTime.UtcNow;

            entity.RejectionReason = reason;
            entity.RejectedBy = actorUsername;
            entity.RejectedAt = now;
            entity.State = OrderStates.Rejected;

            await _context.SaveChangesAsync();

            return _mapper.Map<OrderModel>(entity);
        }

        public override async Task<OrderModel> Cancel(Order entity,string reason,string actorUsername)
        {
            if (string.IsNullOrWhiteSpace(reason))
            {
                throw new UserException("Cancellation reason is required.");
            }

            reason = reason.Trim();

            if (reason.Length > 500)
            {
                throw new UserException("Cancellation reason can contain at most 500 characters.");
            }

            if (string.IsNullOrWhiteSpace(entity.PaymentIntentId))
            {
                throw new UserException("Payment intent does not exist.");
            }

            await _serviceProvider.GetRequiredService<IStripeService>().CreateRefundAsync(entity.PaymentIntentId, $"order-refund-{entity.Id}");

            var now = DateTime.UtcNow;

            entity.CancellationReason = reason;
            entity.CancelledBy = actorUsername;
            entity.CancelledAt = now;
            entity.State = OrderStates.Cancelled;

            await _context.SaveChangesAsync();

            return _mapper.Map<OrderModel>(entity);
        }

        public override async Task<List<string>> AllowedActions()
        {
            var list = await base.AllowedActions();

            list.Add(nameof(Update));
            list.Add(nameof(Accept));
            list.Add(nameof(Reject));
            list.Add(nameof(Cancel));

            return list;
        }
    }
}
