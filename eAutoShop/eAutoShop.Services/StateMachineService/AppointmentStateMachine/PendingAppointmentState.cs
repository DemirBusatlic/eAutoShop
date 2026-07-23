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

        public override async Task<AppointmentModel> Update(Appointment entity,AppointmentUpdateRequest request)
        {
            if (request.ReservationDate.HasValue)
            {
                if (request.ReservationDate.Value <= DateTime.UtcNow)
                {
                    throw new UserException("Reservation date must be in the future.");
                }

                var newReservationDate = request.ReservationDate.Value;
                var newEndDate = newReservationDate.Add(entity.TotalDuration.ToTimeSpan());

                var hasConflict = await _context.Appointments.AnyAsync(x =>
                    x.Id != entity.Id &&
                    x.State != AppointmentStates.Cancelled &&
                    x.State != AppointmentStates.Rejected &&
                    newReservationDate < x.ReservationDate.Add(x.TotalDuration.ToTimeSpan()) && newEndDate > x.ReservationDate);

                if (hasConflict)
                {
                    throw new UserException("Selected appointment time is already taken.");
                }

                entity.ReservationDate = newReservationDate;
            }

            if (request.EstimatedCompletionDate.HasValue)
            {
                if (request.EstimatedCompletionDate.Value <= entity.ReservationDate)
                {
                    throw new UserException("Estimated completion date must be after reservation date.");
                }

                entity.EstimatedCompletionDate = request.EstimatedCompletionDate.Value;
            }

            if (request.CompletionDate.HasValue)
            {
                throw new UserException("Completion date cannot be set while appointment is pending.");
            }

            await _context.SaveChangesAsync();

            return _mapper.Map<AppointmentModel>(entity);
        }

        public override async Task<AppointmentModel> Confirm(Appointment entity,DateTime? estimatedCompletionDate)
        {
            if (estimatedCompletionDate.HasValue && estimatedCompletionDate.Value <= entity.ReservationDate)
            {
                throw new UserException("Estimated completion date must be after reservation date.");
            }

            var appointmentEndDate = entity.ReservationDate.Add(entity.TotalDuration.ToTimeSpan());

            var hasConflict = await _context.Appointments.AnyAsync(x =>
                x.Id != entity.Id &&
                x.State != AppointmentStates.Cancelled &&
                x.State != AppointmentStates.Rejected &&
                entity.ReservationDate < x.ReservationDate.Add(x.TotalDuration.ToTimeSpan()) && appointmentEndDate > x.ReservationDate);

            if (hasConflict)
            {
                throw new UserException("Selected appointment time is already taken.");
            }

            entity.State = AppointmentStates.Confirmed;
            entity.EstimatedCompletionDate = estimatedCompletionDate;

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
