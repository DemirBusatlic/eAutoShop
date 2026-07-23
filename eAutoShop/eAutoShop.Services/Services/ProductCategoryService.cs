using eAutoShop.Model.Model;
using eAutoShop.Model.SearchObjects;
using eAutoShop.Services.Database;
using eAutoShop.Services.Interfaces;
using MapsterMapper;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace eAutoShop.Services.Services
{
    public class ProductCategoryService : BaseService<ProductCategoryModel, ProductCategory, ProductCategorySearchObject>, IProductCategoryService
    {
        public ProductCategoryService(AutoShopContext context, IMapper mapper) : base(context, mapper)
        {
        }

        public override IQueryable<ProductCategory> AddFilter(IQueryable<ProductCategory> query, ProductCategorySearchObject? search = null)
        {
            query = query.OrderBy(sc => sc.Name);
            return base.AddFilter(query, search);
        }
    }
}
