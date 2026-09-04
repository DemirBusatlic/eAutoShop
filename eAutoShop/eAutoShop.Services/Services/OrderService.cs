using eAutoShop.Model.Exceptions;
using eAutoShop.Model.Model;
using eAutoShop.Model.Request;
using eAutoShop.Model.SearchObjects;
using eAutoShop.Services.Database;
using eAutoShop.Services.Helpers;
using eAutoShop.Services.Interfaces;
using eAutoShop.Services.StateMachineService.OrderStateMachine;
using MapsterMapper;
using Microsoft.AspNetCore.Http;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;

namespace eAutoShop.Services.Services
{
    public class OrderService : BaseCRUDService<OrderModel, Order, OrderSearchObject, OrderInsertRequest, OrderUpdateRequest>, IOrderService
    {
        private readonly BaseOrderState _baseOrderState;
        private readonly IHttpContextAccessor _httpContextAccessor;

        public OrderService(AutoShopContext context, IMapper mapper, BaseOrderState baseOrderState, IHttpContextAccessor httpContextAccessor) : base(context, mapper)
        {
            _baseOrderState = baseOrderState;
            _httpContextAccessor = httpContextAccessor;
        }

        public override IQueryable<Order> AddInclude(IQueryable<Order> query, OrderSearchObject? search = null)
        {
            query = query.Include(o => o.Customer).Include(o => o.City);

            if (search?.IncludeItems == true)
            {
                query = query
                    .Include(o => o.OrderItems)
                    .ThenInclude(oi => oi.Product);
            }

            return base.AddInclude(query, search);
        }

        public override IQueryable<Order> AddFilter(IQueryable<Order> query, OrderSearchObject? search = null)
        {
            query = query.OrderByDescending(o => o.Id);

            query = ApplyScope(query);

            if (search == null)
                return base.AddFilter(query, search);

            if (!string.IsNullOrWhiteSpace(search.CustomerName))
            {
                var term = search.CustomerName.Trim();

                query = query.Where(o =>
                    o.Customer != null &&
                    (
                        o.Customer.Username.Contains(term) ||
                        o.Customer.Name.Contains(term) ||
                        o.Customer.Surname.Contains(term)
                    ));
            }

            if (search.HasDiscount.HasValue)
            {
                query = search.HasDiscount.Value ? query.Where(o => o.OrderItems.Any(oi => oi.Discount > 0))
                    : query.Where(o => !o.OrderItems.Any(oi => oi.Discount > 0));
            }

            if (!string.IsNullOrWhiteSpace(search.State))
            {
                var state = search.State.Trim();

                query = query.Where(o => o.State == state);
            }

            if (search.MinTotalAmount.HasValue)
                query = query.Where(o => o.TotalAmount >= search.MinTotalAmount.Value);

            if (search.MaxTotalAmount.HasValue)
                query = query.Where(o => o.TotalAmount <= search.MaxTotalAmount.Value);

            if (search.MinOrderDate.HasValue)
                query = query.Where(o => o.OrderDate >= search.MinOrderDate.Value);

            if (search.MaxOrderDate.HasValue) query = query.Where(o => o.OrderDate <= search.MaxOrderDate.Value);

            if (search.MinShippingDate.HasValue) query = query.Where(o => o.ShippingDate >= search.MinShippingDate.Value);

            if (search.MaxShippingDate.HasValue) query = query.Where(o => o.ShippingDate <= search.MaxShippingDate.Value);

            return base.AddFilter(query, search);
        }

        private IQueryable<Order> ApplyScope(IQueryable<Order> query)
        {
            var user = _httpContextAccessor.HttpContext?.User
                ?? throw new UserException("Unauthorized.");

            var role = GetCurrentUserRole(user);
            var username = GetCurrentUsername(user);

            if (role == UserRoles.Customer)
            {
                return query.Where(o =>
                    o.Customer != null &&
                    o.Customer.Username == username &&
                    !o.DeletedByCustomer);
            }

            return query.Where(o => !o.DeletedByShop);
        }

        private static string GetCurrentUserRole(ClaimsPrincipal user)
        {
            return user.FindFirst(ClaimTypes.Role)?.Value?.Trim().ToLowerInvariant() ?? throw new UserException("Unauthorized.");
        }

