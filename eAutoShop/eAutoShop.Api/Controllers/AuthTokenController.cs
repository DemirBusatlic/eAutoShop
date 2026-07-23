using Azure.Core;
using eAutoShop.Model.Exceptions;
using eAutoShop.Model.Request;
using eAutoShop.Services.Interfaces;
using eAutoShop.Services.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Runtime.CompilerServices;

namespace eAutoShop.Api.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class AuthTokenController : ControllerBase
    {
        private readonly ILogger<AuthTokenController> _logger;

        private readonly IAuthTokenService _authTokenService;

        public AuthTokenController(IAuthTokenService service,ILogger<AuthTokenController> logger)
        {
            _authTokenService = service;
            _logger = logger;
        }

        [AllowAnonymous]
        [HttpPost("login")]
        public async Task<IActionResult> Login([FromBody] UserLoginRequest credentials)
        {
            var token = await _authTokenService.Login(credentials.Username,credentials.Password);

            return Ok(new { token });
        }

        [Authorize]
        [HttpPost("logout")]
        public async Task<IActionResult> Logout()
        {
            var authHeader = Request.Headers["Authorization"].ToString();

            if (string.IsNullOrWhiteSpace(authHeader))
            {
                throw new UserException("Unauthorized.");
            }

            var token = authHeader.Split(" ").Last();

            await _authTokenService.RevokeToken(token);

            return Ok(new{ message = "Logout successful."});
        }
    }

}

