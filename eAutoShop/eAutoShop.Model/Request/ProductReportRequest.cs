using System;
using System.Collections.Generic;
using System.Text;

namespace eAutoShop.Model.Request
{
    public class ProductReportRequest : ReportRequest
    {
        public int? ProductCategoryId { get; set; }
        public int? ProductId { get; set; }
    }
}
