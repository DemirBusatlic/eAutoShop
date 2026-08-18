using eAutoShop.Model.Exceptions;
using eAutoShop.Model.Model;
using eAutoShop.Model.Request;
using eAutoShop.Model.SearchObjects;
using eAutoShop.Services.Database;
using eAutoShop.Services.Helpers;
using eAutoShop.Services.Interfaces;
using MapsterMapper;
using Microsoft.AspNetCore.Http;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;

namespace eAutoShop.Services.Services
{
    public class OrderItemService : BaseCRUDService<OrderItemModel, OrderItem, OrderItemSearchObject, OrderItemInsertRequest, OrderItemUpdateRequest>, IOrderItemService
    {
        private readonly IHttpContextAccessor _httpContextAccessor;

        public OrderItemService(AutoShopContext context,IMapper mapper,IHttpContextAccessor httpContextAccessor): base(context, mapper)
        {
            _httpContextAccessor = httpContextAccessor;
        }

        public override IQueryable<OrderItem> AddInclude(IQueryable<OrderItem> query, OrderItemSearchObject? search = null)
        {
            query = query.Include(x => x.Product);
            return base.AddInclude(query, search);
        }

        public override IQueryable<OrderItem> AddFilter(IQueryable<OrderItem> query, OrderItemSearchObject? search = null)
        {
            var user = _httpContextAccessor.HttpContext?.User ?? throw new UserException("Unauthorized.");

            var role = user.FindFirst(ClaimTypes.Role)?.Value?.Trim().ToLowerInvariant();

            if (role == UserRoles.Customer)
            {
                var idValue = user.FindFirst(ClaimTypes.NameIdentifier)?.Value;

                if (!int.TryParse(idValue, out var userId))
                    throw new UserException("Unauthorized.");

                query = query.Where(x => x.Order.CustomerId == userId && !x.Order.DeletedByCustomer);
            }

            if (search?.OrderId != null)
                query = query.Where(x => x.OrderId == search.OrderId);

            return base.AddFilter(query, search);
        }
    }
}
