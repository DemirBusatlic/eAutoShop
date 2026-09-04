using eAutoShop.Model.Exceptions;
using eAutoShop.Model.Model;
using eAutoShop.Model.Request;
using eAutoShop.Model.SearchObjects;
using eAutoShop.Services.Database;
using eAutoShop.Services.Helpers;
using eAutoShop.Services.Interfaces;
using MapsterMapper;
using Microsoft.AspNetCore.Http;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;

namespace eAutoShop.Services.Services
{
    public class StaffReviewService : BaseCRUDService<StaffReviewModel, StaffReview, StaffReviewSearchObject, StaffReviewInsertRequest, StaffReviewUpdateRequest>, IStaffReviewService
    {
        private readonly IHttpContextAccessor _httpContextAccessor;

        public StaffReviewService(AutoShopContext context, IMapper mapper, IHttpContextAccessor httpContextAccessor) : base(context, mapper)
        {
            _httpContextAccessor = httpContextAccessor;
        }

        public override IQueryable<StaffReview> AddInclude(IQueryable<StaffReview> query, StaffReviewSearchObject? search = null)
        {
            query = query
                .Include(x => x.User)
                .Include(x => x.Employee);

            return base.AddInclude(query, search);
        }

        public override IQueryable<StaffReview> AddFilter(IQueryable<StaffReview> query, StaffReviewSearchObject? search = null)
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
                query = query.Where(
                    x => x.Comment != null &&
                         x.Comment.Contains(search.CommentFTS));
            }

            return base.AddFilter(query, search);
        }

        public override async Task BeforeInsert(StaffReview db, StaffReviewInsertRequest insert)
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

            if (!string.Equals(appointment.State, "completed", StringComparison.OrdinalIgnoreCase))
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

        public override async Task BeforeUpdate(StaffReview db, StaffReviewUpdateRequest update)
        {
            EnsureOwnerOrManager(db);

            db.Comment = string.IsNullOrWhiteSpace(update.Comment) ? null : update.Comment.Trim();

            await base.BeforeUpdate(db, update);
        }

        public override async Task BeforeRemove(StaffReview db)
        {
            EnsureOwnerOrManager(db);

            await base.BeforeRemove(db);
        }

        private ClaimsPrincipal CurrentUser => _httpContextAccessor.HttpContext?.User ?? throw new UserException("Unauthorized.");

        private int GetCurrentUserId()
        {
            var value = CurrentUser.FindFirst(ClaimTypes.NameIdentifier)?.Value;

            if (!int.TryParse(value, out var userId))
            {
                throw new UserException("Unauthorized.");
            }

            return userId;
        }

        private void EnsureOwnerOrManager(StaffReview review)
        {
            var role = CurrentUser.FindFirst(ClaimTypes.Role)?.Value?.Trim().ToLowerInvariant();

            if (role == UserRoles.Manager)
            {
                return;
            }

            if (review.UserId != GetCurrentUserId())
            {
                throw new UserException("Ne možete mijenjati ili brisati tuđu recenziju.");
            }
        }
    }
}
