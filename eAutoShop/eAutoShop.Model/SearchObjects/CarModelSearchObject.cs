using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace eAutoShop.Model.SearchObjects
{
    public class CarModelSearchObject : BaseSearchObject
    {
        public string? Name { get; set; }

        public int? CarManufacturerId { get; set; }
    }
}
