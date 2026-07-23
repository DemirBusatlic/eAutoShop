using eAutoShop.Model.Exceptions;
using eAutoShop.Model.Model;
using eAutoShop.Model.Request;
using eAutoShop.Services.Database;
using eAutoShop.Services.Helpers;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace eAutoShop.Services.StateMachineService.OrderStateMachine
{
    public class InitialOrderState : BaseOrderState
    {
        public InitialOrderState(AutoShopContext context,IMapper mapper,IServiceProvider serviceProvider): base(context, mapper, serviceProvider)
        {
        }

        public override async Task<OrderModel> Insert(OrderInsertRequest request)
        {
            using var transaction = await _context.Database.BeginTransactionAsync();

            var user = await _context.Users.Include(x => x.Role).FirstOrDefaultAsync(x =>x.Username == request.Username)?? throw new UserException("User not found.");

            if (user.Role?.Name?.Trim().ToLowerInvariant() != UserRoles.Customer)
            {
                throw new UserException("Invalid user role.");
            }

            var productIds = request.Product
                .Select(x => x.ProductId)
                .Distinct()
                .ToList();

            var products = await _context.Products.Where(x => productIds.Contains(x.Id)).ToListAsync();

            if (products.Count != productIds.Count)
            {
                throw new UserException("One or more products do not exist.");
            }

            var entity = new Order
            {
                CustomerId = user.Id,
                State = OrderStates.MissingPayment,
                TotalAmount = 0,
                OrderDate = DateTime.UtcNow,
                DeletedByCustomer = false,
                DeletedByShop = false
            };

            if (request.UserAddress)
            {
                entity.CityId = user.CityId;
                entity.ShippingAddress = user.Address;
                entity.PostalCode = user.PostalCode;
            }
            else
            {
                if (!request.CityId.HasValue)
                {
                    throw new UserException("City is required.");
                }

                entity.CityId = request.CityId.Value;
                entity.ShippingAddress =request.ShippingAddress?? throw new UserException("Shipping address is required.");

                entity.PostalCode =request.ShippingPostalCode?? throw new UserException("Postal code is required.");
            }

            entity.OrderItems = new List<OrderItem>();

            foreach (var item in request.Product)
            {
                if (item.Quantity <= 0)
                {
                    throw new UserException("Quantity must be greater than 0.");
                }

                var product = products.First(x => x.Id == item.ProductId);

                if (product.Discount < 0 || product.Discount > 100)
                {
                    throw new UserException("Invalid discount on product.");
                }

                var totalPrice = product.Price * item.Quantity;

                var discountMultiplier = product.Discount / 100.0;

                var discountedPrice =totalPrice - (totalPrice * discountMultiplier);

                entity.TotalAmount += discountedPrice;

                entity.OrderItems.Add(new OrderItem
                {
                    ProductId = product.Id,
                    Quantity = item.Quantity,
                    UnitPrice = product.Price,
                    Discount = product.Discount,
                    TotalItemPrice = totalPrice,
                    TotalItemPriceDiscounted = discountedPrice
                });
            }

            entity.TotalAmount = Math.Round(entity.TotalAmount, 2);

            _context.Orders.Add(entity);

            await _context.SaveChangesAsync();

            await transaction.CommitAsync();

            return _mapper.Map<OrderModel>(entity);
        }

        public override async Task<List<string>> AllowedActions()
        {
            var list = await base.AllowedActions();

            list.Add(nameof(Insert));

            return list;
        }
    }
}
