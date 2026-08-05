import 'package:get/get.dart';
import 'package:shoplancer_vendor/api/api_client.dart';
import 'package:shoplancer_vendor/features/pos/domain/models/pos_customer_model.dart';
import 'package:shoplancer_vendor/features/pos/domain/repositories/pos_repository_interface.dart';
import 'package:shoplancer_vendor/util/app_constants.dart';

class PosRepository implements PosRepositoryInterface {
  final ApiClient apiClient;
  PosRepository({required this.apiClient});

  @override
  Future<List<PosCustomerModel>?> searchCustomers(String search) async {
    Response response = await apiClient.getData('${AppConstants.searchCustomersUri}?search=$search', handleError: false);
    if ((response.statusCode == 200 || response.statusCode == 201) && response.body != null) {
      List<PosCustomerModel> list = [];
      List<dynamic> raw = response.body is List ? response.body : (response.body['data'] ?? []);
      for (var item in raw) {
        list.add(PosCustomerModel.fromJson(item));
      }
      return list;
    }
    return null;
  }

  @override
  Future<Response> addCustomer(PosCustomerModel customer) async {
    return await apiClient.postData(AppConstants.addPosCustomerUri, customer.toJson(), handleError: false);
  }

  @override
  Future<Response> applyCoupon(String code, int? customerId, double orderAmount) async {
    return await apiClient.postData(AppConstants.applyPosCouponUri, {
      'code': code,
      'customer_id': customerId,
      'order_amount': orderAmount,
    }, handleError: false);
  }

  @override
  Future<Response> placeOrder(Map<String, dynamic> body) async {
    return await apiClient.postData(AppConstants.placeOrderUri, body, handleError: false);
  }
}
