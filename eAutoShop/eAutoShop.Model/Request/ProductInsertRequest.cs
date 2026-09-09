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
        [Required, MaxLength(100)]
        public string Name { get; set; } = null!;
        [Range(0.01, double.MaxValue)]
        public double Price { get; set; }
        [Range(0, 1)]
        public double? Discount { get; set; }
        public string? ImageData { get; set; }
        [MaxLength(255)]
        public string? Description { get; set; }
        public List<int>? CarModelIds { get; set; }
        [Range(1, int.MaxValue)]
        public int? ProductCategoryId { get; set; }
    }
}

