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
    public class CarModelController: BaseCRUDController<CarModelModel,CarModelSearchObject,CarModelInsertRequest,CarModelUpdateRequest>
    {
        private readonly ICarModelService _carModelService;

        public CarModelController(ICarModelService service,ILogger<BaseCRUDController<CarModelModel,CarModelSearchObject,CarModelInsertRequest,CarModelUpdateRequest>> logger): base(logger, service)
        {
            _carModelService = service;
        }

        [Authorize]
        public override Task<PageResult<CarModelModel>> Get([FromQuery] CarModelSearchObject? search = null)
        {
            return base.Get(search);
        }

        [Authorize(Roles = UserRoles.Manager)]
        public override Task<CarModelModel> Insert([FromBody] CarModelInsertRequest insert)
        {
            return base.Insert(insert);
        }

        [Authorize(Roles = UserRoles.Manager)]
        public override Task<CarModelModel> Update(int id,[FromBody] CarModelUpdateRequest update)
        {
            return base.Update(id, update);
        }

        [Authorize(Roles = UserRoles.Manager)]
        public override Task<IActionResult> Delete(int id)
        {
            return base.Delete(id);
        }

        [Authorize]
        [HttpGet("/GetByManufacturerAll")]
        public async Task<PageResult<CarModelGetByManufacturerModel>>GetByManufacturerAll()
        {
            return await _carModelService.GetByManufacturerAll();
        }
    }
}