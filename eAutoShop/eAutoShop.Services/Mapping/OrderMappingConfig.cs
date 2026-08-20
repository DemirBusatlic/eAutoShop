using eAutoShop.Model.Model;
using eAutoShop.Services.Database;
using Mapster;

namespace eAutoShop.Services.Mapping
{
    public class OrderMappingConfig : IRegister
    {
        public void Register(TypeAdapterConfig config)
        {
            config.NewConfig<Order, OrderModel>()
                .Map(
                    destination => destination.Username,
                    source => source.Customer.Username
                )
                .Map(
                    destination => destination.ShippingCity,
                    source => source.City.Name
                )
                .Map(
                    destination => destination.ShippingPostalCode,
                    source => source.PostalCode
                );

            config.NewConfig<OrderItem, OrderItemModel>()
                .Map(
                    destination => destination.ProductName,
                    source => source.Product.Name
                )
                .Map(
                    destination => destination.TotalItemsPrice,
                    source => source.TotalItemPrice
                )
                .Map(
                    destination => destination.TotalItemsPriceDiscounted,
                    source => source.TotalItemPriceDiscounted
                );

            config.NewConfig<Order, OrderBasicInfoModel>()
                .Map(
                    destination => destination.Username,
                    source => source.Customer != null
                        ? source.Customer.Username
                        : string.Empty
                )
                .Ignore(destination => destination.Items);
        }
    }
}
