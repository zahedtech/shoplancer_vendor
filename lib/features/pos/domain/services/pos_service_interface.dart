import 'package:get/get_connect/http/src/response/response.dart';
import 'package:shoplancer_vendor/features/pos/domain/models/pos_customer_model.dart';

abstract class PosServiceInterface {
  Future<List<PosCustomerModel>?> searchCustomers(String search);
  Future<Response> addCustomer(PosCustomerModel customer);
  Future<Response> applyCoupon(String code, int? customerId, double orderAmount);
  Future<Response> placeOrder(Map<String, dynamic> body);
}
