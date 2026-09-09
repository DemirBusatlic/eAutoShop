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
    public class RoleController : BaseController<RoleModel, RoleSearchObject>
    {
        public RoleController(IRoleService service, ILogger<BaseController<RoleModel, RoleSearchObject>> logger) : base(logger, service)
        {
        }
    }
}
