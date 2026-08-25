using eAutoShop.Model.Model;
using eAutoShop.Model.Request;
using eAutoShop.Model.SearchObjects;
using eAutoShop.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace eAutoShop.Api.Controllers
{
    [ApiController]
    public class ProductReviewController : BaseCRUDController<ProductReviewModel, ProductReviewSearchObject, ProductReviewInsertRequest, ProductReviewUpdateRequest>
    {
        public ProductReviewController(ILogger<BaseController<ProductReviewModel, ProductReviewSearchObject>> logger, IProductReviewService service): base(logger, service)
        {
        }

        [Authorize(Roles = "customer")]
        public override Task<ProductReviewModel> Insert([FromBody] ProductReviewInsertRequest insert)
        {
            var userIdClaim = User.FindFirstValue(ClaimTypes.NameIdentifier);

            if (!int.TryParse(userIdClaim, out var userId))
            {
                throw new UnauthorizedAccessException("Prijavljeni korisnik nije pronađen.");
            }

            insert.UserId = userId;

            return base.Insert(insert);
        }

        [Authorize(Roles = "customer")]
        public override Task<ProductReviewModel> Update(int id, [FromBody] ProductReviewUpdateRequest update)
        {
            return base.Update(id, update);
        }

        [Authorize(Roles = "customer,manager")]
        public override Task<IActionResult> Delete(int id)
        {
            return base.Delete(id);
        }
    }
}

