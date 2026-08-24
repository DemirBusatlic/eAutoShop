using eAutoShop.Model.Model;
using eAutoShop.Model.Request;
using eAutoShop.Model.SearchObjects;
using eAutoShop.Services.Interfaces;
using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace eAutoShop.Api.Controllers
{
    [ApiController]
    public class StaffReviewController : BaseCRUDController<StaffReviewModel,StaffReviewSearchObject,StaffReviewInsertRequest,StaffReviewUpdateRequest>
    {
        public StaffReviewController(ILogger<BaseController<StaffReviewModel, StaffReviewSearchObject>> logger,IStaffReviewService service): base(logger, service)
        {
        }

        [Authorize(Roles = "customer")]
        public override Task<StaffReviewModel> Insert([FromBody] StaffReviewInsertRequest insert)
        {
            var userIdClaim = User.FindFirstValue(ClaimTypes.NameIdentifier);

            if (!int.TryParse(userIdClaim, out var userId))
            {
                throw new UnauthorizedAccessException("Prijavljeni korisnik nije pronađen.");
            }

            insert.UserId = userId;

            return base.Insert(insert);
        }

        [Authorize]
        public override Task<StaffReviewModel> Update(int id,[FromBody] StaffReviewUpdateRequest update)
        {
            return base.Update(id, update);
        }

        [Authorize]
        public override Task<IActionResult> Delete(int id)
        {
            return base.Delete(id);
        }
    }
}
