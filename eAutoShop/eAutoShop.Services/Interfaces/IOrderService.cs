using eAutoShop.Model.Model;
using eAutoShop.Model.Request;
using eAutoShop.Model.SearchObjects;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace eAutoShop.Services.Interfaces
{
    public interface IOrderService : IBaseCRUDService<OrderModel, OrderSearchObject, OrderInsertRequest, OrderUpdateRequest>
    {
        Task<OrderModel> Accept(int id, OrderAcceptRequest orderAccept);
        Task<OrderModel> Complete(int id);
        Task<OrderModel> Reject(int id);
        Task<OrderModel> Cancel(int id);
        Task<OrderModel> Resend(int id);
        Task<List<string>> AllowedActions(int id);
        Task<OrderBasicInfoModel> GetBasicOrderInfo(int id);
        Task<OrderModel> SoftDelete(int id);
    }
}
