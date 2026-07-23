using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace eAutoShop.Model.Request
{
    public class ProductInsertRequest
    {
        public string Name { get; set; }
        public double Price { get; set; }
        public double? Discount { get; set; }
        public string? ImageData { get; set; }
        public string? Description { get; set; }
        public List<int>? CarModelIds { get; set; }
        public int? ProductCategoryId { get; set; }
    }
}
