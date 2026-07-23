using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace eAutoShop.Model.Model
{
    public class ProductModel
    {
        public int Id { get; set; }
        public string Name { get; set; } = null!;

        public double Price { get; set; }

        public string State { get; set; }

        public double Discount { get; set; }          
        public double DiscountedPrice { get; set; }    

        public string? ImageData { get; set; }
        public string? Details { get; set; }

        public ICollection<CarModelModel>? CarModels { get; set; }

        public int? ProductCategoryId { get; set; }
        public string? Category { get; set; }
    }
}
