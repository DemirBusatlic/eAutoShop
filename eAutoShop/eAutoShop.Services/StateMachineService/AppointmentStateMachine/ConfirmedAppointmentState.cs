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
    public class ConfirmedAppointmentState : BaseAppointmentState
    {
        public ConfirmedAppointmentState(AutoShopContext context, IMapper mapper, IServiceProvider serviceProvider) : base(context, mapper, serviceProvider)
        {
        }

        public override async Task<AppointmentModel> Start(Appointment entity)
        {
            entity.State = AppointmentStates.Ongoing;

            await _context.SaveChangesAsync();

            return _mapper.Map<AppointmentModel>(entity);
        }

        public override async Task<List<string>> AllowedActions()
        {
            var list = await base.AllowedActions();

            list.Add("Start");

            return list;
        }
    }
}
