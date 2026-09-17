using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using eAutoShop.Model.Model;
using eAutoShop.Model.Request;
using eAutoShop.Model.SearchObjects;

namespace eAutoShop.Services.Interfaces
{
    public interface IEmployeeTaskService: IService<EmployeeTaskModel, EmployeeTaskSearchObject>
    {
        Task<EmployeeTaskModel> Insert(EmployeeTaskInsertRequest request, string creatorUsername);

        Task<PageResult<EmployeeTaskModel>> GetByEmployee(EmployeeTaskSearchObject? search, string employeeUsername);

        Task<EmployeeTaskModel> Complete(int id, string employeeUsername);
    }
}