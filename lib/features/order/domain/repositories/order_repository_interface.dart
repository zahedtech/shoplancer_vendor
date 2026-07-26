import 'package:shoplancer_vendor/api/api_client.dart';
import 'package:shoplancer_vendor/features/order/domain/models/update_status_body_model.dart';
import 'package:shoplancer_vendor/interface/repository_interface.dart';

abstract class OrderRepositoryInterface implements RepositoryInterface {
  Future<dynamic> getPaginatedOrderList(int offset, String status, {String? from, String? to});
  Future<dynamic> updateOrderStatus(UpdateStatusBodyModel updateStatusBody, List<MultipartBody> proofAttachment);
  Future<dynamic> getOrderDetails(int orderID);
  Future<dynamic> getCancelReasons();
  Future<dynamic> sendDeliveredNotification(int? orderID);
  Future<void> setBluetoothAddress(String? address);
  String? getBluetoothAddress();
  Future<dynamic> updateOrderItems(Map<String, dynamic> body);
}