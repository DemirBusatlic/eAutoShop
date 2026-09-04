using eAutoShop.Model.Exceptions;
using eAutoShop.Model.Model;
using eAutoShop.Model.Request;
using eAutoShop.Model.SearchObjects;
using eAutoShop.Services.Database;
using eAutoShop.Services.Helpers;
using eAutoShop.Services.Interfaces;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace eAutoShop.Services.Services
{
    public class UserService : BaseCRUDService<UserModel, User, UserSearchObject, UserInsertRequest, UserUpdateRequest>, IUserService
    {
        private readonly ILogger<UserService> _logger;

        public UserService(AutoShopContext context, IMapper mapper, ILogger<UserService> logger) : base(context, mapper)
        {
            _logger = logger;
        }

        public override IQueryable<User> AddInclude(IQueryable<User> query, UserSearchObject? search = null)
        {
            query = query.Include(x => x.Role).Include(x => x.City);

            return query;
        }

        public override IQueryable<User> AddFilter(IQueryable<User> query, UserSearchObject? search = null)
        {
            if (search != null)
            {
                if (!string.IsNullOrWhiteSpace(search.Role))
                {
                    query = query.Where(x => x.Role.Name == search.Role);
                }

                if (!string.IsNullOrWhiteSpace(search.Username))
                {
                    query = query.Where(x => x.Username == search.Username);
                }

                if (!string.IsNullOrWhiteSpace(search.ContainsUsername))
                {
                    query = query.Where(x => x.Username.Contains(search.ContainsUsername));
                }

                if (search.Active.HasValue)
                {
                    query = query.Where(x => x.Active == search.Active.Value);
                }
            }

            return query;
        }

        public async Task ChangeActiveStatus(int id)
        {
            var entity = await _context.Users.FirstOrDefaultAsync(x => x.Id == id);

            if (entity == null)
            {
                throw new UserException("Wrong user id!");
            }

            entity.Active = !entity.Active;

            if (!entity.Active)
            {
                var now = DateTime.UtcNow;

                var tokens = await _context.AuthTokens.Where(x => x.UserId == entity.Id && x.Revoked == null).ToListAsync();

                foreach (var token in tokens)
                {
                    token.Revoked = now;
                }
            }

            await _context.SaveChangesAsync();
        }

        public async Task ChangePassword(int userId, UserChangePasswordRequest request)
        {
            if (request.NewPassword != request.ConfirmNewPassword)
            {
                throw new UserException("New password values don't match.");
            }

            var user = await _context.Users
                .FirstOrDefaultAsync(x => x.Id == userId);

            if (user == null)
            {
                throw new UserException("User not found.");
            }

            if (!user.Active)
            {
                throw new UserException("Your account is inactive.");
            }

            var validPassword = BCrypt.Net.BCrypt.Verify(request.OldPassword, user.PasswordHash);

            if (!validPassword)
            {
                throw new UserException("Wrong old password.");
            }

            var samePassword = BCrypt.Net.BCrypt.Verify(request.NewPassword, user.PasswordHash);

            if (samePassword)
            {
                throw new UserException("New password can't be the same as the old one.");
            }

            user.PasswordHash = BCrypt.Net.BCrypt.HashPassword(request.NewPassword);

            var activeTokens = await _context.AuthTokens.Where(x => x.UserId == userId && x.Revoked == null).ToListAsync();

            foreach (var token in activeTokens)
            {
                token.Revoked = DateTime.UtcNow;
            }

            await _context.SaveChangesAsync();
        }

        public override async Task<UserModel> Update(int id, UserUpdateRequest request)
        {
            var entity = await _context.Users
                .Include(x => x.City)
                .Include(x => x.Role)
                .FirstOrDefaultAsync(x => x.Id == id);

            if (entity == null)
            {
                throw new UserException("User doesn't exist.");
            }

            if (request.Username != null)
            {
                var username = request.Username.Trim();

                if (string.IsNullOrWhiteSpace(username))
                {
                    throw new UserException("Username is required.");
                }

                var usernameTaken = await _context.Users.AnyAsync(x => x.Id != entity.Id && x.Username == username);

                if (usernameTaken)
                {
                    throw new UserException("This username is already in use.");
                }

                entity.Username = username;
            }

            if (request.Name != null)
            {
                var name = request.Name.Trim();

                if (string.IsNullOrWhiteSpace(name))
                {
                    throw new UserException("Name is required.");
                }

                entity.Name = name;
            }

            if (request.Surname != null)
            {
                var surname = request.Surname.Trim();

                if (string.IsNullOrWhiteSpace(surname))
                {
                    throw new UserException("Surname is required.");
                }

                entity.Surname = surname;
            }

            if (request.Email != null)
            {
                var email = request.Email.Trim();

                if (string.IsNullOrWhiteSpace(email))
                {
                    throw new UserException("Email is required.");
                }

                var emailTaken = await _context.Users.AnyAsync(x => x.Id != entity.Id && x.Email == email);

                if (emailTaken)
                {
                    throw new UserException("This email is already in use.");
                }

                entity.Email = email;
            }

            if (request.Phone != null)
            {
                var phone = request.Phone.Trim();

                if (string.IsNullOrWhiteSpace(phone))
                {
                    throw new UserException("Phone is required.");
                }

                entity.Phone = phone;
            }

            if (request.Gender != null)
            {
                var gender = request.Gender.Trim();

                if (string.IsNullOrWhiteSpace(gender))
                {
                    throw new UserException("Gender is required.");
                }

                entity.Gender = gender;
            }

            if (request.Address != null)
            {
                entity.Address = string.IsNullOrWhiteSpace(request.Address) ? null : request.Address.Trim();
            }

            if (request.PostalCode != null)
            {
                entity.PostalCode = string.IsNullOrWhiteSpace(request.PostalCode) ? null : request.PostalCode.Trim();
            }

            if (request.CityId.HasValue)
            {
                var cityExists = await _context.Cities.AnyAsync(x => x.Id == request.CityId.Value);

                if (!cityExists)
                {
                    throw new UserException("Selected city doesn't exist.");
                }

                entity.CityId = request.CityId.Value;
            }

            if (request.RoleId.HasValue)
            {
                var roleExists = await _context.Roles.AnyAsync(
                    x => x.Id == request.RoleId.Value
                );

                if (!roleExists)
                {
                    throw new UserException("Selected role doesn't exist.");
                }

                entity.RoleId = request.RoleId.Value;
            }

            if (request.Image != null)
            {
                if (string.IsNullOrWhiteSpace(request.Image))
                {
                    entity.Image = null;
                }
                else
                {
                    try
                    {
                        entity.Image = Convert.FromBase64String(request.Image);
                    }
                    catch (FormatException)
                    {
                        throw new UserException("Invalid image format.");
                    }
                }
            }

            await _context.SaveChangesAsync();

            return await GetById(entity.Id);
        }

        public async Task<UserModel> UpdateByToken(UserUpdateRequest request)
        {
            var entity = await _context.Users
                .Include(x => x.City)
                .Include(x => x.Role)
                .FirstOrDefaultAsync(x => x.Id == request.UserId);

            if (entity == null)
            {
                throw new UserException("User doesn't exist.");
            }

            if (!entity.Active)
            {
                throw new UserException("Your account is inactive.");
            }

            if (request.Name != null)
            {
                entity.Name = request.Name.Trim();
            }

            if (request.Surname != null)
            {
                entity.Surname = request.Surname.Trim();
            }

            if (request.Email != null)
            {
                var email = request.Email.Trim();

                var emailTaken = await _context.Users.AnyAsync(
                    x => x.Id != entity.Id && x.Email == email
                );

                if (emailTaken)
                {
                    throw new UserException("This email is already in use.");
                }

                entity.Email = email;
            }

            if (request.Phone != null)
            {
                entity.Phone = request.Phone.Trim();
            }

            if (request.Gender != null)
            {
                entity.Gender = request.Gender.Trim();
            }

            if (request.Address != null)
            {
                entity.Address = string.IsNullOrWhiteSpace(request.Address)
                    ? null
                    : request.Address.Trim();
            }

            if (request.PostalCode != null)
            {
                entity.PostalCode = string.IsNullOrWhiteSpace(request.PostalCode)
                    ? null
                    : request.PostalCode.Trim();
            }

            if (request.CityId.HasValue)
            {
                var cityExists = await _context.Cities.AnyAsync(
                    x => x.Id == request.CityId.Value
                );

                if (!cityExists)
                {
                    throw new UserException("Selected city doesn't exist.");
                }

                entity.CityId = request.CityId.Value;
            }

            if (request.Image != null)
            {
                if (string.IsNullOrWhiteSpace(request.Image))
                {
                    entity.Image = null;
                }
                else
                {
                    try
                    {
                        entity.Image = Convert.FromBase64String(request.Image);
                    }
                    catch (FormatException)
                    {
                        throw new UserException("Invalid image format.");
                    }
                }
            }

            await _context.SaveChangesAsync();

            return await GetById(entity.Id);
        }

        public override async Task BeforeInsert(User entity, UserInsertRequest request)
        {
            var usernameTaken = await _context.Users.AnyAsync(x => x.Username == request.Username);

            if (usernameTaken)
            {
                throw new UserException("This username is already in use.");
            }

            var emailTaken = await _context.Users.AnyAsync(x => x.Email == request.Email);

            if (emailTaken)
            {
                throw new UserException("This email is already in use.");
            }

            if (request.Password != request.PasswordConfirm)
            {
                throw new UserException("Passwords must match.");
            }

            entity.PasswordHash = BCrypt.Net.BCrypt.HashPassword(request.Password);

            entity.CreatedAt = DateTime.UtcNow;

            entity.Active = true;

            if (!string.IsNullOrWhiteSpace(request.Image))
            {
                try
                {
                    entity.Image = Convert.FromBase64String(request.Image);
                }
                catch (FormatException)
                {
                    throw new UserException("Invalid image format.");
                }
            }
            else
            {
                entity.Image = null;
            }

            await base.BeforeInsert(entity, request);
        }
    }
}
