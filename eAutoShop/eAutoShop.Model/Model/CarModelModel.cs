using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations.Schema;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace eAutoShop.Model.Model
{
    public class CarModelModel
    {
        public int Id { get; set; }
        public string Name { get; set; }
        public string ModelYear { get; set; }
    }
}
