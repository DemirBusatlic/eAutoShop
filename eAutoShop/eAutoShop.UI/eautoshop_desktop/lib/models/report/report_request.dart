class ReportRequest {
  final String? username;
  final String? role;
  final DateTime? startDate;
  final DateTime? endDate;

  const ReportRequest({this.username, this.role, this.startDate, this.endDate});

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'role': role,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
    };
  }
}
