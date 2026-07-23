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
        public OnHoldOrderState(AutoShopContext context,IMapper mapper,IServiceProvider serviceProvider): base(context, mapper, serviceProvider)
        {
        }

        public override async Task<OrderModel> Update(Order entity,OrderUpdateRequest request)
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
            if (orderAccept.shippingDate <= DateTime.UtcNow)
            {
                throw new UserException("Shipping date must be in the future.");
            }

            entity.State = OrderStates.Accepted;
            entity.ShippingDate = orderAccept.shippingDate;

            var appointment = await _context.Appointments.FirstOrDefaultAsync(x => x.OrderId == entity.Id);

            if (appointment != null)
            {
                if (entity.ShippingDate > appointment.ReservationDate)
                {
                    appointment.State = AppointmentStates.Cancelled;
                }
                else
                {
                    appointment.State = AppointmentStates.Pending;
                }
            }

            await _context.SaveChangesAsync();

            return _mapper.Map<OrderModel>(entity);
        }

        public override async Task<OrderModel> Reject(Order entity)
        {
            entity.State = OrderStates.Rejected;

            var appointment = await _context.Appointments.FirstOrDefaultAsync(x => x.OrderId == entity.Id);

            if (appointment != null)
            {
                appointment.OrderId = null;
            }

            await _context.SaveChangesAsync();

            await _serviceProvider.GetRequiredService<IStripeService>().CreateRefundAsync(entity.PaymentIntentId!);

            return _mapper.Map<OrderModel>(entity);
        }

        public override async Task<OrderModel> Cancel(Order entity)
        {
            entity.State = OrderStates.Cancelled;

            var appointment = await _context.Appointments.FirstOrDefaultAsync(x => x.OrderId == entity.Id);

            if (appointment != null)
            {
                appointment.OrderId = null;
            }

            await _context.SaveChangesAsync();

            await _serviceProvider.GetRequiredService<IStripeService>().CreateRefundAsync(entity.PaymentIntentId!);

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
