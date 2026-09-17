using System.Security.Claims;
using eAutoShop.Model.Exceptions;
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
    public class EmployeeTaskController: BaseController<EmployeeTaskModel, EmployeeTaskSearchObject>
    {
        private readonly IEmployeeTaskService _employeeTaskService;

        public EmployeeTaskController(IEmployeeTaskService service,ILogger<BaseController<EmployeeTaskModel,EmployeeTaskSearchObject>> logger): base(logger, service)
        {
            _employeeTaskService = service;
        }

        [Authorize(Roles = UserRoles.Manager)]
        [HttpGet]
        public override async Task<PageResult<EmployeeTaskModel>> Get([FromQuery] EmployeeTaskSearchObject? search = null)
        {
            return await _employeeTaskService.Get(search);
        }

        [Authorize(Roles = UserRoles.Manager)]
        [HttpGet("{id}")]
        public override async Task<EmployeeTaskModel> GetById(int id)
        {
            return await _employeeTaskService.GetById(id);
        }

        [Authorize(Roles = UserRoles.Manager)]
        [HttpPost]
        public async Task<EmployeeTaskModel> Insert([FromBody] EmployeeTaskInsertRequest request)
        {
            return await _employeeTaskService.Insert(request, GetRequiredUsername());
        }

        [Authorize(Roles = UserRoles.Salesperson + "," + UserRoles.Technician)]
        [HttpGet("GetByEmployee")]
        public async Task<PageResult<EmployeeTaskModel>> GetByEmployee([FromQuery] EmployeeTaskSearchObject? search = null)
        {
            return await _employeeTaskService.GetByEmployee(search, GetRequiredUsername());
        }

        [Authorize(Roles = UserRoles.Salesperson + "," + UserRoles.Technician)]
        [HttpPut("Complete/{id}")]
        public async Task<EmployeeTaskModel> Complete(int id)
        {
            return await _employeeTaskService.Complete(id, GetRequiredUsername());
        }

        private string GetRequiredUsername()
        {
            var username =User.FindFirst(ClaimTypes.Name)?.Value;

            if (string.IsNullOrWhiteSpace(username))
            {
                throw new UserException("Prijavljeni korisnik nije pronađen.");
            }

            return username;
        }
    }
}
