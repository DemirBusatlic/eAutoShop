using eAutoShop.Model.Model;
using eAutoShop.Services.Database;
using Mapster;

namespace eAutoShop.Services.Mapping
{
    public class AutoShopServiceMappingConfig : IRegister
    {
        public void Register(TypeAdapterConfig config)
        {
            config.NewConfig<AutoShopService, AutoShopServiceModel>()
                .Map(
                    destination => destination.ServiceTypeName,
                    source => source.ServiceType != null
                        ? source.ServiceType.Name
                        : string.Empty
                )
                .Map(
                    destination => destination.ImageData,
                    source => source.Image != null &&
                              source.Image.Length > 0
                        ? Convert.ToBase64String(source.Image)
                        : null
                )
                .Map(
                    destination => destination.Duration,
                    source => source.Duration.ToTimeSpan()
                );
        }
    }
}