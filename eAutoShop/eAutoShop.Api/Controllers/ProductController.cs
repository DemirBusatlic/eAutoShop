using eAutoShop.Api.SignalR;
using eAutoShop.Model.Model;
using eAutoShop.Model.Request;
using eAutoShop.Model.SearchObjects;
using eAutoShop.Services.Helpers;
using eAutoShop.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace eAutoShop.Api.Controllers
{
    [AllowAnonymous]
    [ApiController]
    public class ProductController : BaseCRUDController<ProductModel, ProductSearchObject, ProductInsertRequest, ProductUpdateRequest>
    {
        private readonly NotificationService _notificationService;

        public ProductController(IProductService service, ILogger<BaseCRUDController<ProductModel, ProductSearchObject, ProductInsertRequest, ProductUpdateRequest>> logger, NotificationService notificationService)
            : base(logger, service)
        {
            _notificationService = notificationService;
        }

        [Authorize(Roles = "manager,salesperson")]
        [HttpPut("{id}/activate")]
        public async Task<ProductModel> Activate(int id)
        {
            var activatedProduct = await (_service as IProductService)!.Activate(id);

            var price = activatedProduct.DiscountedPrice > 0 ? activatedProduct.DiscountedPrice : activatedProduct.Price;

            var message = $"Product activated: " + $"{activatedProduct.Name} " + $"({activatedProduct.Category}) - " + $"{price:0.00}";

            await _notificationService.SendServiceNotification(message, "product_activated");

            return activatedProduct;
        }

        [Authorize(Roles = "manager,salesperson")]
        [HttpPut("{id}/hide")]
        public virtual async Task<ProductModel> Hide(int id)
        {
            return await (_service as IProductService)!.Hide(id);
        }

        [Authorize(Roles = "manager,salesperson")]
        [HttpGet("{id}/allowed-actions")]
        public virtual async Task<List<string>> AllowedActions(int id)
        {
            return await (_service as IProductService)!.AllowedActions(id);
        }

        [Authorize(Roles = "manager,salesperson")]
        [HttpPost]
        public override async Task<ProductModel> Insert(ProductInsertRequest request)
        {
            return await (_service as IProductService)!.Insert(request);
        }

        [Authorize(Roles = "customer,manager,salesperson,technician")]
        [HttpGet("active")]
        public async Task<PageResult<ProductModel>> GetActive([FromQuery] ProductSearchObject? search = null)
        {
            search ??= new ProductSearchObject();

            search.State ??= ProductStates.Active;

            return await (_service as IProductService)!.Get(search);
        }
    }
}
