using eAutoShop.Model.Model;
using eAutoShop.Services.Database;
using Mapster;

namespace eAutoShop.Services.Mapping
{
    public class AppointmentMappingConfig : IRegister
    {
        public void Register(TypeAdapterConfig config)
        {
            config.NewConfig<Appointment, AppointmentModel>()
                .Map(
                    destination => destination.CustomerUsername,
                    source => source.Customer != null
                        ? source.Customer.Username
                        : string.Empty
                )
                .Map(
                    destination => destination.EmployeeUsername,
                    source => source.Employee != null
                        ? source.Employee.Username
                        : null
                )
                .Map(
                    destination => destination.CarModel,
                    source => source.CarModel != null
                        ? source.CarModel.Name +
                          " (" + source.CarModel.ModelYear + ")"
                        : string.Empty
                )
                .Map(
                    destination => destination.TotalDuration,
                    source => source.TotalDuration.ToTimeSpan()
                );

            config.NewConfig<AppointmentDetail, AppointmentDetailModel>()
                .Map(
                    destination => destination.ServiceId,
                    source => source.ServiceId
                );
        }
    }
}
