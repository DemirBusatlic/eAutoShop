import 'report_request.dart';

class ProductReportRequest extends ReportRequest {
  final int? productCategoryId;
  final int? productId;

  const ProductReportRequest({
    super.username,
    super.role,
    super.startDate,
    super.endDate,
    this.productCategoryId,
    this.productId,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      ...super.toJson(),
      'productCategoryId': productCategoryId,
      'productId': productId,
    };
  }
}
