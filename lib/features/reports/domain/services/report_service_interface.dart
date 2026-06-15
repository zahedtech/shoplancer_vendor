import 'package:shoplancer_vendor/features/reports/domain/models/expense_model.dart';
import 'package:shoplancer_vendor/features/reports/domain/models/tax_report_model.dart';

abstract class ReportServiceInterface {
  Future<ExpenseBodyModel?> getExpenseList({
    required int offset,
    required int? restaurantId,
    required String? from,
    required String? to,
    required String? searchText,
  });
  Future<TaxReportModel?> getTaxReport({
    required int offset,
    required String? from,
    required String? to,
  });
}
