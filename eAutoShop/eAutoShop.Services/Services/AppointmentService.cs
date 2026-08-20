using eAutoShop.Model.Exceptions;
using eAutoShop.Model.Model;
using eAutoShop.Model.Request;
using eAutoShop.Model.SearchObjects;
using eAutoShop.Services.Database;
using eAutoShop.Services.Helpers;
using eAutoShop.Services.Interfaces;
using eAutoShop.Services.StateMachineService.AppointmentStateMachine;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace eAutoShop.Services.Services
{
    public class AppointmentService: BaseCRUDService<AppointmentModel, Appointment, AppointmentSearchObject, AppointmentInsertRequest, AppointmentUpdateRequest>, IAppointmentService
    {
        private readonly BaseAppointmentState _baseAppointmentState;

        public AppointmentService(AutoShopContext context,IMapper mapper,BaseAppointmentState baseAppointmentState): base(context, mapper)
        {
            _baseAppointmentState = baseAppointmentState;
        }

        public override IQueryable<Appointment> AddInclude(IQueryable<Appointment> query,AppointmentSearchObject? search = null)
        {
            query = query.Include(x => x.Customer);
            query = query.Include(x => x.Employee);
            query = query.Include(x => x.CarModel).ThenInclude(x => x.CarManufacturer);
            query = query.Include(x => x.Order);

            return base.AddInclude(query, search);
        }

        public override IQueryable<Appointment> AddFilter(IQueryable<Appointment> query,AppointmentSearchObject? search = null)
        {
            query = query.OrderByDescending(x => x.Id);

            if (search == null)
                return base.AddFilter(query, search);

            if (!string.IsNullOrWhiteSpace(search.CustomerUsername))
            {
                query = query.Where(x =>x.Customer.Username.Contains(search.CustomerUsername) && !x.DeletedByCustomer);
            }

            if (!string.IsNullOrWhiteSpace(search.EmployeeUsername))
            {
                query = query.Where(x =>x.Employee != null && x.Employee.Username.Contains(search.EmployeeUsername) && !x.DeletedByShop);
            }

            if (!string.IsNullOrWhiteSpace(search.State))
                query = query.Where(x => x.State == search.State);

            if (!string.IsNullOrWhiteSpace(search.Type))
                query = query.Where(x => x.Type.Contains(search.Type));

            if (search.HasOrder.HasValue)
            {
                query = search.HasOrder.Value ? query.Where(x => x.OrderId != null) : query.Where(x => x.OrderId == null);
            }

            if (search.MinTotalAmount.HasValue)
                query = query.Where(x => x.TotalAmount >= search.MinTotalAmount.Value);

            if (search.MaxTotalAmount.HasValue)
                query = query.Where(x => x.TotalAmount <= search.MaxTotalAmount.Value);

            if (search.MinReservationDate.HasValue)
                query = query.Where(x => x.ReservationDate >= search.MinReservationDate.Value);

            if (search.MaxReservationDate.HasValue)
                query = query.Where(x => x.ReservationDate <= search.MaxReservationDate.Value);

            if (search.MinCreatedDate.HasValue)
                query = query.Where(x => x.ReservationCreatedDate >= search.MinCreatedDate.Value);

            if (search.MaxCreatedDate.HasValue)
                query = query.Where(x => x.ReservationCreatedDate <= search.MaxCreatedDate.Value);

            if (search.MinCompletionDate.HasValue)
                query = query.Where(x => x.CompletionDate >= search.MinCompletionDate.Value);

            if (search.MaxCompletionDate.HasValue)
                query = query.Where(x => x.CompletionDate <= search.MaxCompletionDate.Value);

            return base.AddFilter(query, search);
        }

        public override async Task<AppointmentModel> Insert(AppointmentInsertRequest request)
        {
            var state = _baseAppointmentState.CreateState(AppointmentStates.Initial);

            return await state.Insert(request);
        }

        public override async Task<AppointmentModel> Update(int id, AppointmentUpdateRequest request)
        {
            var entity = await GetAppointment(id);

            if (entity == null)
                throw new UserException("Appointment doesn't exist.");

            var state = _baseAppointmentState.CreateState(entity.State);

            return await state.Update(entity, request);
        }

        public async Task<AppointmentModel> Confirm(int id, AppointmentConfirmRequest request)
        {
            var entity = await GetAppointment(id);

            var state = _baseAppointmentState.CreateState(entity.State);

            return await state.Confirm(entity, request);
        }

        public async Task<AppointmentModel> Reject(int id, string reason)
        {
            var entity = await GetAppointment(id);

            var state = _baseAppointmentState.CreateState(entity.State);

            return await state.Reject(entity, reason);
        }

        public async Task<AppointmentModel> Cancel(int id, string reason)
        {
            var entity = await GetAppointment(id);

            var state = _baseAppointmentState.CreateState(entity.State);

            return await state.Cancel(entity, reason);
        }

        public async Task<AppointmentModel> Start(int id)
        {
            var entity = await GetAppointment(id);

            var state = _baseAppointmentState.CreateState(entity.State);

            return await state.Start(entity);
        }

        public async Task<AppointmentModel> UpdateEstimatedDate(int id, DateTime newEstimatedCompletion)
        {
            var entity = await GetAppointment(id);

            var state = _baseAppointmentState.CreateState(entity.State);

            return await state.UpdateEstimatedDate(entity, newEstimatedCompletion);
        }

        public async Task<AppointmentModel> Complete(int id)
        {
            var entity = await GetAppointment(id);

            var state = _baseAppointmentState.CreateState(entity.State);

            return await state.Complete(entity);
        }

        public async Task<AppointmentModel> SoftDelete(int id, string role)
        {
            var entity = await GetAppointment(id);

            var state = _baseAppointmentState.CreateState(entity.State);

            return await state.SoftDelete(entity, role);
        }

        public async Task<List<string>> AllowedActions(int id)
        {
            var entity = await _context.Appointments.FindAsync(id);

            var state = _baseAppointmentState.CreateState(entity?.State ?? AppointmentStates.Initial);

            return await state.AllowedActions();
        }

        private async Task<Appointment> GetAppointment(int id)
        {
            var entity = await _context.Appointments
                .Include(x => x.Customer)
                .Include(x => x.Employee)
                .Include(x => x.CarModel)
                .FirstOrDefaultAsync(x => x.Id == id);

            if (entity == null)
            {
                throw new UserException("Appointment doesn't exist.");
            }

            return entity;
        }
    }
}
