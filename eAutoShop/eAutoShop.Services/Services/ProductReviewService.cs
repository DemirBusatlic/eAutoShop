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
    public class ProductReviewService : BaseCRUDService<ProductReviewModel, ProductReview, ProductReviewSearchObject, ProductReviewInsertRequest, ProductReviewUpdateRequest>, IProductReviewService
    {
        private readonly IHttpContextAccessor _httpContextAccessor;

        public ProductReviewService(AutoShopContext context, IMapper mapper, IHttpContextAccessor httpContextAccessor): base(context, mapper)
        {
            _httpContextAccessor = httpContextAccessor;
        }

        public override IQueryable<ProductReview> AddInclude(IQueryable<ProductReview> query,ProductReviewSearchObject? search = null)
        {
            return base.AddInclude(query.Include(x => x.User).Include(x => x.Product), search);
        }

        public override IQueryable<ProductReview> AddFilter(IQueryable<ProductReview> query,ProductReviewSearchObject? search = null)
        {
            if (search?.Rating != null)
                query = query.Where(x => x.Rating == search.Rating);

            if (search?.UserId != null)
                query = query.Where(x => x.UserId == search.UserId);

            if (search?.ProductId != null)
                query = query.Where(x => x.ProductId == search.ProductId);

            if (!string.IsNullOrWhiteSpace(search?.CommentFTS))
                query = query.Where(x => x.Comment != null && x.Comment.Contains(search.CommentFTS));

            return base.AddFilter(query, search);
        }

        public override async Task BeforeInsert(ProductReview db,ProductReviewInsertRequest insert)
        {
            if (insert.UserId == null)
            {
                throw new UserException("Prijavljeni korisnik nije pronađen.");
            }

            var orderItem = await _context.OrderItems.AsNoTracking().Include(x => x.Order).FirstOrDefaultAsync(x => x.Id == insert.OrderItemId);

            if (orderItem == null)
            {
                throw new UserException("Stavka narudžbe nije pronađena.");
            }

            if (orderItem.Order.CustomerId != insert.UserId.Value)
            {
                throw new UserException( "Ne možete ocijeniti proizvod iz tuđe narudžbe.");
            }

            var orderState = orderItem.Order.State;

            var canReview =string.Equals(orderState,"completed",StringComparison.OrdinalIgnoreCase) ||string.Equals(orderState,"delivered",StringComparison.OrdinalIgnoreCase);

            if (!canReview)
            {
                throw new UserException("Proizvod možete ocijeniti tek nakon završene narudžbe.");
            }

            var reviewAlreadyExists = await _context.ProductReviews.AnyAsync(x => x.OrderItemId == orderItem.Id);

            if (reviewAlreadyExists)
            {
                throw new UserException("Ovaj proizvod iz narudžbe je već ocijenjen.");
            }

            db.UserId = insert.UserId.Value;
            db.ProductId = orderItem.ProductId;
            db.OrderItemId = orderItem.Id;
            db.CreatedAt = DateTime.Now;

            await base.BeforeInsert(db, insert);
        }

        public override async Task BeforeUpdate(ProductReview db, ProductReviewUpdateRequest update)
        {
            EnsureOwnerOrManager(db);
            db.Comment = string.IsNullOrWhiteSpace(update.Comment)? null : update.Comment.Trim();

            await base.BeforeUpdate(db, update);
        }

        public override async Task BeforeRemove(ProductReview db)
        {
            EnsureOwnerOrManager(db);
            await base.BeforeRemove(db);
        }

        private ClaimsPrincipal CurrentUser =>_httpContextAccessor.HttpContext?.User ?? throw new UserException("Unauthorized.");

        private int GetCurrentUserId()
        {
            var value = CurrentUser.FindFirst(ClaimTypes.NameIdentifier)?.Value;

            if (!int.TryParse(value, out var userId))
                throw new UserException("Unauthorized.");

            return userId;
        }

        private void EnsureOwnerOrManager(ProductReview review)
        {
            var role = CurrentUser.FindFirst(ClaimTypes.Role)?.Value?.Trim().ToLowerInvariant();

            if (role == UserRoles.Manager)
                return;

            if (review.UserId != GetCurrentUserId())
                throw new UserException("Ne možete mijenjati tuđu recenziju.");
        }
    }
}
