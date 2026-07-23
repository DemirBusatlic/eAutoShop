using eAutoShop.Model.Model;
using eAutoShop.Model.SearchObjects;
using eAutoShop.Services.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace eAutoShop.Api.Controllers
{
    [ApiController]
    public class AppointmentDetailController : BaseController<AppointmentDetailModel, AppointmentDetailSearchObject>
    {
        public AppointmentDetailController(IAppointmentDetailService service, ILogger<BaseController<AppointmentDetailModel, AppointmentDetailSearchObject>> logger) : base(logger, service)
        {

        }
    }
}
