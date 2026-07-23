using eAutoShop.Model.Model;
using eAutoShop.Services.Database;
using eAutoShop.Services.Helpers;
using MapsterMapper;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace eAutoShop.Services.StateMachineService.AppointmentStateMachine
{
    public class CompletedAppointmentState : BaseAppointmentState
    {
        public CompletedAppointmentState(AutoShopContext context,IMapper mapper,IServiceProvider serviceProvider): base(context, mapper, serviceProvider)
        {
        }

        public override async Task<AppointmentModel> SoftDelete(Appointment entity,string role)
        {
            if (role == UserRoles.Customer)
            {
                entity.DeletedByCustomer = true;
            }
            else
            {
                entity.DeletedByShop = true;
            }

            await _context.SaveChangesAsync();

            return _mapper.Map<AppointmentModel>(entity);
        }

        public override async Task<List<string>> AllowedActions()
        {
            var list = await base.AllowedActions();

            list.Add("SoftDelete");

            return list;
        }
    }
}
