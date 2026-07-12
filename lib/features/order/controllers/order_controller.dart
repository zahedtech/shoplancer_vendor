import 'package:image_picker/image_picker.dart';
import 'package:shoplancer_vendor/common/models/response_model.dart';
import 'package:shoplancer_vendor/features/profile/controllers/profile_controller.dart';
import 'package:shoplancer_vendor/features/splash/controllers/splash_controller.dart';
import 'package:shoplancer_vendor/api/api_client.dart';
import 'package:shoplancer_vendor/features/order/domain/models/update_status_body_model.dart';
import 'package:shoplancer_vendor/features/order/domain/models/order_cancellation_body_model.dart';
import 'package:shoplancer_vendor/features/order/domain/models/order_details_model.dart';
import 'package:shoplancer_vendor/features/order/domain/models/order_model.dart';
import 'package:shoplancer_vendor/features/order/domain/models/running_order_model.dart';
import 'package:shoplancer_vendor/common/widgets/custom_snackbar_widget.dart';
import 'package:get/get.dart';
import 'package:shoplancer_vendor/features/order/domain/services/order_service_interface.dart';
import 'package:shoplancer_vendor/helper/route_helper.dart';
import 'package:shoplancer_vendor/util/app_constants.dart';

class OrderController extends GetxController implements GetxService {
  final OrderServiceInterface orderServiceInterface;
  OrderController({required this.orderServiceInterface});

  List<OrderModel>? _orderList;
  List<OrderModel>? get orderList => _orderList;

  List<OrderModel>? _runningOrderList;
  List<OrderModel>? get runningOrderList => _runningOrderList;

  List<RunningOrderModel>? _runningOrders;
  List<RunningOrderModel>? get runningOrders => _runningOrders;

  List<OrderModel>? _historyOrderList;
  List<OrderModel>? get historyOrderList => _historyOrderList;

  List<OrderDetailsModel>? _orderDetailsModel;
  List<OrderDetailsModel>? get orderDetailsModel => _orderDetailsModel;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  int _orderIndex = 0;
  int get orderIndex => _orderIndex;

  bool _campaignOnly = false;
  bool get campaignOnly => _campaignOnly;

  String _runningOrderSort = 'latest';
  String get runningOrderSort => _runningOrderSort;

  String _otp = '';
  String get otp => _otp;

  int _historyIndex = 0;
  int get historyIndex => _historyIndex;

  final List<String> _statusList = ['all', 'delivered', 'refunded'];
  List<String> get statusList => _statusList;

  bool _paginate = false;
  bool get paginate => _paginate;

  int? _pageSize;
  int? get pageSize => _pageSize;

  List<int> _offsetList = [];

  int _offset = 1;
  int get offset => _offset;

  String _orderType = 'all';
  String get orderType => _orderType;

  OrderModel? _orderModel;
  OrderModel? get orderModel => _orderModel;

  List<Data>? _orderCancelReasons;
  List<Data>? get orderCancelReasons => _orderCancelReasons;

  String? _cancelReason = '';
  String? get cancelReason => _cancelReason;

  bool _showDeliveryImageField = false;
  bool get showDeliveryImageField => _showDeliveryImageField;

  List<XFile> _pickedPrescriptions = [];
  List<XFile> get pickedPrescriptions => _pickedPrescriptions;

  bool _hideNotificationButton = false;
  bool get hideNotificationButton => _hideNotificationButton;

  final Map<int, List<int>> _checklistMap = {};
  Map<int, List<int>> get checklistMap => _checklistMap;

  void toggleItemCheck(int orderId, int orderDetailsId) {
    if (_checklistMap.containsKey(orderId)) {
      if (_checklistMap[orderId]!.contains(orderDetailsId)) {
        _checklistMap[orderId]!.remove(orderDetailsId);
      } else {
        _checklistMap[orderId]!.add(orderDetailsId);
      }
    } else {
      _checklistMap[orderId] = [orderDetailsId];
    }
    update();
  }

  bool isItemChecked(int orderId, int orderDetailsId) {
    return _checklistMap.containsKey(orderId) &&
        _checklistMap[orderId]!.contains(orderDetailsId);
  }

