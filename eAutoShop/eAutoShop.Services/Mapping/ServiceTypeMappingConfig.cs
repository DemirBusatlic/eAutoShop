using System;
using eAutoShop.Model.Model;
using eAutoShop.Services.Database;
using Mapster;

namespace eAutoShop.Services.Mapping
{
    public class ServiceTypeMappingConfig : IRegister
    {
        public void Register(TypeAdapterConfig config)
        {
            config.NewConfig<ServiceType, ServiceTypeModel>()
                .Map(
                    destination => destination.Image,
                    source => source.Image != null &&
                              source.Image.Length > 0
                        ? Convert.ToBase64String(source.Image)
                        : string.Empty
                );
        }
    }
}
