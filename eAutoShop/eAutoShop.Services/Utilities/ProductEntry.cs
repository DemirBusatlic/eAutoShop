using Microsoft.ML.Data;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace eAutoShop.Services.Utilities
{
    public class ProductEntry
    {
        [KeyType(count: 1000)]
        public uint ProductId { get; set; }

        [KeyType(count: 1000)]
        public uint CoPurchaseProductId { get; set; }

        public float Label { get; set; }
    }
}
