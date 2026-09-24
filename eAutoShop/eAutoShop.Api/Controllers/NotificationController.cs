using System.Security.Claims;
using eAutoShop.Model.Exceptions;
using eAutoShop.Model.Model;
using eAutoShop.Services.Helpers;
using eAutoShop.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace eAutoShop.Api.Controllers
{
    [ApiController]
    [Route("[controller]")]
    [Authorize(Roles = UserRoles.Customer)]
    public class NotificationController : ControllerBase
    {
        private readonly INotificationService _notificationService;

        public NotificationController(INotificationService notificationService)
        {
            _notificationService = notificationService;
        }

        [HttpGet]
        public async Task<List<NotificationModel>> Get()
        {
            return await _notificationService.GetByUser(GetRequiredUserId());
        }

        [HttpPut("MarkAsRead/{id}")]
        public async Task<NotificationModel> MarkAsRead(int id)
        {
            return await _notificationService.MarkAsRead(id,GetRequiredUserId());
        }

        private int GetRequiredUserId()
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

            if (!int.TryParse(userIdClaim, out var userId))
            {
                throw new UserException("Prijavljeni korisnik nije pronađen.");
            }

            return userId;
        }
    }
}