  bool isOrderChecklistComplete(int orderId) {
    if (_orderDetailsModel == null || _orderDetailsModel!.isEmpty) return false;
    if (!_checklistMap.containsKey(orderId)) return false;

    for (var item in _orderDetailsModel!) {
      if (!_checklistMap[orderId]!.contains(item.id)) {
        return false;
      }
    }
    return true;
  }

  Future<bool> sendDeliveredNotification(int? orderID) async {
    _hideNotificationButton = true;
    update();
    bool isSuccess = await orderServiceInterface.sendDeliveredNotification(
      orderID,
    );
    _hideNotificationButton = false;
    update();
    return isSuccess;
  }

  void changeDeliveryImageStatus({bool isUpdate = true}) {
    _showDeliveryImageField = !_showDeliveryImageField;
    if (isUpdate) {
      update();
    }
  }

  void pickPrescriptionImage({
    required bool isRemove,
    required bool isCamera,
  }) async {
    if (isRemove) {
      _pickedPrescriptions = [];
    } else {
      XFile? xFile = await ImagePicker().pickImage(
        source: isCamera ? ImageSource.camera : ImageSource.gallery,
        imageQuality: 50,
      );
      if (xFile != null) {
        _pickedPrescriptions.add(xFile);
        if (Get.isDialogOpen!) {
          Get.back();
        }
      }
      update();
    }
  }

  void removePrescriptionImage(int index) {
    _pickedPrescriptions.removeAt(index);
    update();
  }

  void setOrderCancelReason(String? reason) {
    _cancelReason = reason;
    update();
  }

  Future<void> getOrderCancelReasons() async {
    OrderCancellationBodyModel? orderCancellationBody =
        await orderServiceInterface.getCancelReasons();
    if (orderCancellationBody != null) {
      _orderCancelReasons = [];
      for (var element in orderCancellationBody.data!) {
        _orderCancelReasons!.add(element);
      }
    }
    update();
  }

  void clearPreviousData() {
    _orderDetailsModel = null;
    _orderModel = null;
  }

  Future<void> getOrderDetails(int orderId) async {
    OrderModel? orderModel = await orderServiceInterface.getOrderWithId(
      orderId,
    );
    if (orderModel != null) {
      _orderModel = orderModel;
    }
    update();
  }

  Future<void> getCurrentOrders() async {
    List<OrderModel>? runningOrderList = await orderServiceInterface
        .getCurrentOrders();
    if (runningOrderList != null) {
      _runningOrderList = [];
      bool isGrocery = Get.find<SplashController>().moduleType == 'grocery';
      if (isGrocery) {
        _runningOrders = [
          RunningOrderModel(status: 'pending', orderList: []),
          RunningOrderModel(status: 'ready_for_handover', orderList: []),
          RunningOrderModel(status: 'food_on_the_way', orderList: []),
        ];
      } else {
        _runningOrders = [
          RunningOrderModel(status: 'pending', orderList: []),
          RunningOrderModel(status: 'confirmed', orderList: []),
          RunningOrderModel(
            status:
                Get.find<SplashController>()
                    .configModel!
                    .moduleConfig!
                    .module!
                    .showRestaurantText!
                ? 'cooking'
                : 'processing',
            orderList: [],
          ),
          RunningOrderModel(status: 'ready_for_handover', orderList: []),
          RunningOrderModel(status: 'food_on_the_way', orderList: []),
        ];
      }
      _runningOrderList!.addAll(runningOrderList);
      _campaignOnly = true;
      _orderIndex = 0;
      toggleCampaignOnly();
    }
    update();
  }

  Future<void> getPaginatedOrders(int offset, bool reload) async {
    if (offset == 1 || reload) {
      _offsetList = [];
      _offset = 1;
      if (reload) {
        _historyOrderList = null;
      }
      update();
    }
    if (!_offsetList.contains(offset)) {
      _offsetList.add(offset);
      PaginatedOrderModel? historyOrderModel = await orderServiceInterface
          .getPaginatedOrderList(offset, _statusList[_historyIndex]);
      if (historyOrderModel != null) {
        if (offset == 1) {
          _historyOrderList = [];
        }
        _historyOrderList!.addAll(historyOrderModel.orders!);
        _pageSize = historyOrderModel.totalSize;
        _paginate = false;
        update();
      }
    } else {
      if (_paginate) {
        _paginate = false;
        update();
      }
    }
  }

