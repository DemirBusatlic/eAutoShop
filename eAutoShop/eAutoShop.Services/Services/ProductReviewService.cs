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

namespace eAutoShop.Services.Services
{
    public class ProductReviewService : BaseCRUDService<ProductReviewModel,ProductReview,ProductReviewSearchObject,ProductReviewInsertRequest,ProductReviewUpdateRequest>,IProductReviewService
    {
        public ProductReviewService(AutoShopContext context, IMapper mapper): base(context, mapper)
        {
        }

        public override IQueryable<ProductReview> AddFilter(IQueryable<ProductReview> query,ProductReviewSearchObject? search = null)
        {
            if (search?.Rating != null)
            {
                query = query.Where(x => x.Rating == search.Rating);
            }

            if (search?.UserId != null)
            {
                query = query.Where(x => x.UserId == search.UserId);
            }

            if (search?.ProductId != null)
            {
                query = query.Where(x => x.ProductId == search.ProductId);
            }

            if (!string.IsNullOrWhiteSpace(search?.CommentFTS))
            {
                query = query.Where(x => x.Comment != null && x.Comment.Contains(search.CommentFTS));
            }

            return base.AddFilter(query, search);
        }

        public override Task BeforeInsert(ProductReview db, ProductReviewInsertRequest insert)
        {
            db.CreatedAt = DateTime.Now;

            return base.BeforeInsert(db, insert);
        }
    }
}
