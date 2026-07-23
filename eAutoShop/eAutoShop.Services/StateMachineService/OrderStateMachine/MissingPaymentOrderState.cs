using eAutoShop.Model.Exceptions;
using eAutoShop.Model.Model;
using eAutoShop.Services.Database;
using eAutoShop.Services.Helpers;
using MapsterMapper;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace eAutoShop.Services.StateMachineService.OrderStateMachine
{
    public class MissingPaymentOrderState : BaseOrderState
    {
        public MissingPaymentOrderState(AutoShopContext context,IMapper mapper,IServiceProvider serviceProvider): base(context, mapper, serviceProvider)
        {
        }

        public override async Task<OrderModel> AddSuccessfulPayment( Order entity,string paymentIntentId)
        {
            if (string.IsNullOrWhiteSpace(paymentIntentId))
            {
                throw new UserException("Invalid payment intent.");
            }

            paymentIntentId = paymentIntentId.Trim();

            entity.State = OrderStates.OnHold;

            entity.PaymentIntentId = paymentIntentId;

            await _context.SaveChangesAsync();

            return _mapper.Map<OrderModel>(entity);
        }

        public override async Task<OrderModel> AddFailedPayment(Order entity,string paymentIntentId)
        {
            if (string.IsNullOrWhiteSpace(paymentIntentId))
            {
                throw new UserException("Invalid payment intent.");
            }

            paymentIntentId = paymentIntentId.Trim();

            entity.State = OrderStates.PaymentFailed;

            entity.PaymentIntentId = paymentIntentId;

            await _context.SaveChangesAsync();

            return _mapper.Map<OrderModel>(entity);
        }

        public override async Task<OrderModel> SoftDelete(Order entity,string role)
        {
            role = role?.Trim().ToLowerInvariant()?? throw new UserException("Invalid role.");

            if (role == UserRoles.Salesperson ||
                role == UserRoles.Technician ||
                role == UserRoles.Manager)
            {
                entity.DeletedByShop = true;
            }
            else if (role == UserRoles.Customer)
            {
                entity.DeletedByCustomer = true;
            }
            else
            {
                throw new UserException("Invalid role.");
            }

            await _context.SaveChangesAsync();

            return _mapper.Map<OrderModel>(entity);
        }

        public override async Task<List<string>> AllowedActions()
        {
            var list = await base.AllowedActions();

            list.Add(nameof(AddSuccessfulPayment));
            list.Add(nameof(AddFailedPayment));
            list.Add(nameof(SoftDelete));

            return list;
        }
    }
}
