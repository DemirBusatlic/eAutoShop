using eAutoShop.Model.Exceptions;
using eAutoShop.Model.Model;
using eAutoShop.Model.Request;
using eAutoShop.Model.SearchObjects;
using eAutoShop.Services.Database;
using eAutoShop.Services.Helpers;
using eAutoShop.Services.Interfaces;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using Newtonsoft.Json.Linq;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace eAutoShop.Services.Services
{
    public class AuthTokenService : BaseCRUDService<AuthTokenModel, AuthToken, AuthTokenSearchObject, AuthTokenInsertRequest, AuthTokenUpdateRequest>, IAuthTokenService
    {
        private readonly string _secret;

        public AuthTokenService(string secret, AutoShopContext context, IMapper mapper) : base(context, mapper)
        {
            _secret = secret;
        }

        public async Task<string> Login(string username, string password)
        {
            var user = await _context.Users.Include(x => x.Role).FirstOrDefaultAsync(x => x.Username == username);

            if (user == null)
            {
                throw new UserException("Incorrect login!");
            }

            var validPassword = BCrypt.Net.BCrypt.Verify(password, user.PasswordHash);

            if (!validPassword)
            {
                throw new UserException("Incorrect login!");
            }

            if (!user.Active)
            {
                var manager = await _context.Users.Include(x => x.Role).FirstOrDefaultAsync(x => x.Role.Name == UserRoles.Manager);

                throw new UserException($"Your account is inactive! " + $"Please contact the administrator! " + $"Phone: {manager?.Phone} " + $"Email: {manager?.Email}");
            }

            var authToken = GenerateToken(user, _secret);

            if (authToken.Created == default)
            {
                authToken.Created = DateTime.UtcNow;
            }

            await _context.AuthTokens.AddAsync(authToken);

            await _context.SaveChangesAsync();

            return authToken.Value;
        }

        public async Task RevokeToken(string token)
        {
            var entity = await _context.AuthTokens.FirstOrDefaultAsync(x => x.Value == token);

            if (entity == null)
            {
                return;
            }

            if (entity.Revoked == null)
            {
                entity.Revoked = DateTime.UtcNow;

                await _context.SaveChangesAsync();
            }
        }

        public async Task<bool> IsTokenRevoked(string token)
        {
            var entity = await _context.AuthTokens.FirstOrDefaultAsync(x => x.Value == token);

            if (entity == null)
            {
                return true;
            }

            return entity.Revoked != null;
        }
    }
}
