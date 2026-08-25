using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace eAutoShop.Model.Model
{
    public class OrderItemModel
    {
        public int Id { get; set; }
        public int OrderId { get; set; }
        public int ProductId { get; set; }
        public string ProductName { get; set; } = null!;
        public int Quantity { get; set; }
        public double UnitPrice { get; set; }
        public double TotalItemsPrice { get; set; }
        public double TotalItemsPriceDiscounted { get; set; }
        public double Discount { get; set; }
        public bool HasProductReview { get; set; }
    }
}
