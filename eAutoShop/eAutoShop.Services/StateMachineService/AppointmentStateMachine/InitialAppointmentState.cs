using eAutoShop.Model.Exceptions;
using eAutoShop.Model.Model;
using eAutoShop.Model.Request;
using eAutoShop.Services.Database;
using eAutoShop.Services.Helpers;
using MapsterMapper;
using Microsoft.AspNetCore.Http;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Security.Claims;
using System.Text;
using System.Threading.Tasks;

namespace eAutoShop.Services.StateMachineService.AppointmentStateMachine
{
    public class InitialAppointmentState : BaseAppointmentState
    {
        public InitialAppointmentState(AutoShopContext context,IMapper mapper,IServiceProvider serviceProvider): base(context, mapper, serviceProvider)
        {
        }

        public override async Task<AppointmentModel> Insert(AppointmentInsertRequest request)
        {
            var userIdClaim = _serviceProvider.GetRequiredService<IHttpContextAccessor>().HttpContext?.User?.FindFirst(ClaimTypes.NameIdentifier)?.Value;

            if (!int.TryParse(userIdClaim, out var userId))
            {
                throw new UserException("User not found.");
            }

            var customer = await _context.Users
                .FirstOrDefaultAsync(x => x.Id == userId);

            if (customer == null)
            {
                throw new UserException("User not found.");
            }

            var carModel = await _context.CarModels.FirstOrDefaultAsync(x => x.Id == request.CarModelId);

            if (carModel == null)
                throw new UserException("Car model not found.");

            if (request.ReservationDate <= DateTime.UtcNow)
                throw new UserException("Reservation date must be in the future.");

            if (request.Services == null || !request.Services.Any())
                throw new UserException("Please select at least one service.");

            if (request.OrderId != null)
            {
                var order = await _context.Orders.FirstOrDefaultAsync(x => x.Id == request.OrderId);

                if (order == null)
                    throw new UserException($"Order #{request.OrderId} does not exist.");

                if (order.CustomerId != customer.Id)
                    throw new UserException($"Order #{request.OrderId} is not made by you.");

                var alreadyUsed = await _context.Appointments.AnyAsync(x =>x.OrderId == order.Id &&x.State != AppointmentStates.Rejected &&x.State != AppointmentStates.Cancelled);

                if (alreadyUsed)
                    throw new UserException($"This order is already used for another appointment.");
            }

            double totalAmount = 0;
            TimeSpan totalDuration = TimeSpan.Zero;

            foreach (var serviceId in request.Services)
            {
                var service = await _context.AutoShopServices.FirstOrDefaultAsync(x => x.Id == serviceId);

                if (service == null)
                    throw new UserException($"Service #{serviceId} not found.");

                if (service.State != "active")
                    throw new UserException($"Service #{serviceId} is not active.");

                totalAmount += service.DiscountedPrice;
                totalDuration += service.Duration.ToTimeSpan();
            }

            var reservationEndDate = request.ReservationDate.Add(totalDuration);


            var shopIsAtCapacity = await IsShopAtCapacity(request.ReservationDate,totalDuration);

            if (shopIsAtCapacity)
            {
                throw new UserException("All technicians are busy during the selected time.");
            }

            var appointment = new Appointment
            {
                CustomerId = customer.Id,
                EmployeeId = null,
                OrderId = request.OrderId,
                CarModelId = request.CarModelId,
                ReservationCreatedDate = DateTime.UtcNow,
                ReservationDate = request.ReservationDate,
                TotalAmount = totalAmount,
                TotalDuration = TimeOnly.FromTimeSpan(totalDuration),
                State = AppointmentStates.Pending,
                Type = "Service",
                DeletedByCustomer = false,
                DeletedByShop = false
            };

            _context.Appointments.Add(appointment);
            await _context.SaveChangesAsync();

            foreach (var serviceId in request.Services)
            {
                var service = await _context.AutoShopServices
                    .FirstOrDefaultAsync(x => x.Id == serviceId);

                if (service == null)
                    throw new UserException($"Service #{serviceId} not found.");

                var detail = new AppointmentDetail
                {
                    AppointmentId = appointment.Id,
                    ServiceId = service.Id,
                    ServiceName = service.Name,
                    ServicePrice = service.Price,
                    ServiceDiscount = service.Discount,
                    ServiceDiscountedPrice = service.DiscountedPrice
                };

                _context.AppointmentDetails.Add(detail);
            }

            await _context.SaveChangesAsync();

            return _mapper.Map<AppointmentModel>(appointment);
        }

        public override async Task<List<string>> AllowedActions()
        {
            var list = await base.AllowedActions();

            list.Add("Insert");

            return list;
        }
    }
}
