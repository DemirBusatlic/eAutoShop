class TopCustomerItem {
  final int customerId;
  final String username;
  final String customerName;
  final int ordersCount;
  final double totalSpent;

  const TopCustomerItem({
    required this.customerId,
    required this.username,
    required this.customerName,
    required this.ordersCount,
    required this.totalSpent,
  });
}
