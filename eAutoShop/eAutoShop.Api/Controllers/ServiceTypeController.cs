using eAutoShop.Model.Model;
using eAutoShop.Model.Request;
using eAutoShop.Model.SearchObjects;
using eAutoShop.Services.Helpers;
using eAutoShop.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace eAutoShop.Api.Controllers
{
    [ApiController]
    public class ServiceTypeController
        : BaseCRUDController<
            ServiceTypeModel,
            ServiceTypeSearchObject,
            ServiceTypeInsertRequest,
            ServiceTypeUpdateRequest>
    {
        public ServiceTypeController(
            IServiceTypeService service,
            ILogger<BaseCRUDController<
                ServiceTypeModel,
                ServiceTypeSearchObject,
                ServiceTypeInsertRequest,
                ServiceTypeUpdateRequest>> logger)
            : base(logger, service)
        {
        }

        [Authorize]
        public override Task<PageResult<ServiceTypeModel>> Get(
            [FromQuery] ServiceTypeSearchObject? search = null)
        {
            return base.Get(search);
        }

        [Authorize(Roles = UserRoles.Manager)]
        public override Task<ServiceTypeModel> Insert(
            [FromBody] ServiceTypeInsertRequest insert)
        {
            return base.Insert(insert);
        }

        [Authorize(Roles = UserRoles.Manager)]
        public override Task<ServiceTypeModel> Update(
            int id,
            [FromBody] ServiceTypeUpdateRequest update)
        {
            return base.Update(id, update);
        }

        [Authorize(Roles = UserRoles.Manager)]
        public override Task<IActionResult> Delete(int id)
        {
            return base.Delete(id);
        }
    }
}