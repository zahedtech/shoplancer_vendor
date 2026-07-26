import 'package:image_picker/image_picker.dart';
import 'package:shoplancer_vendor/api/api_client.dart';
import 'package:shoplancer_vendor/common/models/response_model.dart';
import 'package:shoplancer_vendor/features/order/domain/models/order_cancellation_body_model.dart';
import 'package:shoplancer_vendor/features/order/domain/models/order_details_model.dart';
import 'package:shoplancer_vendor/features/order/domain/models/order_model.dart';
import 'package:shoplancer_vendor/features/order/domain/models/update_status_body_model.dart';

abstract class OrderServiceInterface {
  Future<List<OrderModel>?> getCurrentOrders();
  Future<PaginatedOrderModel?> getPaginatedOrderList(int offset, String status, {String? from, String? to});
  Future<ResponseModel> updateOrderStatus(UpdateStatusBodyModel updateStatusBody, List<MultipartBody> proofAttachment);
  Future<List<OrderDetailsModel>?> getOrderDetails(int orderID);
  Future<OrderModel?> getOrderWithId(int orderId);
  Future<ResponseModel> updateOrderAmount(Map<String, String> body);
  Future<ResponseModel> updateOrderItems(Map<String, dynamic> body);
  Future<OrderCancellationBodyModel?> getCancelReasons();
  Future<bool> sendDeliveredNotification(int? orderID);
  List<MultipartBody> processMultipartData(List<XFile> pickedPrescriptions);
  Future<void> setBluetoothAddress(String? address);
  String? getBluetoothAddress();
}