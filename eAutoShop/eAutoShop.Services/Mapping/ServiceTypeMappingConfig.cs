using eAutoShop.Model.Model;
using eAutoShop.Model.Request;
using eAutoShop.Services.Database;
using Mapster;
using System;

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
                        : string.Empty);

            config.NewConfig<ServiceTypeInsertRequest, ServiceType>()
                .Ignore(destination => destination.Image);

            config.NewConfig<ServiceTypeUpdateRequest, ServiceType>()
                .Ignore(destination => destination.Image);
        }
    }
}