  void showBottomLoader() {
    _paginate = true;
    update();
  }

  void setOffset(int offset) {
    _offset = offset;
  }

  void setOrderType(String type) {
    _orderType = type;
    getPaginatedOrders(1, true);
  }

  void setRunningOrderSort(String sort) {
    _runningOrderSort = sort;
    _sortRunningOrderGroups();
    update();
  }

  Future<bool> updateOrderStatus(
    int? orderID,
    String status, {
    bool back = false,
    String? reason,
    String? processingTime,
    bool fromNotification = false,
    String? externalDeliveryManName,
  }) async {
    if (status != 'canceled' && status != 'failed' && status != 'refunded') {
      if (_orderDetailsModel != null &&
          _orderDetailsModel!.isNotEmpty &&
          _orderDetailsModel!.first.orderId == orderID) {
        if (!isOrderChecklistComplete(orderID ?? 0)) {
          showCustomSnackBar(
            'check_all_items_before_updating_status'.tr,
            isError: true,
          );
          return false;
        }
      }
    }

    _isLoading = true;
    update();
    List<MultipartBody> pickedPrescriptions = orderServiceInterface
        .processMultipartData(_pickedPrescriptions);
    UpdateStatusBodyModel updateStatusBody = UpdateStatusBodyModel(
      orderId: orderID,
      status: status,
      otp: status == 'delivered' ? _otp : null,
      processingTime: processingTime,
      reason: reason,
      externalDeliveryManName: externalDeliveryManName,
    );
    ResponseModel responseModel = await orderServiceInterface.updateOrderStatus(
      updateStatusBody,
      pickedPrescriptions,
    );
    // Only close dialog if one is open (like confirmation dialogs)
    if (Get.isDialogOpen == true) {
      Get.back(result: responseModel.isSuccess);
    }
    if (responseModel.isSuccess) {
      if (status == 'picked_up' || status == AppConstants.pickedUp) {
        Get.offAllNamed(RouteHelper.getInitialRoute());
      } else {
        if (back && fromNotification) {
          Get.offAllNamed(RouteHelper.getInitialRoute());
        } else if (back && !fromNotification) {
          Get.back();
        }
        if (orderID != null && !back) {
          await getOrderDetails(orderID);
        }
      }
      getCurrentOrders();
      Get.find<ProfileController>().getProfile();
      showCustomSnackBar('order_status_updated'.tr, isError: false);
    } else {
      showCustomSnackBar(responseModel.message?.tr, isError: true);
    }
    _isLoading = false;
    update();
    return responseModel.isSuccess;
  }

  Future<bool> updateOrderAmount(
    int orderID,
    String amount,
    bool isItemPrice,
  ) async {
    _isLoading = true;
    update();
    Map<String, String> body = <String, String>{};
    if (isItemPrice) {
      body['_method'] = 'PUT';
      body['order_id'] = orderID.toString();
      body['order_amount'] = amount;
    } else {
      body['_method'] = 'PUT';
      body['order_id'] = orderID.toString();
      body['discount_amount'] = amount;
    }
    ResponseModel responseModel = await orderServiceInterface.updateOrderAmount(
      body,
    );
    if (responseModel.isSuccess) {
      await getOrderDetails(orderID);
      Get.back();
      showCustomSnackBar(responseModel.message, isError: false);
    } else {
      showCustomSnackBar(responseModel.message, isError: true);
    }
    _isLoading = false;
    update();
    return responseModel.isSuccess;
  }

  Future<bool> updateOrderItems(Map<String, dynamic> body) async {
    _isLoading = true;
    update();

    ResponseModel responseModel = await orderServiceInterface.updateOrderItems(
      body,
    );

    if (responseModel.isSuccess) {
      await getOrderDetails(body['order_id']);
      await getOrderItemsDetails(body['order_id']);
      showCustomSnackBar(responseModel.message, isError: false);
    } else {
      showCustomSnackBar(responseModel.message, isError: true);
    }

    _isLoading = false;
    update();
    return responseModel.isSuccess;
  }

