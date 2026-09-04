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
    [Route("[controller]")]
    [Authorize]
    public class AutoShopServiceController : BaseCRUDController<AutoShopServiceModel, AutoShopServiceSearchObject, AutoShopServiceInsertRequest, AutoShopServiceUpdateRequest>
    {
        private readonly IAutoShopServiceService _autoShopServiceService;

        public AutoShopServiceController(ILogger<BaseController<AutoShopServiceModel, AutoShopServiceSearchObject>> logger, IAutoShopServiceService service) : base(logger, service)
        {
            _autoShopServiceService = service;
        }

        [Authorize(Roles = $"{UserRoles.Manager},{UserRoles.Salesperson},{UserRoles.Technician}")]
        [HttpPut("{id}/activate")]
        public async Task<AutoShopServiceModel> Activate(int id)
        {
            return await _autoShopServiceService.Activate(id);
        }

        [Authorize(Roles = $"{UserRoles.Manager},{UserRoles.Salesperson},{UserRoles.Technician}")]
        [HttpPut("{id}/hide")]
        public async Task<AutoShopServiceModel> Hide(int id)
        {
            return await _autoShopServiceService.Hide(id);
        }

        [Authorize(Roles = $"{UserRoles.Manager},{UserRoles.Salesperson},{UserRoles.Technician}")]
        [HttpGet("{id}/allowed-actions")]
        public async Task<List<string>> AllowedActions(int id)
        {
            return await _autoShopServiceService.AllowedActions(id);
        }
    }

}
