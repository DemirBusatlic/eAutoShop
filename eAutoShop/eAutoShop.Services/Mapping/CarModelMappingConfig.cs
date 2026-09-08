using eAutoShop.Model.Model;
using eAutoShop.Services.Database;
using Mapster;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace eAutoShop.Services.Mapping
{
    public class CarModelMappingConfig : IRegister
    {
        public void Register(TypeAdapterConfig config)
        {
            config.NewConfig<CarModel, CarModelModel>()
                .Map(
                    destination => destination.CarManufacturerName,
                    source => source.CarManufacturer.Name);
        }
    }
}
