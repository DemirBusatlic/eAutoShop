using eAutoShop.Model.Model;
using eAutoShop.Model.Request;
using eAutoShop.Model.SearchObjects;
using eAutoShop.Services.Database;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace eAutoShop.Services.Interfaces
{
    public interface IAuthTokenService : IBaseCRUDService<AuthTokenModel, AuthTokenSearchObject, AuthTokenInsertRequest, AuthTokenUpdateRequest>
    {
        Task<string> Login(string username, string passowrd);
        Task RevokeToken(string token);
        Task<bool> IsTokenRevoked(string token);
    }
}
