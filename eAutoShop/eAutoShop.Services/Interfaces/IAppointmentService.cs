using eAutoShop.Model.Model;
using eAutoShop.Model.Request;
using eAutoShop.Model.SearchObjects;

namespace eAutoShop.Services.Interfaces
{
    public interface IAppointmentService :IBaseCRUDService<AppointmentModel,AppointmentSearchObject,AppointmentInsertRequest,AppointmentUpdateRequest>
    {
        Task<PageResult<AppointmentModel>> GetByCustomer(AppointmentSearchObject? search,string customerUsername);

        Task<PageResult<AppointmentModel>> GetByEmployee(AppointmentSearchObject? search, string employeeUsername);

        Task<AppointmentModel> UpdateForCustomer(int id, AppointmentUpdateRequest request, string customerUsername);

        Task<AppointmentModel> Confirm(int id, AppointmentConfirmRequest request);

        Task<AppointmentModel> Reject(int id,string reason);

        Task<AppointmentModel> CancelForCustomer(int id,string reason,string customerUsername);

        Task<AppointmentModel> StartForEmployee(int id,string employeeUsername);

        Task<AppointmentModel> UpdateEstimatedDateForEmployee(int id,DateTime newEstimatedCompletion, string employeeUsername);

        Task<AppointmentModel> CompleteForEmployee(int id,string employeeUsername);

        Task<List<string>> AllowedActionsForUser(int id,string role,string username);

        Task<AppointmentModel> SoftDeleteForUser(int id,string role,string username);
    }
}
