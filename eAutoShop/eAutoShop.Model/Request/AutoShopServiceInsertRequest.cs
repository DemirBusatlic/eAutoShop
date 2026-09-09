using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Text;

namespace eAutoShop.Model.Request
{
    public class AutoShopServiceInsertRequest
    {
        [Range(1, int.MaxValue)]
        public int ServiceTypeId { get; set; }

        [Required, MaxLength(100)]
        public string Name { get; set; } = null!;

        [Range(0.01, double.MaxValue)]
        public double Price { get; set; }

        [Range(0, 1)]
        public double? Discount { get; set; }

        public string? ImageData { get; set; }

        [Required, MaxLength(255)]
        public string Description { get; set; } = null!;

        [MaxLength(1000)]
        public string? Details { get; set; }

        [Required]
        public string Duration { get; set; } = null!;
    }
}
