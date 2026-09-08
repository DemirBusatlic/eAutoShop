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

        public override async Task<OrderModel> Accept(Order entity, OrderAcceptRequest orderAccept)
        {
            if (orderAccept.ShippingDate <= DateTime.UtcNow)
            {
                throw new UserException("Shipping date must be in the future.");
            }

            entity.State = OrderStates.Accepted;
            entity.ShippingDate = orderAccept.ShippingDate;


            await _context.SaveChangesAsync();

            return _mapper.Map<OrderModel>(entity);
        }

        public override async Task<OrderModel> Reject(Order entity)
        {
            if (string.IsNullOrWhiteSpace(entity.PaymentIntentId))
            {
                throw new UserException("Payment intent does not exist.");
            }

            await _serviceProvider.GetRequiredService<IStripeService>().CreateRefundAsync(entity.PaymentIntentId,$"order-refund-{entity.Id}");

            entity.State = OrderStates.Rejected;


            await _context.SaveChangesAsync();

            return _mapper.Map<OrderModel>(entity);
        }

        public override async Task<OrderModel> Cancel(Order entity)
        {
            if (string.IsNullOrWhiteSpace(entity.PaymentIntentId))
            {
                throw new UserException("Payment intent does not exist.");
            }

            await _serviceProvider.GetRequiredService<IStripeService>().CreateRefundAsync(entity.PaymentIntentId,$"order-refund-{entity.Id}");

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
