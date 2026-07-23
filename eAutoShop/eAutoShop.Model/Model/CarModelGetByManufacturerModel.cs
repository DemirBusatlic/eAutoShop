using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace eAutoShop.Model.Model
{
    public class CarModelGetByManufacturerModel
    {
        public CarManufacturerModel Manufacturer { get; set; }
        public List<CarModelModel> Models { get; set; }
    }
}
