using eAutoShop.Model.Model;
using eAutoShop.Model.SearchObjects;
using eAutoShop.Services.Database;
using eAutoShop.Services.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace eAutoShop.Api.Controllers
{
    [ApiController]
    public class CarModelController : BaseController<CarModelModel, CarModelSearchObject>
    {
        public CarModelController(ICarModelService service, ILogger<BaseController<CarModelModel, CarModelSearchObject>> logger) : base(logger, service)
        {
        }

        [HttpGet("/GetByManufacturerAll")]
        public virtual async Task<PageResult<CarModelGetByManufacturerModel>> GetByManufacturerAll()
        {
            return await (_service as ICarModelService).GetByManufacturerAll();
        }
    }
}
