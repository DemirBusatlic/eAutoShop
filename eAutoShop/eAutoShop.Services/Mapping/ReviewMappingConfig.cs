using eAutoShop.Model.Model;
using eAutoShop.Services.Database;
using Mapster;

namespace eAutoShop.Services.Mapping
{
    public class ReviewMappingConfig : IRegister
    {
        public void Register(TypeAdapterConfig config)
        {
            config.NewConfig<StaffReview, StaffReviewModel>()
                .Map(
                    destination => destination.UserName,
                    source => source.User != null
                        ? source.User.Username
                        : null
                )
                .Map(
                    destination => destination.EmployeeName,
                    source => source.Employee != null
                        ? source.Employee.Name + " " +
                          source.Employee.Surname
                        : null
                );

            config.NewConfig<ProductReview, ProductReviewModel>()
                .Map(
                    destination => destination.UserName,
                    source => source.User != null
                        ? source.User.Username
                        : null
                )
                .Map(
                    destination => destination.ProductName,
                    source => source.Product != null
                        ? source.Product.Name
                        : null
                );
        }
    }
}
