using eAutoShop.Model.Exceptions;
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
    public class AppointmentController : BaseCRUDController<AppointmentModel, AppointmentSearchObject, AppointmentInsertRequest, AppointmentUpdateRequest>
    {
        private IAppointmentService AppointmentService => (IAppointmentService)_service;

        public AppointmentController(IAppointmentService service,ILogger<BaseCRUDController<AppointmentModel, AppointmentSearchObject, AppointmentInsertRequest, AppointmentUpdateRequest>> logger): base(logger, service)
        {
        }

        [Authorize(Roles = UserRoles.Manager)]
        [HttpGet]
        public override async Task<PageResult<AppointmentModel>> Get([FromQuery] AppointmentSearchObject? search = null)
        {
            return await AppointmentService.Get(search);
        }

        [Authorize(Roles = UserRoles.Manager)]
        [HttpGet("{id}")]
        public override async Task<AppointmentModel> GetById(int id)
        {
            return await AppointmentService.GetById(id);
        }

        [Authorize(Roles = UserRoles.Customer)]
        [HttpPost]
        public override async Task<AppointmentModel> Insert([FromBody] AppointmentInsertRequest request)
        {
            return await AppointmentService.Insert(request);
        }

        [Authorize(Roles = UserRoles.Customer)]
        [HttpPut("{id}")]
        public override async Task<AppointmentModel> Update(int id, [FromBody] AppointmentUpdateRequest request)
        {
            return await AppointmentService.UpdateForCustomer(id,request,GetRequiredUsername());
        }

        [NonAction]
        public override Task<IActionResult> Delete(int id)
        {
            return base.Delete(id);
        }

        [Authorize(Roles = UserRoles.Manager)]
        [HttpPut("Confirm/{id}")]
        public async Task<AppointmentModel> Confirm(int id, [FromBody] AppointmentConfirmRequest request)
        {
            return await AppointmentService.Confirm(id, request);
        }

        [Authorize(Roles = UserRoles.Manager)]
        [HttpPut("Reject/{id}/{reason}")]
        public async Task<AppointmentModel> Reject(int id, string reason)
        {
            return await AppointmentService.Reject(id, reason);
        }

        [Authorize(Roles = UserRoles.Customer)]
        [HttpPut("Cancel/{id}/{reason}")]
        public async Task<AppointmentModel> Cancel(int id, string reason)
        {
            return await AppointmentService.CancelForCustomer(id,reason,GetRequiredUsername());
        }

        [Authorize(Roles = UserRoles.Technician)]
        [HttpPut("Start/{id}")]
        public async Task<AppointmentModel> Start(int id)
        {
            return await AppointmentService.StartForEmployee(id,GetRequiredUsername());
        }

        [Authorize(Roles = UserRoles.Technician)]
        [HttpPut("UpdateEstimatedDate/{id}/{newEstimatedCompletion}")]
        public async Task<AppointmentModel> UpdateEstimatedDate(int id, DateTime newEstimatedCompletion)
        {
            return await AppointmentService.UpdateEstimatedDateForEmployee(id,newEstimatedCompletion,GetRequiredUsername());
        }

        [Authorize(Roles = UserRoles.Technician)]
        [HttpPut("Complete/{id}")]
        public async Task<AppointmentModel> Complete(int id)
        {
            return await AppointmentService.CompleteForEmployee(id,GetRequiredUsername());
        }

        [Authorize(Roles = UserRoles.Customer + "," + UserRoles.Manager)]
        [HttpPut("SoftDelete/{id}")]
        public async Task<AppointmentModel> SoftDelete(int id)
        {
            return await AppointmentService.SoftDeleteForUser(id,GetRequiredRole(),GetRequiredUsername());
        }

        [Authorize(Roles = UserRoles.Manager + "," + UserRoles.Technician + "," + UserRoles.Customer)]
        [HttpGet("AllowedActions/{id}")]
        public async Task<List<string>> AllowedActions(int id)
        {
            return await AppointmentService.AllowedActionsForUser(id,GetRequiredRole(),GetRequiredUsername());
        }

        [Authorize(Roles = UserRoles.Manager)]
        [HttpGet("GetByShop")]
        public async Task<PageResult<AppointmentModel>> GetByShop([FromQuery] AppointmentSearchObject? search = null)
        {
            return await AppointmentService.Get(search);
        }

        [Authorize(Roles = UserRoles.Technician)]
        [HttpGet("GetByEmployee")]
        public async Task<PageResult<AppointmentModel>> GetByEmployee([FromQuery] AppointmentSearchObject? search = null)
        {
            return await AppointmentService.GetByEmployee(search,GetRequiredUsername());
        }

        [Authorize(Roles = UserRoles.Customer)]
        [HttpGet("GetByCustomer")]
        public async Task<PageResult<AppointmentModel>> GetByCustomer([FromQuery] AppointmentSearchObject? search = null)
        {
            return await AppointmentService.GetByCustomer(search,GetRequiredUsername());
        }

        private string GetRequiredUsername()
        {
            string? username = User.FindFirst(ClaimTypes.Name)?.Value;

            if (string.IsNullOrWhiteSpace(username))
                throw new UserException("Signed-in user was not found.");

            return username;
        }

        private string GetRequiredRole()
        {
            string? role = User.FindFirst(ClaimTypes.Role)?.Value;

            if (string.IsNullOrWhiteSpace(role))
                throw new UserException("Signed-in user role was not found.");

            return role;
        }
    }
}