  Future<void> getOrderItemsDetails(int orderID) async {
    _orderDetailsModel = null;
    if (_orderModel != null && !_orderModel!.prescriptionOrder!) {
      List<OrderDetailsModel>? orderDetailsModel = await orderServiceInterface
          .getOrderDetails(orderID);
      if (orderDetailsModel != null) {
        _orderDetailsModel = [];
        _orderDetailsModel!.addAll(orderDetailsModel);
      }
      update();
    } else {
      _orderDetailsModel = [];
    }
  }

  void setOrderIndex(int index) {
    _orderIndex = index;
    update();
  }

  void _sortRunningOrderGroups() {
    if (_runningOrders == null) {
      return;
    }

    for (final RunningOrderModel runningOrder in _runningOrders!) {
      runningOrder.orderList.sort((first, second) {
        final int comparison = _runningOrderSort == 'latest'
            ? _orderTime(second).compareTo(_orderTime(first))
            : _orderTime(first).compareTo(_orderTime(second));

        if (comparison != 0) {
          return comparison;
        }

        return _runningOrderSort == 'latest'
            ? (second.id ?? 0).compareTo(first.id ?? 0)
            : (first.id ?? 0).compareTo(second.id ?? 0);
      });
    }
  }

  DateTime _orderTime(OrderModel order) {
    return DateTime.tryParse(order.createdAt ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(order.id ?? 0);
  }

  void toggleCampaignOnly() {
    _campaignOnly = !_campaignOnly;
    bool isGrocery = Get.find<SplashController>().moduleType == 'grocery';

    for (int i = 0; i < _runningOrders!.length; i++) {
      _runningOrders![i].orderList = [];
    }

    for (var order in _runningOrderList!) {
      if (isGrocery) {
        if ((order.orderStatus == 'pending' ||
                order.orderStatus == 'confirmed' ||
                order.orderStatus == 'processing' ||
                (order.orderStatus == 'accepted' && order.confirmed != null)) &&
            (Get.find<SplashController>().configModel!.orderConfirmationModel !=
                    'deliveryman' ||
                order.orderType == 'take_away' ||
                Get.find<ProfileController>()
                        .profileModel!
                        .stores![0]
                        .selfDeliverySystem ==
                    1) &&
            (_campaignOnly ? order.itemCampaign == 1 : true)) {
          _runningOrders![0].orderList.add(order);
        } else if (order.orderStatus == 'handover' &&
            (_campaignOnly ? order.itemCampaign == 1 : true)) {
          _runningOrders![1].orderList.add(order);
        } else if (order.orderStatus == 'picked_up' &&
            (_campaignOnly ? order.itemCampaign == 1 : true)) {
          _runningOrders![2].orderList.add(order);
        }
      } else {
        if (order.orderStatus == 'pending' &&
            (Get.find<SplashController>().configModel!.orderConfirmationModel !=
                    'deliveryman' ||
                order.orderType == 'take_away' ||
                Get.find<ProfileController>()
                        .profileModel!
                        .stores![0]
                        .selfDeliverySystem ==
                    1) &&
            (_campaignOnly ? order.itemCampaign == 1 : true)) {
          _runningOrders![0].orderList.add(order);
        } else if ((order.orderStatus == 'confirmed' ||
                (order.orderStatus == 'accepted' && order.confirmed != null)) &&
            (_campaignOnly ? order.itemCampaign == 1 : true)) {
          _runningOrders![1].orderList.add(order);
        } else if (order.orderStatus == 'processing' &&
            (_campaignOnly ? order.itemCampaign == 1 : true)) {
          _runningOrders![2].orderList.add(order);
        } else if (order.orderStatus == 'handover' &&
            (_campaignOnly ? order.itemCampaign == 1 : true)) {
          _runningOrders![3].orderList.add(order);
        } else if (order.orderStatus == 'picked_up' &&
            (_campaignOnly ? order.itemCampaign == 1 : true)) {
          _runningOrders![4].orderList.add(order);
        }
      }
    }
    _sortRunningOrderGroups();
    update();
  }

  void setOtp(String otp) {
    _otp = otp;
    if (otp != '') {
      update();
    }
  }

  void setHistoryIndex(int index) {
    _historyIndex = index;
    getPaginatedOrders(offset, true);
    update();
  }

  String? getBluetoothMacAddress() =>
      orderServiceInterface.getBluetoothAddress();

  void setBluetoothMacAddress(String? address) =>
      orderServiceInterface.setBluetoothAddress(address);
}
