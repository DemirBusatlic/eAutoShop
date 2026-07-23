using eAutoShop.Model.Exceptions;
using eAutoShop.Model.Model;
using eAutoShop.Model.Request;
using eAutoShop.Model.SearchObjects;
using eAutoShop.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;


namespace eAutoShop.Api.Controllers
{

    //[Authorize]

    [AllowAnonymous]
    [ApiController]
    public class UserController : BaseCRUDController<UserModel,UserSearchObject,UserInsertRequest,UserUpdateRequest>
    {

        public UserController(IUserService service, ILogger<BaseCRUDController<UserModel, UserSearchObject, UserInsertRequest, UserUpdateRequest>> logger) : base(logger, service)
        {
        }

        [Authorize(Roles = "manager")]
        [HttpPost()]
        public async override Task<UserModel> Insert(UserInsertRequest request)
        {
            
            return await (_service as IUserService).Insert(request);
        }


        [Authorize]
        [HttpPut("UpdateByToken")]
        public async Task<UserModel> UpdateByToken(UserUpdateRequest request)
        {
            int userId = int.Parse(
                User.FindFirst(ClaimTypes.NameIdentifier)!.Value
            );

            request.UserId = userId;

            return await (_service as IUserService).UpdateByToken(request);
        }

        [Authorize]
        [HttpPut("ChangePassword")]
        public async Task ChangePassword([FromBody] UserChangePasswordRequest request)
        {
            int userId = int.Parse(
                User.FindFirst(ClaimTypes.NameIdentifier)!.Value);

            await ((IUserService)_service).ChangePassword(userId, request);
        }

        [Authorize(Roles = "manager")]
        [HttpPut("ChangeActiveStatus/{id}")]
        public async Task ChangeActiveStatus(int id)
        {
            await (_service as IUserService).ChangeActiveStatus(id);
        }

    }
}
