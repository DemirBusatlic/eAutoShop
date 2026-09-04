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

namespace eAutoShop.Services.Services
{
    public class AppointmentService : BaseCRUDService<AppointmentModel, Appointment, AppointmentSearchObject, AppointmentInsertRequest, AppointmentUpdateRequest>, IAppointmentService
    {
        private const int DefaultPage = 1;
        private const int DefaultPageSize = 10;
        private const int MaxPageSize = 100;

        private readonly BaseAppointmentState _baseAppointmentState;

        public AppointmentService(AutoShopContext context, IMapper mapper, BaseAppointmentState baseAppointmentState) : base(context, mapper)
        {
            _baseAppointmentState = baseAppointmentState;
        }

        public override IQueryable<Appointment> AddInclude(IQueryable<Appointment> query, AppointmentSearchObject? search = null)
        {
            query = query.Include(x => x.Customer)
                .Include(x => x.Employee)
                .Include(x => x.CarModel)
                .ThenInclude(x => x.CarManufacturer)
                .Include(x => x.Order)
                .Include(x => x.StaffReview);

            return base.AddInclude(query, search);
        }

        public override IQueryable<Appointment> AddFilter(IQueryable<Appointment> query, AppointmentSearchObject? search = null)
        {
            query = query.OrderByDescending(x => x.Id);

            if (search == null)
                return base.AddFilter(query, search);

            if (!string.IsNullOrWhiteSpace(search.CustomerUsername))
            {
                query = query.Where(x => x.Customer.Username.Contains(search.CustomerUsername) && !x.DeletedByCustomer);
            }

            if (!string.IsNullOrWhiteSpace(search.EmployeeUsername))
            {
                query = query.Where(x =>
                    x.Employee != null &&
                    x.Employee.Username.Contains(search.EmployeeUsername) &&
                    !x.DeletedByShop);
            }

            if (!string.IsNullOrWhiteSpace(search.State))
                query = query.Where(x => x.State == search.State);

            if (!string.IsNullOrWhiteSpace(search.Type))
                query = query.Where(x => x.Type.Contains(search.Type));

            if (search.HasOrder.HasValue)
            {
                query = search.HasOrder.Value
                    ? query.Where(x => x.OrderId != null)
                    : query.Where(x => x.OrderId == null);
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

        public async Task<PageResult<AppointmentModel>> GetByCustomer(AppointmentSearchObject? search, string customerUsername)
        {
            ValidateUsername(customerUsername);
            return await GetForUser(search, customerUsername, isEmployee: false);
        }

        public async Task<PageResult<AppointmentModel>> GetByEmployee(AppointmentSearchObject? search, string employeeUsername)
        {
            ValidateUsername(employeeUsername);
            return await GetForUser(search, employeeUsername, isEmployee: true);
        }

        public override async Task<AppointmentModel> Insert(AppointmentInsertRequest request)
        {
            var state = _baseAppointmentState.CreateState(AppointmentStates.Initial);
            return await state.Insert(request);
        }

        public override async Task<AppointmentModel> Update(int id, AppointmentUpdateRequest request)
        {
            var entity = await GetAppointment(id);
            var state = _baseAppointmentState.CreateState(entity.State);
            return await state.Update(entity, request);
        }

        public async Task<AppointmentModel> UpdateForCustomer(int id, AppointmentUpdateRequest request, string customerUsername)
        {
            var entity = await GetAppointment(id);
            EnsureCustomerOwnsAppointment(entity, customerUsername);

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

        public async Task<AppointmentModel> CancelForCustomer(int id, string reason, string customerUsername)
        {
            var entity = await GetAppointment(id);
            EnsureCustomerOwnsAppointment(entity, customerUsername);

            var state = _baseAppointmentState.CreateState(entity.State);
            return await state.Cancel(entity, reason);
        }

        public async Task<AppointmentModel> StartForEmployee(int id, string employeeUsername)
        {
            var entity = await GetAppointment(id);
            EnsureAssignedToEmployee(entity, employeeUsername);

            var state = _baseAppointmentState.CreateState(entity.State);
            return await state.Start(entity);
        }

        public async Task<AppointmentModel> UpdateEstimatedDateForEmployee(int id, DateTime newEstimatedCompletion, string employeeUsername)
        {
            var entity = await GetAppointment(id);
            EnsureAssignedToEmployee(entity, employeeUsername);

            var state = _baseAppointmentState.CreateState(entity.State);
            return await state.UpdateEstimatedDate(entity, newEstimatedCompletion);
        }

        public async Task<AppointmentModel> CompleteForEmployee(int id, string employeeUsername)
        {
            var entity = await GetAppointment(id);
            EnsureAssignedToEmployee(entity, employeeUsername);

            var state = _baseAppointmentState.CreateState(entity.State);
            return await state.Complete(entity);
        }

        public async Task<AppointmentModel> SoftDeleteForUser(int id, string role, string username)
        {
            var entity = await GetAppointment(id);

            if (role == UserRoles.Customer)
            {
                EnsureCustomerOwnsAppointment(entity, username);
            }
            else if (role != UserRoles.Manager)
            {
                throw new UserException("You are not allowed to remove this appointment.");
            }

            var state = _baseAppointmentState.CreateState(entity.State);
            return await state.SoftDelete(entity, role);
        }

        public async Task<List<string>> AllowedActionsForUser(int id, string role, string username)
        {
            var entity = await GetAppointment(id);
            HashSet<string> actionsAllowedForRole;

            if (role == UserRoles.Manager)
            {
                actionsAllowedForRole = new HashSet<string>
                {
                    "Confirm",
                    "Reject",
                    "SoftDelete"
                };
            }
            else if (role == UserRoles.Technician)
            {
                EnsureAssignedToEmployee(entity, username);
                actionsAllowedForRole = new HashSet<string>
                {
                    "Start",
                    "UpdateEstimatedDate",
                    "Complete"
                };
            }
            else if (role == UserRoles.Customer)
            {
                EnsureCustomerOwnsAppointment(entity, username);
                actionsAllowedForRole = new HashSet<string>
                {
                    "Update",
                    "Cancel",
                    "SoftDelete"
                };
            }
            else
            {
                throw new UserException("You are not allowed to access this appointment.");
            }

            var state = _baseAppointmentState.CreateState(entity.State);
            var stateActions = await state.AllowedActions();

            return stateActions
                .Where(actionsAllowedForRole.Contains)
                .ToList();
        }

        private async Task<PageResult<AppointmentModel>> GetForUser(AppointmentSearchObject? search, string username, bool isEmployee)
        {
            search ??= new AppointmentSearchObject();

            search.CustomerUsername = null;
            search.EmployeeUsername = null;

            var query = _context.Appointments.AsQueryable();
            query = AddFilter(query, search);
            query = AddInclude(query, search);

            query = isEmployee ? query.Where(x => x.Employee != null && x.Employee.Username == username && !x.DeletedByShop) : query.Where(x => x.Customer.Username == username & !x.DeletedByCustomer);

            var count = await query.CountAsync();
            var page = Math.Max(search.Page ?? DefaultPage, DefaultPage);
            var pageSize = search.PageSize ?? DefaultPageSize;

            if (pageSize < 1)
                pageSize = DefaultPageSize;
            else if (pageSize > MaxPageSize)
                pageSize = MaxPageSize;

            var entities = await query
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync();

            return new PageResult<AppointmentModel>
            {
                Count = count,
                Result = _mapper.Map<List<AppointmentModel>>(entities)
            };
        }

        private async Task<Appointment> GetAppointment(int id)
        {
            var entity = await _context.Appointments
                .Include(x => x.Customer)
                .Include(x => x.Employee)
                .Include(x => x.CarModel)
                .FirstOrDefaultAsync(x => x.Id == id);

            if (entity == null)
                throw new UserException("Appointment doesn't exist.");

            return entity;
        }

        private static void EnsureCustomerOwnsAppointment(Appointment appointment, string customerUsername)
        {
            ValidateUsername(customerUsername);

            if (!string.Equals(appointment.Customer.Username, customerUsername, StringComparison.OrdinalIgnoreCase))
            {
                throw new UserException("Appointment does not belong to the signed-in customer.");
            }
        }

        private static void EnsureAssignedToEmployee(Appointment appointment, string employeeUsername)
        {
            ValidateUsername(employeeUsername);

            if (appointment.Employee == null ||
                !string.Equals(appointment.Employee.Username, employeeUsername, StringComparison.OrdinalIgnoreCase))
            {
                throw new UserException("Appointment is not assigned to the signed-in employee.");
            }
        }

        private static void ValidateUsername(string username)
        {
            if (string.IsNullOrWhiteSpace(username))
                throw new UserException("Signed-in user was not found.");
        }
    }
}
