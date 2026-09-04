using eAutoShop.Model.Model;
using eAutoShop.Model.SearchObjects;
using eAutoShop.Services.Database;
using eAutoShop.Services.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace eAutoShop.Api.Controllers
{
    [ApiController]
    public class ServiceTypeController : BaseController<ServiceTypeModel, ServiceTypeSearchObject>
    {
        public ServiceTypeController(IServiceTypeService service, ILogger<BaseController<ServiceTypeModel, ServiceTypeSearchObject>> logger) : base(logger, service)
        {

        }
    }
}
