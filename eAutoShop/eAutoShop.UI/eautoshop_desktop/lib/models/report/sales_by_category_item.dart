class SalesByCategoryItem {
  final int categoryId;
  final String categoryName;
  final int totalSold;
  final double totalRevenue;

  const SalesByCategoryItem({
    required this.categoryId,
    required this.categoryName,
    required this.totalSold,
    required this.totalRevenue,
  });
}
