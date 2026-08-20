using eAutoShop.Model.Model;
using eAutoShop.Model.Request;
using eAutoShop.Model.SearchObjects;
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

        public override Task BeforeInsert(StaffReview db, StaffReviewInsertRequest insert)
        {
            db.CreatedAt = DateTime.Now;

            return base.BeforeInsert(db, insert);
        }
    }
}
