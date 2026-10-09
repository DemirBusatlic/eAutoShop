using eAutoShop.Model.Exceptions;
using eAutoShop.Model.Model;
using eAutoShop.Model.Request;
using eAutoShop.Model.SearchObjects;
using eAutoShop.Services.Database;
using eAutoShop.Services.Helpers;
using eAutoShop.Services.Interfaces;
using eAutoShop.Services.Services.eAutoShop.Services.Database;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using System;
using System.Security.Cryptography;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace eAutoShop.Services.Services
{
    public class UserService : BaseCRUDService<UserModel, User, UserSearchObject, UserInsertRequest, UserUpdateRequest>, IUserService
    {
        private readonly ILogger<UserService> _logger;
        private readonly RabbitMQService _rabbitMQService;

        public UserService(AutoShopContext context, IMapper mapper, ILogger<UserService> logger, RabbitMQService rabbitMQService): base(context, mapper)
        {
            _logger = logger;
            _rabbitMQService = rabbitMQService;
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

        public async Task ForgotPassword(UserForgotPasswordRequest request)
        {
            var email = request.Email?.Trim().ToLowerInvariant();

            if (string.IsNullOrWhiteSpace(email))
            {
                throw new UserException("Email is required.");
            }

            var user = await _context.Users.FirstOrDefaultAsync(x => x.Email == email && x.Active);

            if (user == null)
            {
                return;
            }

            var now = DateTime.UtcNow;

            var latestActiveResetToken = await _context.PasswordResetTokens.Where(x => x.UserId == user.Id && x.UsedAt == null && x.RevokedAt == null && x.ExpiresAt > now).OrderByDescending(x => x.CreatedAt).FirstOrDefaultAsync();

            if (latestActiveResetToken != null && latestActiveResetToken.CreatedAt > now.AddMinutes(-1))
            {
                return;
            }

            var previousTokens = await _context.PasswordResetTokens.Where(x =>x.UserId == user.Id &&x.UsedAt == null && x.RevokedAt == null).ToListAsync();

            foreach (var previousToken in previousTokens)
            {
                previousToken.RevokedAt = now;
            }

            var code = RandomNumberGenerator.GetInt32(0, 1_000_000).ToString("D6");

            var passwordResetToken = new PasswordResetToken
            {
                UserId = user.Id,
                CodeHash = BCrypt.Net.BCrypt.HashPassword(code),
                CreatedAt = now,
                ExpiresAt = now.AddMinutes(15),
                FailedAttempts = 0
            };

            _context.PasswordResetTokens.Add(passwordResetToken);
            await _context.SaveChangesAsync();

            try
            {
                await _rabbitMQService.SendPasswordResetEmail(new PasswordResetEmailModel
                    {
                        Email = user.Email,
                        RecipientName = $"{user.Name} {user.Surname}".Trim(),
                        Code = code,
                        ExpiresAt = passwordResetToken.ExpiresAt
                    });
            }
            catch (Exception exception)
            {
                passwordResetToken.RevokedAt = DateTime.UtcNow;
                await _context.SaveChangesAsync();

                _logger.LogError(exception, "Password reset email could not be queued for user {UserId}.", user.Id);

                throw new UserException("Password reset request could not be processed. Please try again.");
            }
        }

        public async Task ResetPassword(UserResetPasswordRequest request)
        {
            var email = request.Email?.Trim().ToLowerInvariant();
            var code = request.Code?.Trim();

            if (string.IsNullOrWhiteSpace(email))
            {
                throw new UserException("Email is required.");
            }

            if (string.IsNullOrWhiteSpace(code) || code.Length != 6 || !code.All(char.IsDigit))
            {
                throw new UserException("Reset code must contain exactly 6 digits.");
            }

            if (string.IsNullOrWhiteSpace(request.NewPassword))
            {
                throw new UserException("New password is required.");
            }

            if (request.NewPassword.Length < 8)
            {
                throw new UserException("New password must contain at least 8 characters.");
            }

            if (request.NewPassword != request.ConfirmNewPassword)
            {
                throw new UserException("New password values don't match.");
            }

            var user = await _context.Users.FirstOrDefaultAsync(x => x.Email == email && x.Active);

            if (user == null)
            {
                throw new UserException("Reset code is invalid or has expired.");
            }

            var now = DateTime.UtcNow;

            var resetToken = await _context.PasswordResetTokens.Where(x => x.UserId == user.Id && x.UsedAt == null && x.RevokedAt == null).OrderByDescending(x => x.CreatedAt).FirstOrDefaultAsync();

            if (resetToken == null)
            {
                throw new UserException("Reset code is invalid or has expired.");
            }

            if (resetToken.ExpiresAt <= now)
            {
                resetToken.RevokedAt = now;
                await _context.SaveChangesAsync();

                throw new UserException("Reset code is invalid or has expired.");
            }

            if (resetToken.FailedAttempts >= 5)
            {
                resetToken.RevokedAt = now;
                await _context.SaveChangesAsync();

                throw new UserException("Reset code is invalid or has expired.");
            }

            var validCode = BCrypt.Net.BCrypt.Verify(code,resetToken.CodeHash);

            if (!validCode)
            {
                resetToken.FailedAttempts++;

                if (resetToken.FailedAttempts >= 5)
                {
                    resetToken.RevokedAt = now;
                }

                await _context.SaveChangesAsync();

                throw new UserException("Reset code is invalid or has expired.");
            }

            if (!string.IsNullOrWhiteSpace(user.PasswordHash) && BCrypt.Net.BCrypt.Verify(request.NewPassword, user.PasswordHash))
            {
                throw new UserException("New password can't be the same as the old one.");
            }

            user.PasswordHash = BCrypt.Net.BCrypt.HashPassword(request.NewPassword);

            resetToken.UsedAt = now;

            var otherActiveResetTokens =await _context.PasswordResetTokens.Where(x =>x.UserId == user.Id && x.Id != resetToken.Id && x.UsedAt == null && x.RevokedAt == null).ToListAsync();

            foreach (var otherResetToken in otherActiveResetTokens)
            {
                otherResetToken.RevokedAt = now;
            }

            var activeAuthTokens = await _context.AuthTokens.Where(x => x.UserId == user.Id && x.Revoked == null).ToListAsync();

            foreach (var authToken in activeAuthTokens)
            {
                authToken.Revoked = now;
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

            var claimsChanged = false;

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

                if (entity.Username != username)
                {
                    entity.Username = username;
                    claimsChanged = true;
                }
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
                var email = request.Email.Trim().ToLowerInvariant();

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

                if (entity.RoleId != request.RoleId.Value)
                {
                    entity.RoleId = request.RoleId.Value;
                    claimsChanged = true;
                }
            }

            if (request.Image != null)
            {
                if (string.IsNullOrWhiteSpace(request.Image))
                {
                    entity.Image = null;
                }
                else
                {
                    entity.Image = ImageValidator.Parse(request.Image);
                }
            }

            if (claimsChanged)
            {
                var now = DateTime.UtcNow;

                var activeTokens = await _context.AuthTokens.Where(x => x.UserId == entity.Id && x.Revoked == null).ToListAsync();

                foreach (var token in activeTokens)
                {
                    token.Revoked = now;
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
                var email = request.Email.Trim().ToLowerInvariant();

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
                    throw new UserException("Phone is required.");
                entity.Phone = phone;
            }

            if (request.Gender != null)
            {
                entity.Gender = request.Gender.Trim();
            }

            if (request.Address != null)
            {
                entity.Address = string.IsNullOrWhiteSpace(request.Address)? null : request.Address.Trim();
            }

            if (request.PostalCode != null)
            {
                entity.PostalCode = string.IsNullOrWhiteSpace(request.PostalCode)? null : request.PostalCode.Trim();
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

            if (request.Image != null)
            {
                if (string.IsNullOrWhiteSpace(request.Image))
                {
                    entity.Image = null;
                }
                else
                {
                    entity.Image = ImageValidator.Parse(request.Image);
                }
            }

            await _context.SaveChangesAsync();

            return await GetById(entity.Id);
        }

        public async Task<UserModel> Register(UserRegistrationRequest request)
        {
            var customerRoleId = await _context.Roles
                .Where(role => role.Name == UserRoles.Customer)
                .Select(role => (int?)role.Id)
                .SingleOrDefaultAsync();

            if (!customerRoleId.HasValue)
            {
                throw new UserException("Customer role is not configured.");
            }

            var insertRequest = _mapper.Map<UserInsertRequest>(request);

            insertRequest.RoleId = customerRoleId.Value;

            return await Insert(insertRequest);
        }

        public override async Task BeforeInsert(User entity,UserInsertRequest request)
        {
            var username = request.Username?.Trim();
            var email = request.Email?.Trim().ToLowerInvariant();
            var name = request.Name?.Trim();
            var surname = request.Surname?.Trim();
            var phone = request.Phone?.Trim();
            var gender = request.Gender?.Trim();

            if (string.IsNullOrWhiteSpace(username))
            {
                throw new UserException("Username is required.");
            }

            if (string.IsNullOrWhiteSpace(email))
            {
                throw new UserException("Email is required.");
            }

            if (string.IsNullOrWhiteSpace(name))
            {
                throw new UserException("Name is required.");
            }

            if (string.IsNullOrWhiteSpace(surname))
            {
                throw new UserException("Surname is required.");
            }

            if (string.IsNullOrWhiteSpace(phone))
            {
                throw new UserException("Phone is required.");
            }

            if (string.IsNullOrWhiteSpace(gender))
            {
                throw new UserException("Gender is required.");
            }

            var cityExists = await _context.Cities.AnyAsync(x => x.Id == request.CityId);

            if (!cityExists)
            {
                throw new UserException("Selected city doesn't exist.");
            }

            if (!request.RoleId.HasValue ||!await _context.Roles.AnyAsync(x => x.Id == request.RoleId.Value))
            {
                throw new UserException("Selected role doesn't exist.");
            }

            var usernameTaken = await _context.Users.AnyAsync(x => x.Username == username);

            if (usernameTaken)
            {
                throw new UserException("This username is already in use.");
            }

            var emailTaken = await _context.Users.AnyAsync(x => x.Email == email);

            if (emailTaken)
            {
                throw new UserException("This email is already in use.");
            }

            if (request.Password != request.PasswordConfirm)
            {
                throw new UserException("Passwords must match.");
            }

            entity.Username = username;
            entity.Email = email;
            entity.Name = name;
            entity.Surname = surname;
            entity.Phone = phone;
            entity.Gender = gender;

            entity.Address =string.IsNullOrWhiteSpace(request.Address)? null: request.Address.Trim();

            entity.PostalCode =string.IsNullOrWhiteSpace(request.PostalCode)? null: request.PostalCode.Trim();

            entity.PasswordHash =BCrypt.Net.BCrypt.HashPassword(request.Password);

            entity.CreatedAt = DateTime.UtcNow;
            entity.Active = true;

            entity.Image =string.IsNullOrWhiteSpace(request.Image)? null: ImageValidator.Parse(request.Image);

            await base.BeforeInsert(entity, request);
        }
    }
}
