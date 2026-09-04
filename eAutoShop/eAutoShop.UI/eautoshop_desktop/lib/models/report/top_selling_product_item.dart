class TopSellingProductItem {
  final int productId;
  final String productName;
  final String category;
  final int totalSold;
  final double totalRevenue;

  const TopSellingProductItem({
    required this.productId,
    required this.productName,
    required this.category,
    required this.totalSold,
    required this.totalRevenue,
  });
}
