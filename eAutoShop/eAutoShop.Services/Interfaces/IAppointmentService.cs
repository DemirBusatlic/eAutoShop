using eAutoShop.Model.Model;
using eAutoShop.Model.Request;
using eAutoShop.Model.SearchObjects;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace eAutoShop.Services.Interfaces
{
    public interface IAppointmentService: IBaseCRUDService<AppointmentModel, AppointmentSearchObject, AppointmentInsertRequest, AppointmentUpdateRequest>
    {
        Task<AppointmentModel> Confirm(int id,AppointmentConfirmRequest request);
        Task<AppointmentModel> Reject(int id, string reason);
        Task<AppointmentModel> Cancel(int id, string reason);
        Task<AppointmentModel> Start(int id);
        Task<AppointmentModel> UpdateEstimatedDate(int id, DateTime newEstimatedCompletion);
        Task<AppointmentModel> Complete(int id);
        Task<List<string>> AllowedActions(int id);
        Task<AppointmentModel> SoftDelete(int id, string role);
    }
}
