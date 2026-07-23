using eAutoShop.Model.Model;
using eAutoShop.Model.SearchObjects;
using eAutoShop.Services.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace eAutoShop.Api.Controllers
{
    [ApiController]
    public class ProductCategoryController : BaseController<ProductCategoryModel, ProductCategorySearchObject>
    {
        public ProductCategoryController(ILogger<BaseController<ProductCategoryModel, ProductCategorySearchObject>> logger, IProductCategoryService service) : base(logger, service)
        {
        }
    }
}
