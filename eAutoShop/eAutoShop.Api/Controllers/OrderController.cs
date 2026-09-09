using eAutoShop.Model.Exceptions;
using eAutoShop.Model.Model;
using eAutoShop.Model.Request;
using eAutoShop.Model.SearchObjects;
using eAutoShop.Services.Interfaces;
using eAutoShop.Services.Helpers;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;
using eAutoShop.Api.SignalR;

namespace eAutoShop.Api.Controllers
{

    [ApiController]
    public class OrderController : BaseCRUDController<OrderModel, OrderSearchObject, OrderInsertRequest, OrderUpdateRequest>
    {
        private readonly NotificationService _notificationService;
        private readonly ILogger<OrderController> _orderLogger;
        public OrderController(IOrderService service,NotificationService notificationService,ILogger<OrderController> orderLogger,ILogger<BaseCRUDController<OrderModel,OrderSearchObject,OrderInsertRequest,OrderUpdateRequest>> logger): base(logger, service)
        {
            _notificationService = notificationService;
            _orderLogger = orderLogger;
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
            var order = await (_service as IOrderService)!.Accept(id, orderAccept);

            if (order.CustomerId.HasValue)
            {
                try
                {
                    await _notificationService.SendUserNotification(order.CustomerId.Value,"Vaša narudžba je prihvaćena.","orderstatuschanged");
                }
                catch (Exception exception)
                {
                    _orderLogger.LogError(exception,"Slanje notifikacije o prihvatanju narudžbe {OrderId} korisniku {CustomerId} nije uspjelo.",order.Id,order.CustomerId.Value);
                }
            }

            return order;
        }

        [Authorize(Roles = UserRoles.Manager + "," + UserRoles.Salesperson)]
        [HttpPut("Reject/{id}")]
        public virtual async Task<OrderModel> Reject(int id)
        {
            var order = await (_service as IOrderService)!.Reject(id);

            if (order.CustomerId.HasValue)
            {
                try
                {
                    await _notificationService.SendUserNotification(order.CustomerId.Value,"Vaša narudžba je odbijena.","orderstatuschanged");
                }
                catch (Exception exception)
                {
                    _orderLogger.LogError(exception, "Slanje notifikacije o odbijanju narudžbe {OrderId} korisniku {CustomerId} nije uspjelo.",order.Id, order.CustomerId.Value);
                }
            }

            return order;
        }

        [Authorize(Roles = UserRoles.Manager + "," +UserRoles.Salesperson)]
        [HttpPut("Complete/{id}")]
        public virtual async Task<OrderModel> Complete(int id)
        {
            var order = await (_service as IOrderService)!.Complete(id);

            if (order.CustomerId.HasValue)
            {
                try
                {
                    await _notificationService.SendUserNotification(order.CustomerId.Value, "Vaša narudžba je završena.","orderstatuschanged");
                }
                catch (Exception exception)
                {
                    _orderLogger.LogError(exception, "Slanje notifikacije o završetku narudžbe {OrderId} korisniku {CustomerId} nije uspjelo.", order.Id,order.CustomerId.Value);
                }
            }

            return order;
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
