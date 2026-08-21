using eAutoShop.Model.Model;
using eAutoShop.Model.Request;
using eAutoShop.Model.SearchObjects;
using eAutoShop.Services.Helpers;
using eAutoShop.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace eAutoShop.Api.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class AppointmentController: BaseCRUDController<AppointmentModel, AppointmentSearchObject, AppointmentInsertRequest, AppointmentUpdateRequest>
    {
        public AppointmentController(IAppointmentService service,ILogger<BaseCRUDController<AppointmentModel, AppointmentSearchObject, AppointmentInsertRequest, AppointmentUpdateRequest>> logger): base(logger, service)
        {
        }

        [Authorize(Roles = UserRoles.Customer)]
        [HttpPost]
        public override async Task<AppointmentModel> Insert([FromBody] AppointmentInsertRequest request)
        {
            return await (_service as IAppointmentService)!.Insert(request);
        }

        [Authorize(Roles = UserRoles.Manager + "," + UserRoles.Salesperson)]
        [HttpPut("Confirm/{id}")]
        public async Task<AppointmentModel> Confirm(int id,[FromBody] AppointmentConfirmRequest request)
        {
            return await (_service as IAppointmentService)!.Confirm(id, request);
        }

        [Authorize(Roles = UserRoles.Manager + "," + UserRoles.Salesperson)]
        [HttpPut("Reject/{id}/{reason}")]
        public async Task<AppointmentModel> Reject(int id, string reason)
        {
            return await (_service as IAppointmentService)!.Reject(id, reason);
        }

        [Authorize]
        [HttpPut("Cancel/{id}/{reason}")]
        public async Task<AppointmentModel> Cancel(int id, string reason)
        {
            return await (_service as IAppointmentService)!.Cancel(id, reason);
        }

        [Authorize(Roles = UserRoles.Manager + "," + UserRoles.Salesperson)]
        [HttpPut("Start/{id}")]
        public async Task<AppointmentModel> Start(int id)
        {
            return await (_service as IAppointmentService)!.Start(id);
        }

        [Authorize(Roles = UserRoles.Manager + "," + UserRoles.Salesperson)]
        [HttpPut("UpdateEstimatedDate/{id}/{newEstimatedCompletion}")]
        public async Task<AppointmentModel> UpdateEstimatedDate(int id, DateTime newEstimatedCompletion)
        {
            return await (_service as IAppointmentService)!.UpdateEstimatedDate(id, newEstimatedCompletion);
        }

        [Authorize(Roles =UserRoles.Manager + "," + UserRoles.Salesperson)]
        [HttpPut("Complete/{id}")]
        public async Task<AppointmentModel> Complete(int id)
        {
            return await (_service as IAppointmentService)!.Complete(id);
        }

        [Authorize]
        [HttpPut("SoftDelete/{id}")]
        public async Task<AppointmentModel> SoftDelete(int id)
        {
            string role = User.FindFirst(ClaimTypes.Role)?.Value!;
            return await (_service as IAppointmentService)!.SoftDelete(id, role);
        }

        [Authorize]
        [HttpGet("AllowedActions/{id}")]
        public async Task<List<string>> AllowedActions(int id)
        {
            return await (_service as IAppointmentService)!.AllowedActions(id);
        }

        [Authorize(Roles = UserRoles.Manager + "," + UserRoles.Salesperson)]
        [HttpGet("GetByShop")]
        public async Task<PageResult<AppointmentModel>> GetByShop([FromQuery] AppointmentSearchObject? search = null)
        {
            search ??= new AppointmentSearchObject();

            return await (_service as IAppointmentService)!.Get(search);
        }

        [Authorize(Roles = UserRoles.Customer)]
        [HttpGet("GetByCustomer")]
        public async Task<PageResult<AppointmentModel>> GetByCustomer([FromQuery] AppointmentSearchObject? search = null)
        {
            search ??= new AppointmentSearchObject();

            string? username =User.FindFirst(ClaimTypes.Name)?.Value;
            search.CustomerUsername = username;

            return await (_service as IAppointmentService)!.Get(search);
        }
    }
}
