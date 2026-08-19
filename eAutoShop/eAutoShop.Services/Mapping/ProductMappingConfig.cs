using eAutoShop.Model.Model;
using eAutoShop.Services.Database;
using Mapster;

namespace eAutoShop.Services.Mapping
{
    public class ProductMappingConfig : IRegister
    {
        public void Register(TypeAdapterConfig config)
        {
            config.NewConfig<Product, ProductModel>()
                .Map(
                    destination => destination.Category,
                    source => source.ProductCategory != null
                        ? source.ProductCategory.Name
                        : null
                )
                .Map(
                    destination => destination.Details,
                    source => source.Description
                )
                .Map(
                    destination => destination.ImageData,
                    source => source.Image != null
                        ? Convert.ToBase64String(source.Image)
                        : null
                );
        }
    }
}
