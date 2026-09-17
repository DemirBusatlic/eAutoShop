using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using eAutoShop.Model.Exceptions;
using eAutoShop.Model.Model;
using eAutoShop.Model.Request;
using eAutoShop.Model.SearchObjects;
using eAutoShop.Services.Database;
using eAutoShop.Services.Helpers;
using eAutoShop.Services.Interfaces;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;

namespace eAutoShop.Services.Services
{
    public class EmployeeTaskService: BaseService<EmployeeTaskModel, EmployeeTask, EmployeeTaskSearchObject>,IEmployeeTaskService
    {
        public EmployeeTaskService(AutoShopContext context,IMapper mapper): base(context, mapper)
        {
        }

        public override IQueryable<EmployeeTask> AddInclude(IQueryable<EmployeeTask> query, EmployeeTaskSearchObject? search = null)
        {
            return query.Include(x => x.Employee)
                .Include(x => x.CreatedBy);
        }

        public override IQueryable<EmployeeTask> AddFilter(IQueryable<EmployeeTask> query, EmployeeTaskSearchObject? search = null)
        {
            if (!string.IsNullOrWhiteSpace(search?.TitleFTS))
            {
                query = query.Where(x =>x.Title.Contains(search.TitleFTS));
            }

            if (search?.EmployeeId != null)
            {
                query = query.Where(x => x.EmployeeId == search.EmployeeId);
            }

            if (search?.CreatedById != null)
            {
                query = query.Where(x => x.CreatedById == search.CreatedById);
            }

            if (!string.IsNullOrWhiteSpace(search?.State))
            {
                query = query.Where(x => x.State == search.State);
            }

            if (search?.MinDueDate != null)
            {
                query = query.Where(x => x.DueDate >= search.MinDueDate);
            }

            if (search?.MaxDueDate != null)
            {
                query = query.Where(x => x.DueDate <= search.MaxDueDate);
            }

            return query.OrderByDescending(x => x.CreatedAt);
        }

        public async Task<EmployeeTaskModel> Insert(EmployeeTaskInsertRequest request, string creatorUsername)
        {
            var creator = await _context.Users.Include(x => x.Role).FirstOrDefaultAsync(x => x.Username == creatorUsername &&x.Active);

            if (creator == null || creator.Role.Name != UserRoles.Manager)
            {
                throw new UserException("Samo aktivni menadžer može kreirati zaduženje.");
            }

            var employee = await _context.Users.Include(x => x.Role).FirstOrDefaultAsync(x =>x.Id == request.EmployeeId && x.Active);

            if (employee == null)
            {
                throw new UserException("Odabrani radnik nije pronađen ili nije aktivan.");
            }

            if (employee.Role.Name != UserRoles.Salesperson && employee.Role.Name != UserRoles.Technician)
            {
                throw new UserException("Zaduženje se može dodijeliti samo prodavaču ili tehničaru.");
            }

            if (request.DueDate.HasValue && request.DueDate.Value <= DateTime.UtcNow)
            {
                throw new UserException("Rok izvršenja mora biti u budućnosti.");
            }

            var entity = new EmployeeTask
            {
                Title = request.Title.Trim(),
                Description = request.Description.Trim(),
                EmployeeId = employee.Id,
                CreatedById = creator.Id,
                CreatedAt = DateTime.UtcNow,
                DueDate = request.DueDate,
                State = "active",
                Employee = employee,
                CreatedBy = creator
            };

            _context.EmployeeTasks.Add(entity);
            await _context.SaveChangesAsync();

            return _mapper.Map<EmployeeTaskModel>(entity);
        }

        public async Task<PageResult<EmployeeTaskModel>> GetByEmployee(EmployeeTaskSearchObject? search,string employeeUsername)
        {
            var employee = await _context.Users.AsNoTracking().FirstOrDefaultAsync(x =>x.Username == employeeUsername && x.Active);

            if (employee == null)
            {
                throw new UserException( "Prijavljeni radnik nije pronađen.");
            }

            search ??= new EmployeeTaskSearchObject();
            search.EmployeeId = employee.Id;

            return await Get(search);
        }

        public async Task<EmployeeTaskModel> Complete(int id, string employeeUsername)
        {
            var entity = await _context.EmployeeTasks.Include(x => x.Employee).Include(x => x.CreatedBy).FirstOrDefaultAsync(x => x.Id == id);

            if (entity == null)
            {
                throw new UserException("Zaduženje nije pronađeno.");
            }

            if (entity.Employee.Username != employeeUsername)
            {
                throw new UserException("Ne možete završiti tuđe zaduženje.");
            }

            if (entity.State == "completed")
            {
                throw new UserException("Zaduženje je već završeno.");
            }

            entity.State = "completed";
            entity.CompletedAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();

            return _mapper.Map<EmployeeTaskModel>(entity);
        }
    }
}
