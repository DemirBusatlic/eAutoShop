using BCrypt.Net;
using eAutoShop.Model.Exceptions;
using eAutoShop.Model.SearchObjects;
using eAutoShop.Services.Database;
using eAutoShop.Services.Interfaces;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Conventions;
using Microsoft.IdentityModel.Tokens;
using System;
using System.Collections.Generic;
using System.IdentityModel.Tokens.Jwt;
using System.Linq;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using System.Threading.Tasks;

namespace eAutoShop.Services.Services
{
    public class BaseCRUDService<T, TDb, TSearch, TInsert, TUpdate> : BaseService<T, TDb, TSearch>, IBaseCRUDService<T, TSearch, TInsert, TUpdate> where TDb : class where T : class where TSearch : BaseSearchObject, new() where TInsert : class where TUpdate : class
    {
        public BaseCRUDService(AutoShopContext context, IMapper mapper)
            : base(context, mapper)
        {
        }

        public virtual Task BeforeInsert(TDb db, TInsert insert)
        {
            return Task.CompletedTask;
        }

        public virtual Task BeforeUpdate(TDb db, TUpdate update)
        {
            return Task.CompletedTask;
        }

        public virtual Task BeforeRemove(TDb db)
        {
            return Task.CompletedTask;
        }

        public virtual async Task<T> Insert(TInsert insert)
        {
            var set = _context.Set<TDb>();

            TDb entity = _mapper.Map<TDb>(insert);

            await BeforeInsert(entity, insert);

            set.Add(entity);

            await _context.SaveChangesAsync();

            return _mapper.Map<T>(entity);
        }

        public virtual async Task<T> Update(int id, TUpdate update)
        {
            var set = _context.Set<TDb>();

            var query = set.AsQueryable();

            query = AddInclude(query);

            query = AddFilterById(query, id);

            var entity = await query.FirstOrDefaultAsync();

            if (entity == null)
                throw new UserException("Entity not found.");

            _mapper.Map(update, entity);

            await BeforeUpdate(entity, update);

            await _context.SaveChangesAsync();

            return _mapper.Map<T>(entity);
        }

        public virtual async Task<bool> Delete(int id)
        {
            var set = _context.Set<TDb>();

            var query = set.AsQueryable();

            query = AddInclude(query);

            query = AddFilterById(query, id);

            var entity = await query.FirstOrDefaultAsync();

            if (entity == null)
                throw new UserException("Entity not found.");

            await BeforeRemove(entity);

            set.Remove(entity);

            await _context.SaveChangesAsync();

            return true;
        }

        public string GenerateHash(string password)
        {
            return BCrypt.Net.BCrypt.HashPassword(password);
        }

        public bool VerifyPassword(string password, string hash)
        {
            return BCrypt.Net.BCrypt.Verify(password, hash);
        }

        public static AuthToken GenerateToken(User user, string secret)
        {
            var tokenHandler = new JwtSecurityTokenHandler();

            var key = Encoding.ASCII.GetBytes(secret);

            var tokenDescriptor = new SecurityTokenDescriptor
            {
                Subject = new ClaimsIdentity(new[]
                {
                new Claim(ClaimTypes.Name, user.Username),
                new Claim(ClaimTypes.NameIdentifier, user.Id.ToString()),
                new Claim(ClaimTypes.Role, user.Role.Name)
            }),

                Expires = DateTime.UtcNow.AddDays(7),

                SigningCredentials = new SigningCredentials(
                    new SymmetricSecurityKey(key),
                    SecurityAlgorithms.HmacSha256Signature)
            };

            var token = tokenHandler.CreateToken(tokenDescriptor);

            var tokenString = tokenHandler.WriteToken(token);

            return new AuthToken
            {
                Value = tokenString,
                UserId = user.Id,
                Created = DateTime.UtcNow
            };
        }
    }
}

