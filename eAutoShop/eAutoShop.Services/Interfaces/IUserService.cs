using eAutoShop.Model.Model;
using eAutoShop.Model.Request;
using eAutoShop.Model.SearchObjects;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace eAutoShop.Services.Interfaces
{
    public interface IUserService : IBaseCRUDService<UserModel, UserSearchObject, UserInsertRequest, UserUpdateRequest>
    {

        Task<UserModel> UpdateByToken(UserUpdateRequest request);


        Task ChangePassword(int userId, UserChangePasswordRequest request);

        Task ChangeActiveStatus(int id);

    }
}
