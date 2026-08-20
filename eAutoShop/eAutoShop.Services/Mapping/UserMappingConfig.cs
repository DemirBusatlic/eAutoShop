using System;
using eAutoShop.Model.Model;
using eAutoShop.Services.Database;
using Mapster;

namespace eAutoShop.Services.Mapping
{
    public class UserMappingConfig : IRegister
    {
        public void Register(TypeAdapterConfig config)
        {
            config.NewConfig<User, UserModel>()
                .Map(
                    destination => destination.Image,
                    source => source.Image != null
                        ? Convert.ToBase64String(source.Image)
                        : null
                )
                .Map(
                    destination => destination.CityName,
                    source => source.City != null
                        ? source.City.Name
                        : null
                )
                .Map(
                    destination => destination.RoleName,
                    source => source.Role != null
                        ? source.Role.Name
                        : null
                );
        }
    }
}
