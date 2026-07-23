using eAutoShop.Model.Exceptions;
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
    public class OngoingAppointmentState : BaseAppointmentState
    {
        public OngoingAppointmentState(AutoShopContext context,IMapper mapper,IServiceProvider serviceProvider): base(context, mapper, serviceProvider)
        {
        }

        public override async Task<AppointmentModel> Complete(Appointment entity)
        {
            entity.State = AppointmentStates.Completed;

            entity.CompletionDate = DateTime.UtcNow;

            await _context.SaveChangesAsync();

            return _mapper.Map<AppointmentModel>(entity);
        }

        public override async Task<AppointmentModel> UpdateEstimatedDate(Appointment entity,DateTime newEstimatedCompletion)
        {
            if (newEstimatedCompletion <= DateTime.UtcNow)
            {
                throw new UserException("Estimated completion date must be in the future.");
            }

            entity.EstimatedCompletionDate = newEstimatedCompletion;

            await _context.SaveChangesAsync();

            return _mapper.Map<AppointmentModel>(entity);
        }

        public override async Task<List<string>> AllowedActions()
        {
            var list = await base.AllowedActions();

            list.Add("UpdateEstimatedDate");
            list.Add("Complete");

            return list;
        }
    }
}
