using eAutoShop.Model.Exceptions;
using eAutoShop.Model.Model;
using eAutoShop.Model.Request;
using eAutoShop.Services.Database;
using eAutoShop.Services.Helpers;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace eAutoShop.Services.StateMachineService.AppointmentStateMachine
{
    public class PendingAppointmentState : BaseAppointmentState
    {
        public PendingAppointmentState(AutoShopContext context,IMapper mapper,IServiceProvider serviceProvider): base(context, mapper, serviceProvider)
        {
        }

        public override async Task<AppointmentModel> Update(
    Appointment entity,
    AppointmentUpdateRequest request)
        {
            if (request.ReservationDate.HasValue)
            {
                var newReservationDate = request.ReservationDate.Value;

                if (newReservationDate <= DateTime.UtcNow)
                {
                    throw new UserException(
                        "Reservation date must be in the future."
                    );
                }

                var shopIsAtCapacity = await IsShopAtCapacity(
                    newReservationDate,
                    entity.TotalDuration.ToTimeSpan(),
                    entity.Id
                );

                if (shopIsAtCapacity)
                {
                    throw new UserException(
                        "All technicians are busy during the selected time."
                    );
                }

                entity.ReservationDate = newReservationDate;
            }

            if (request.EstimatedCompletionDate.HasValue)
            {
                if (request.EstimatedCompletionDate.Value <=
                    entity.ReservationDate)
                {
                    throw new UserException(
                        "Estimated completion date must be after reservation date."
                    );
                }

                entity.EstimatedCompletionDate =
                    request.EstimatedCompletionDate.Value;
            }

            if (request.CompletionDate.HasValue)
            {
                throw new UserException(
                    "Completion date cannot be set while appointment is pending."
                );
            }

            await _context.SaveChangesAsync();

            return _mapper.Map<AppointmentModel>(entity);
        }

        public override async Task<AppointmentModel> Confirm(Appointment entity, AppointmentConfirmRequest request)
        {
            if (request.EstimatedCompletionDate.HasValue &&request.EstimatedCompletionDate.Value <= entity.ReservationDate)
            {
                throw new UserException("Estimated completion date must be after reservation date.");
            }

            var technician = await _context.Users .Include(x => x.Role).FirstOrDefaultAsync(x =>
                    x.Id == request.EmployeeId &&
                    x.Active &&
                    x.Role.Name == UserRoles.Technician
                );

            if (technician == null)
            {
                throw new UserException(
                    "Selected technician does not exist or is not active."
                );
            }

            var shopIsAtCapacity = await IsShopAtCapacity(
                entity.ReservationDate,
                entity.TotalDuration.ToTimeSpan(),
                entity.Id
            );

            if (shopIsAtCapacity)
            {
                throw new UserException(
                    "All technicians are busy during the selected time."
                );
            }

            var appointmentEndDate = entity.ReservationDate.Add(
                entity.TotalDuration.ToTimeSpan()
            );

            var earliestPossibleStart =
                entity.ReservationDate.AddDays(-1);

            var technicianAppointments =
                await _context.Appointments
                    .Where(x =>
                        x.Id != entity.Id &&
                        x.EmployeeId == technician.Id &&
                        (x.State == AppointmentStates.Confirmed ||
                         x.State == AppointmentStates.Ongoing) &&
                        x.ReservationDate >= earliestPossibleStart &&
                        x.ReservationDate < appointmentEndDate)
                    .ToListAsync();

            var technicianIsBusy = technicianAppointments.Any(x =>
            {
                var existingAppointmentEnd =
                    x.ReservationDate.Add(
                        x.TotalDuration.ToTimeSpan()
                    );

                return entity.ReservationDate <
                           existingAppointmentEnd &&
                       appointmentEndDate >
                           x.ReservationDate;
            });

            if (technicianIsBusy)
            {
                throw new UserException(
                    "Selected technician is busy during this time."
                );
            }

            entity.EmployeeId = technician.Id;
            entity.State = AppointmentStates.Confirmed;
            entity.EstimatedCompletionDate =
                request.EstimatedCompletionDate;

            await _context.SaveChangesAsync();

            return _mapper.Map<AppointmentModel>(entity);
        }

        public override async Task<AppointmentModel> Reject(Appointment entity, string reason)
        {
            if (string.IsNullOrWhiteSpace(reason))
                throw new UserException("Rejection reason is required.");

            entity.State = AppointmentStates.Rejected;
            entity.RejectionReason = reason;

            await _context.SaveChangesAsync();

            return _mapper.Map<AppointmentModel>(entity);
        }

        public override async Task<AppointmentModel> Cancel(Appointment entity, string reason)
        {
            if (string.IsNullOrWhiteSpace(reason))
                throw new UserException("Cancellation reason is required.");

            entity.State = AppointmentStates.Cancelled;
            entity.CancellationReason = reason;

            await _context.SaveChangesAsync();

            return _mapper.Map<AppointmentModel>(entity);
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

            list.Add("Confirm");
            list.Add("Update");
            list.Add("Reject");
            list.Add("Cancel");
            list.Add("SoftDelete");

            return list;
        }
    }
}
