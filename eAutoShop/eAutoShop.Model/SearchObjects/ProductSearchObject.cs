using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;


namespace eAutoShop.Model.SearchObjects
{
    public class ProductSearchObject : BaseSearchObject
    {
        public string? Starts { get; set; }
        public string? Contains { get; set; }
        public bool? WithDiscount { get; set; }
        public string? State { get; set; }
        public int? ProductCategoryId { get; set; }
        public int? CarManufacturerId { get; set; }
        public List<int>? CarModelIds { get; set; }
    }
}
