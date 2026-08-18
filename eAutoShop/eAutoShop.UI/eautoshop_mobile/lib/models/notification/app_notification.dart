class AppNotification {
  final String type;
  final String message;

  const AppNotification({required this.type, required this.message});

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      type: json['type']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
    );
  }
}
