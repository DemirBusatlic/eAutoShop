using eAutoShop.Model.Exceptions;
using eAutoShop.Model.Model;
using eAutoShop.Model.Request;
using eAutoShop.Model.SearchObjects;
using eAutoShop.Services.Interfaces;
using eAutoShop.Services.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;


namespace eAutoShop.Api.Controllers
{

    //[Authorize]


    [ApiController]
    public class UserController : BaseCRUDController<UserModel, UserSearchObject, UserInsertRequest, UserUpdateRequest>
    {
        private readonly IUserService _userService;

        public UserController(IUserService service, ILogger<BaseCRUDController<UserModel, UserSearchObject, UserInsertRequest, UserUpdateRequest>> logger) : base(logger, service)
        {
            _userService = service;
        }

        [Authorize(Roles = "manager")]
        [HttpPost()]
        public async override Task<UserModel> Insert(UserInsertRequest request)
        {

            return await _userService.Insert(request);
        }

        [Authorize(Roles = "manager")]
        [HttpPut("{id}")]
        public async override Task<UserModel> Update(int id,[FromBody] UserUpdateRequest request)
        {
            return await _userService.Update(id, request);
        }

        [Authorize(Roles = "manager")]
        [HttpDelete("{id}")]
        public override Task<IActionResult> Delete(int id)
        {
            return base.Delete(id);
        }


        [AllowAnonymous]
        [HttpPost("Register")]
        public async Task<UserModel> Register(UserInsertRequest request)
        {
            request.RoleId = 2;

            return await ((IUserService)_service).Insert(request);
        }

        [Authorize]
        [HttpGet("Me")]
        public async Task<UserModel> GetCurrentUser()
        {
            var userIdClaim =User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

            if (!int.TryParse(userIdClaim, out var userId))
            {
                throw new UserException("Invalid user token.");
            }

            return await _service.GetById(userId);
        }
        [Authorize]
        [HttpPut("UpdateByToken")]
        public async Task<UserModel> UpdateByToken(UserUpdateRequest request)
        {
            int userId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)!.Value);

            request.UserId = userId;

            return await _userService.UpdateByToken(request);
        }

        [Authorize]
        [HttpPut("ChangePassword")]
        public async Task ChangePassword([FromBody] UserChangePasswordRequest request)
        {
            int userId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)!.Value);

            await ((IUserService)_service).ChangePassword(userId, request);
        }

        [Authorize(Roles = "manager")]
        [HttpPut("ChangeActiveStatus/{id}")]
        public async Task ChangeActiveStatus(int id)
        {
            await _userService.ChangeActiveStatus(id);
        }

    }
}
