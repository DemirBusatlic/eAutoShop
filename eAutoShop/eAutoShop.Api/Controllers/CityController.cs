using eAutoShop.Model.Model;
using eAutoShop.Model.Request;
using eAutoShop.Model.SearchObjects;
using eAutoShop.Services.Database;
using eAutoShop.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace eAutoShop.Api.Controllers
{
   
    [ApiController]
    public class CityController : BaseCRUDController<CityModel,CitySearchObject,CityInsertRequest,CityUpdateRequest>
    {
        public CityController(ICityService service, ILogger<BaseCRUDController<CityModel, CitySearchObject, CityInsertRequest, CityUpdateRequest>> logger) : base(logger, service)
        {
        }

        [AllowAnonymous]
        public override async Task<PageResult<CityModel>> Get([FromQuery] CitySearchObject? search = null)
        {
            return await _service.Get(search);
        }
    }
}
