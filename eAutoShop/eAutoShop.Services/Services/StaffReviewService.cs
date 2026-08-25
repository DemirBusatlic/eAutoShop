using eAutoShop.Model.Model;
using eAutoShop.Model.Request;
using eAutoShop.Model.SearchObjects;
using eAutoShop.Model.Exceptions;
using eAutoShop.Services.Database;
using eAutoShop.Services.Interfaces;
using MapsterMapper;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;

namespace eAutoShop.Services.Services
{
    public class StaffReviewService : BaseCRUDService<StaffReviewModel,StaffReview,StaffReviewSearchObject,StaffReviewInsertRequest,StaffReviewUpdateRequest>,IStaffReviewService
    {
        public StaffReviewService(AutoShopContext context, IMapper mapper) : base(context, mapper)
        {
        }

        public override IQueryable<StaffReview> AddInclude(IQueryable<StaffReview> query,StaffReviewSearchObject? search = null)
        {
            query = query .Include(x => x.User).Include(x => x.Employee);

            return base.AddInclude(query, search);
        }
        public override IQueryable<StaffReview> AddFilter(IQueryable<StaffReview> query,StaffReviewSearchObject? search = null)
        {
            if (search?.Rating != null)
            {
                query = query.Where(x => x.Rating == search.Rating);
            }

            if (search?.UserId != null)
            {
                query = query.Where(x => x.UserId == search.UserId);
            }

            if (search?.EmployeeId != null)
            {
                query = query.Where(x => x.EmployeeId == search.EmployeeId);
            }

            if (!string.IsNullOrWhiteSpace(search?.CommentFTS))
            {
                query = query.Where(x => x.Comment != null && x.Comment.Contains(search.CommentFTS));
            }

            return base.AddFilter(query, search);
        }

        public override async Task BeforeInsert(StaffReview db,StaffReviewInsertRequest insert)
        {
            if (insert.UserId == null)
            {
                throw new UserException("Prijavljeni korisnik nije pronađen.");
            }

            var appointment = await _context.Appointments.AsNoTracking().FirstOrDefaultAsync(x => x.Id == insert.AppointmentId);

            if (appointment == null)
            {
                throw new UserException("Rezervacija nije pronađena.");
            }

            if (appointment.CustomerId != insert.UserId.Value)
            {
                throw new UserException("Ne možete ocijeniti zaposlenika iz tuđe rezervacije.");
            }

            if (!string.Equals(appointment.State,"completed", StringComparison.OrdinalIgnoreCase))
            {
                throw new UserException("Zaposlenika možete ocijeniti tek nakon završene rezervacije.");
            }

            if (appointment.EmployeeId == null)
            {
                throw new UserException("Rezervaciji nije dodijeljen zaposlenik.");
            }

            var reviewAlreadyExists = await _context.StaffReviews.AnyAsync(x => x.AppointmentId == appointment.Id);

            if (reviewAlreadyExists)
            {
                throw new UserException("Ova rezervacija je već ocijenjena.");
            }

            db.UserId = insert.UserId.Value;
            db.EmployeeId = appointment.EmployeeId.Value;
            db.AppointmentId = appointment.Id;
            db.CreatedAt = DateTime.Now;

            await base.BeforeInsert(db, insert);
        }
    }
}
