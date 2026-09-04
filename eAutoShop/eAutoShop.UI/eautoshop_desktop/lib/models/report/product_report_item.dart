class ProductReportItem {
  final int productId;
  final String productName;
  final String category;
  final double price;
  final double discount;
  final double discountedPrice;
  final int totalSold;
  final double totalRevenue;

  const ProductReportItem({
    required this.productId,
    required this.productName,
    required this.category,
    required this.price,
    required this.discount,
    required this.discountedPrice,
    required this.totalSold,
    required this.totalRevenue,
  });
}
