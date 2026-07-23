using eAutoShop.Model.Model;
using eAutoShop.Model.Request;
using eAutoShop.Model.SearchObjects;
using eAutoShop.Services.Interfaces;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace eAutoShop.Api.Controllers
{
    [ApiController]
    public class OrderItemController : BaseCRUDController<OrderItemModel, OrderItemSearchObject, OrderItemInsertRequest, OrderItemUpdateRequest>
    {
        public OrderItemController(IOrderItemService service, ILogger<BaseCRUDController<OrderItemModel, OrderItemSearchObject, OrderItemInsertRequest, OrderItemUpdateRequest>> logger) : base(logger,service)
        {
        }
    }
}
