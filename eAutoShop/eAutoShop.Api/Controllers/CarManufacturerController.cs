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
    public class CarManufacturerController: BaseCRUDController<CarManufacturerModel,CarManufacturerSearchObject,CarManufacturerInsertRequest,CarManufacturerUpdateRequest>
    {
        public CarManufacturerController(ILogger<BaseCRUDController<CarManufacturerModel,CarManufacturerSearchObject,CarManufacturerInsertRequest,CarManufacturerUpdateRequest>> logger,ICarManufacturerService service): base(logger, service)
        {
        }

        [Authorize]
        public override Task<PageResult<CarManufacturerModel>> Get([FromQuery] CarManufacturerSearchObject? search = null)
        {
            return base.Get(search);
        }

        [Authorize(Roles = UserRoles.Manager)]
        public override Task<CarManufacturerModel> Insert([FromBody] CarManufacturerInsertRequest insert)
        {
            return base.Insert(insert);
        }

        [Authorize(Roles = UserRoles.Manager)]
        public override Task<CarManufacturerModel> Update(int id,[FromBody] CarManufacturerUpdateRequest update)
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