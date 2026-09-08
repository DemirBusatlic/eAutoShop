using eAutoShop.Model.Exceptions;
using eAutoShop.Model.Model;
using eAutoShop.Model.Request;
using eAutoShop.Model.SearchObjects;
using eAutoShop.Services.Interfaces;
using eAutoShop.Services.Helpers;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace eAutoShop.Api.Controllers
{

    [ApiController]
    public class OrderController : BaseCRUDController<OrderModel, OrderSearchObject, OrderInsertRequest, OrderUpdateRequest>
    {
        public OrderController(IOrderService service, ILogger<BaseCRUDController<OrderModel, OrderSearchObject, OrderInsertRequest, OrderUpdateRequest>> logger) : base(logger, service)
        {
        }
        [Authorize(Roles = UserRoles.Customer)]
        [HttpPost]
        public override async Task<OrderModel> Insert(OrderInsertRequest request)
        {
            string? username = User.FindFirst(ClaimTypes.Name)?.Value;

            request.Username = username;

            return await (_service as IOrderService)!.Insert(request);
        }
        [Authorize(Roles = UserRoles.Manager + "," + UserRoles.Salesperson)]
        [HttpPut("Accept/{id}")]
        public virtual async Task<OrderModel> Accept(int id, OrderAcceptRequest orderAccept)
        {
            return await (_service as IOrderService)!.Accept(id, orderAccept);
        }

        [Authorize(Roles = UserRoles.Manager + "," + UserRoles.Salesperson)]
        [HttpPut("Reject/{id}")]
        public virtual async Task<OrderModel> Reject(int id)
        {
            return await (_service as IOrderService)!.Reject(id);
        }

        [Authorize(Roles = UserRoles.Manager + "," + UserRoles.Salesperson)]
        [HttpPut("Complete/{id}")]
        public virtual async Task<OrderModel> Complete(int id)
        {
            return await (_service as IOrderService)!.Complete(id);
        }
        [Authorize(Roles = UserRoles.Manager + "," + UserRoles.Salesperson + "," + UserRoles.Customer)]
        [HttpPut("Cancel/{id}")]
        public virtual async Task<OrderModel> Cancel(int id)
        {
            return await (_service as IOrderService)!.Cancel(id);
        }
        [Authorize(Roles = UserRoles.Customer)]
        [HttpPut("Resend/{id}")]
        public virtual async Task<OrderModel> Resend(int id)
        {
            return await (_service as IOrderService)!.Resend(id);
        }
        [Authorize(Roles = UserRoles.Manager + "," + UserRoles.Salesperson + "," + UserRoles.Customer + "," + UserRoles.Technician)]
        [HttpPut("SoftDelete/{id}")]
        public virtual async Task<OrderModel> SoftDelete(int id)
        {
            return await (_service as IOrderService)!.SoftDelete(id);
        }


        [Authorize]
        [HttpGet("AllowedActions/{id}")]
        public virtual async Task<List<string>> AllowedActions(int id)
        {
            return await (_service as IOrderService)!.AllowedActions(id);
        }

        [Authorize]
        [HttpGet("GetBasicOrderInfo/{id}")]
        public virtual async Task<OrderBasicInfoModel> GetBasicOrderInfo(int id)
        {
            return await (_service as IOrderService)!.GetBasicOrderInfo(id);
        }
        [Authorize(Roles = UserRoles.Manager + "," + UserRoles.Salesperson + "," + UserRoles.Technician)]
        [HttpGet("shop")]
        public async Task<PageResult<OrderModel>> GetForShop([FromQuery] OrderSearchObject? search = null)
        {
            return await (_service as IOrderService)!.Get(search);
        }
        [Authorize(Roles = UserRoles.Customer)]
        [HttpGet("GetByClient")]
        public async Task<PageResult<OrderModel>> GetByClient([FromQuery] OrderSearchObject? search = null)
        {
            return await (_service as IOrderService)!.Get(search);
        }
    }
}
