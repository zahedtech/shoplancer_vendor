import 'package:shoplancer_vendor/features/pos/domain/models/pos_customer_model.dart';

abstract class PosRepositoryInterface {
  Future<List<PosCustomerModel>?> searchCustomers(String search);
  Future<dynamic> addCustomer(PosCustomerModel customer);
  Future<dynamic> applyCoupon(String code, int? customerId, double orderAmount);
  Future<dynamic> placeOrder(Map<String, dynamic> body);
}