        private static string GetCurrentUsername(ClaimsPrincipal user)
        {
            return user.FindFirst(ClaimTypes.Name)?.Value?.Trim() ?? throw new UserException("Unauthorized.");
        }

        private static int GetCurrentUserId(ClaimsPrincipal user)
        {
            return int.Parse(user.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? throw new UserException("Unauthorized."));
        }

        public async Task<OrderBasicInfoModel> GetBasicOrderInfo(int id)
        {
            IQueryable<Order> query = _context.Orders
                .AsNoTracking()
                .Include(o => o.Customer)
                .Include(o => o.OrderItems)
                    .ThenInclude(oi => oi.Product);

            query = ApplyScope(query);

            var entity = await query.FirstOrDefaultAsync(o => o.Id == id);

            if (entity == null)
                throw new UserException($"Order #{id} doesn't exist!");

            if (!entity.OrderItems.Any())
                throw new UserException("No order items found!");

            var model = _mapper.Map<OrderBasicInfoModel>(entity);

            model.Items = entity.OrderItems
                .Select(oi => $"{oi.Quantity}x {oi.Product.Name}")
                .ToList();

            return model;
        }

        public override async Task<OrderModel> Insert(OrderInsertRequest request)
        {
            var state = _baseOrderState.CreateState("initial");

            return await state.Insert(request);
        }

        public override async Task<OrderModel> Update(int id, OrderUpdateRequest request)
        {
            var entity = await _context.Orders.FindAsync(id);

            if (entity == null)
                throw new UserException("Order not found.");

            var state = _baseOrderState.CreateState(entity.State);

            return await state.Update(entity, request);
        }

        public async Task<OrderModel> Accept(int id, OrderAcceptRequest orderAccept)
        {
            var entity = await _context.Orders.FindAsync(id);

            if (entity == null)
                throw new UserException("Order not found.");

            var state = _baseOrderState.CreateState(entity.State);

            return await state.Accept(entity, orderAccept);
        }

        public async Task<OrderModel> Complete(int id)
        {
            var entity = await _context.Orders.FindAsync(id);

            if (entity == null)
            {
                throw new UserException("Order not found.");
            }

            var state = _baseOrderState.CreateState(entity.State);

            return await state.Complete(entity);
        }

        public async Task<OrderModel> Reject(int id)
        {
            var entity = await _context.Orders.FindAsync(id);

            if (entity == null)
                throw new UserException("Order not found.");

            var state = _baseOrderState.CreateState(entity.State);

            return await state.Reject(entity);
        }


        public async Task<OrderModel> SoftDelete(int id)
        {
            var entity = await _context.Orders.FindAsync(id);

            if (entity == null)
                throw new UserException("Order not found.");

            var role = GetCurrentUserRole(
                _httpContextAccessor.HttpContext!.User);

            var state = _baseOrderState.CreateState(entity.State);

            return await state.SoftDelete(entity, role);
        }

        public async Task<OrderModel> Cancel(int id)
        {
            var entity = await _context.Orders
                .Include(x => x.Customer)
                .FirstOrDefaultAsync(x => x.Id == id);

            if (entity == null)
                throw new UserException("Order not found.");

            var user = _httpContextAccessor.HttpContext!.User;

            var role = GetCurrentUserRole(user);

            var userId = GetCurrentUserId(user);

            if (role == "customer" && entity.CustomerId != userId)
            {
                throw new UserException("You cannot cancel another user's order.");
            }

            var state = _baseOrderState.CreateState(entity.State);

            return await state.Cancel(entity);
        }

        public async Task<OrderModel> Resend(int id)
        {
            var entity = await _context.Orders.FindAsync(id);

            if (entity == null)
                throw new UserException("Order not found.");

            var state = _baseOrderState.CreateState(entity.State);

            return await state.Resend(entity);
        }

        public async Task<List<string>> AllowedActions(int id)
        {
            var entity = await _context.Orders.FindAsync(id);

            if (entity == null)
                throw new UserException("Order not found.");

            var state = _baseOrderState.CreateState(entity.State);

            return await state.AllowedActions();
        }
    }
}
