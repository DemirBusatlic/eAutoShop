using eAutoShop.Model.Model;
using eAutoShop.Model.Request;
using eAutoShop.Model.SearchObjects;
using eAutoShop.Services.Database;
using eAutoShop.Services.Interfaces;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace eAutoShop.Services.Services
{
    public class OrderItemService : BaseCRUDService<OrderItemModel,OrderItem,OrderItemSearchObject,OrderItemInsertRequest,OrderItemUpdateRequest>, IOrderItemService
    {
        public OrderItemService(AutoShopContext context,IMapper mapper) : base(context, mapper)
        {
        }

        public override IQueryable<OrderItem> AddInclude(IQueryable<OrderItem> query,OrderItemSearchObject? search = null)
        {
            query = query.Include(x => x.Product);

            return base.AddInclude(query, search);
        }

        public override IQueryable<OrderItem> AddFilter(IQueryable<OrderItem> query,OrderItemSearchObject? search = null)
        {
            if (search != null)
            {
                if (search.OrderId != null)
                {
                    query = query.Where(x => x.OrderId == search.OrderId);
                }
            }

            return base.AddFilter(query, search);
        }
    }
}
