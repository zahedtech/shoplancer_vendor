import 'package:get/get_connect/http/src/response/response.dart';
import 'package:shoplancer_vendor/features/pos/domain/models/pos_customer_model.dart';
import 'package:shoplancer_vendor/features/pos/domain/repositories/pos_repository_interface.dart';
import 'package:shoplancer_vendor/features/pos/domain/services/pos_service_interface.dart';

class PosService implements PosServiceInterface {
  final PosRepositoryInterface posRepositoryInterface;
  PosService({required this.posRepositoryInterface});

  @override
  Future<List<PosCustomerModel>?> searchCustomers(String search) async {
    return await posRepositoryInterface.searchCustomers(search);
  }

  @override
  Future<Response> addCustomer(PosCustomerModel customer) async {
    return await posRepositoryInterface.addCustomer(customer);
  }

  @override
  Future<Response> applyCoupon(String code, int? customerId, double orderAmount) async {
    return await posRepositoryInterface.applyCoupon(code, customerId, orderAmount);
  }

  @override
  Future<Response> placeOrder(Map<String, dynamic> body) async {
    return await posRepositoryInterface.placeOrder(body);
  }
}
