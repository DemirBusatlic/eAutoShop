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
        public InitialAppointmentState(AutoShopContext context, IMapper mapper, IServiceProvider serviceProvider) : base(context, mapper, serviceProvider)
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


            var serviceIds = request.Services.Distinct().ToList();
            var services = await _context.AutoShopServices
                .Where(x => serviceIds.Contains(x.Id))
                .ToListAsync();

            if (services.Count != serviceIds.Count)
                throw new UserException("One or more selected services do not exist.");

            if (services.Any(x => x.State != AutoShopServiceStates.Active))
                throw new UserException("One or more selected services are not active.");

            var totalAmount = services.Sum(x => x.DiscountedPrice);
            var totalDuration = services.Aggregate(
                TimeSpan.Zero,
                (total, service) => total + service.Duration.ToTimeSpan());


            var shopIsAtCapacity = await IsShopAtCapacity(request.ReservationDate, totalDuration);

            if (shopIsAtCapacity)
            {
                throw new UserException("All technicians are busy during the selected time.");
            }

            var appointment = new Appointment
            {
                CustomerId = customer.Id,
                EmployeeId = null,
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

            await using var transaction = await _context.Database.BeginTransactionAsync();

            try
            {
                _context.Appointments.Add(appointment);
                await _context.SaveChangesAsync();

                foreach (var service in services)
                {
                    _context.AppointmentDetails.Add(new AppointmentDetail
                    {
                        AppointmentId = appointment.Id,
                        ServiceId = service.Id,
                        ServiceName = service.Name,
                        ServicePrice = service.Price,
                        ServiceDiscount = service.Discount,
                        ServiceDiscountedPrice = service.DiscountedPrice
                    });
                }

                await _context.SaveChangesAsync();
                await transaction.CommitAsync();
            }
            catch
            {
                await transaction.RollbackAsync();
                throw;
            }

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