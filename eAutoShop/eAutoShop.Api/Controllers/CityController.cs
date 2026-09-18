using eAutoShop.Model.Model;
using eAutoShop.Model.Request;
using eAutoShop.Model.SearchObjects;
using eAutoShop.Services.Database;
using eAutoShop.Services.Helpers;
using eAutoShop.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace eAutoShop.Api.Controllers
{
    [ApiController]
    public class CityController: BaseCRUDController<CityModel,CitySearchObject,CityInsertRequest,CityUpdateRequest>
    {
        public CityController(ICityService service,ILogger<BaseCRUDController<CityModel,CitySearchObject,CityInsertRequest,CityUpdateRequest>> logger): base(logger, service)
        {
        }

        [Authorize]
        public override async Task<PageResult<CityModel>> Get([FromQuery] CitySearchObject? search = null)
        {
            return await _service.Get(search);
        }

        [AllowAnonymous]
        [HttpGet("RegistrationLookup")]
        public async Task<PageResult<CityModel>>GetRegistrationLookup()
        {
            return await _service.Get(new CitySearchObject{Page = 1, PageSize = 100});
        }

        [Authorize(Roles = UserRoles.Manager)]
        public override Task<CityModel> Insert([FromBody] CityInsertRequest insert)
        {
            return base.Insert(insert);
        }

        [Authorize(Roles = UserRoles.Manager)]
        public override Task<CityModel> Update(int id,[FromBody] CityUpdateRequest update)
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
