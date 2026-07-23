using eAutoShop.Model.Exceptions;
using eAutoShop.Model.Model;
using eAutoShop.Model.Request;
using eAutoShop.Services.Database;
using eAutoShop.Services.Helpers;
using MapsterMapper;
using Microsoft.Extensions.DependencyInjection;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace eAutoShop.Services.StateMachineService.AppointmentStateMachine
{
    public class BaseAppointmentState
    {
        protected AutoShopContext _context;
        protected IMapper _mapper;
        protected IServiceProvider _serviceProvider;

        public BaseAppointmentState(AutoShopContext context,IMapper mapper,IServiceProvider serviceProvider)
        {
            _context = context;
            _mapper = mapper;
            _serviceProvider = serviceProvider;
        }

        public virtual Task<AppointmentModel> Insert(AppointmentInsertRequest request)
        {
            throw new UserException("Action not allowed.");
        }

        public virtual Task<AppointmentModel> Update(Appointment entity, AppointmentUpdateRequest request)
        {
            throw new UserException("Action not allowed.");
        }

        public virtual Task<AppointmentModel> Confirm(Appointment entity, DateTime? estimatedCompletionDate)
        {
            throw new UserException("Action not allowed.");
        }

        public virtual Task<AppointmentModel> Reject(Appointment entity, string reason)
        {
            throw new UserException("Action not allowed.");
        }

        public virtual Task<AppointmentModel> Cancel(Appointment entity, string reason)
        {
            throw new UserException("Action not allowed.");
        }

        public virtual Task<AppointmentModel> Start(Appointment entity)
        {
            throw new UserException("Action not allowed.");
        }

        public virtual Task<AppointmentModel> Complete(Appointment entity)
        {
            throw new UserException("Action not allowed.");
        }

        public virtual Task<AppointmentModel> UpdateEstimatedDate(Appointment entity, DateTime newEstimatedCompletion)
        {
            throw new UserException("Action not allowed.");
        }

        public virtual Task<AppointmentModel> SoftDelete(Appointment entity, string role)
        {
            throw new UserException("Action not allowed.");
        }

        public virtual Task<List<string>> AllowedActions()
        {
            return Task.FromResult(new List<string>());
        }

        public BaseAppointmentState CreateState(string? state)
        {
            return state switch
            {
                null or AppointmentStates.Initial => _serviceProvider.GetService<InitialAppointmentState>()!,
                AppointmentStates.Pending => _serviceProvider.GetService<PendingAppointmentState>()!,
                AppointmentStates.Confirmed => _serviceProvider.GetService<ConfirmedAppointmentState>()!,
                AppointmentStates.Ongoing => _serviceProvider.GetService<OngoingAppointmentState>()!,
                AppointmentStates.Rejected => _serviceProvider.GetService<RejectedAppointmentState>()!,
                AppointmentStates.Cancelled => _serviceProvider.GetService<CancelledAppointmentState>()!,
                AppointmentStates.Completed => _serviceProvider.GetService<CompletedAppointmentState>()!,
                _ => throw new UserException("Invalid appointment state."),
            };
        }
    }
}
