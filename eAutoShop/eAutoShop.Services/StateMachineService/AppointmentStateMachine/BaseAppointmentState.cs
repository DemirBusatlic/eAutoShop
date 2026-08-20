using eAutoShop.Model.Exceptions;
using eAutoShop.Model.Model;
using eAutoShop.Model.Request;
using eAutoShop.Services.Database;
using eAutoShop.Services.Helpers;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
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

        public virtual Task<AppointmentModel> Confirm(Appointment entity, AppointmentConfirmRequest request)
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
        protected async Task<bool> IsShopAtCapacity(DateTime reservationStart,TimeSpan duration,int? excludedAppointmentId = null)
        {
            var technicianCount = await _context.Users.CountAsync(x =>
                x.Active &&
                x.Role.Name == UserRoles.Technician
            );

            // Ako nema aktivnih tehničara, nema ni slobodnog termina.
            if (technicianCount == 0)
            {
                return true;
            }

            var reservationEnd = reservationStart.Add(duration);

            // TotalDuration je TimeOnly i ne može predstavljati 24h ili više.
            var earliestPossibleStart = reservationStart.AddDays(-1);

            var appointments = await _context.Appointments
                .Where(x =>
                    (!excludedAppointmentId.HasValue ||
                     x.Id != excludedAppointmentId.Value) &&
                    (x.State == AppointmentStates.Pending ||
                     x.State == AppointmentStates.Confirmed ||
                     x.State == AppointmentStates.Ongoing) &&
                    x.ReservationDate >= earliestPossibleStart &&
                    x.ReservationDate < reservationEnd)
                .ToListAsync();

            var numberOfOverlappingAppointments = appointments.Count(x =>
            {
                var existingAppointmentEnd = x.ReservationDate.Add(
                    x.TotalDuration.ToTimeSpan()
                );

                return reservationStart < existingAppointmentEnd &&
                       reservationEnd > x.ReservationDate;
            });

            return numberOfOverlappingAppointments >= technicianCount;
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
