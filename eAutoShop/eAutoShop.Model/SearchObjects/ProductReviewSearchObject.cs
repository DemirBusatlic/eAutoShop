using System;
using System.Collections.Generic;
using System.Text;

namespace eAutoShop.Model.SearchObjects
{
    public class ProductReviewSearchObject : BaseSearchObject
    {
        public int? Rating { get; set; }

        public int? UserId { get; set; }

        public int? ProductId { get; set; }

        public int? OrderItemId { get; set; }

        public string? CommentFTS { get; set; }
    }
}
