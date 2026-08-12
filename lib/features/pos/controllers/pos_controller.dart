import 'package:get/get.dart';
import 'package:shoplancer_vendor/api/api_checker.dart';
import 'package:shoplancer_vendor/common/widgets/custom_snackbar_widget.dart';
import 'package:shoplancer_vendor/features/pos/data/local/pos_local_db.dart';
import 'package:shoplancer_vendor/features/pos/data/local/pos_offline_repository.dart';
import 'package:shoplancer_vendor/features/pos/data/local/pos_sync_service.dart';
import 'package:shoplancer_vendor/features/pos/domain/models/pos_cart_model.dart';
import 'package:shoplancer_vendor/features/pos/domain/models/pos_customer_model.dart';
import 'package:shoplancer_vendor/features/pos/domain/services/pos_service_interface.dart';
import 'package:shoplancer_vendor/features/profile/controllers/profile_controller.dart';
import 'package:shoplancer_vendor/features/profile/domain/models/profile_model.dart';
import 'package:shoplancer_vendor/features/store/domain/models/item_model.dart';
import 'package:shoplancer_vendor/util/app_constants.dart';

/// A snapshot of an in-progress order that was set aside ("held") so the
/// cashier could start a new order without losing it — e.g. a customer
/// steps away mid-order. Shown in the desktop sidebar to resume later.
class PosHeldOrder {
  final String id;
  final DateTime heldAt;
  final List<PosCartModel> cartList;
  final PosCustomerModel? customer;
  final String orderType;
  final String paymentMethod;
  final String paymentStatus;
  final double discountAmount;
  final double couponDiscountAmount;
  final String? couponCode;
  final double deliveryCharge;
  final String? label;

  PosHeldOrder({
    required this.id,
    required this.heldAt,
    required this.cartList,
    required this.customer,
    required this.orderType,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.discountAmount,
    required this.couponDiscountAmount,
    required this.couponCode,
    required this.deliveryCharge,
    this.label,
  });

  double get total {
    double t = 0;
    for (final c in cartList) {
      t += c.price * c.quantity;
      if (c.addOns != null) {
        for (final a in c.addOns!) {
          t += (a.price ?? 0);
        }
      }
    }
    t =
        t -
        discountAmount -
        couponDiscountAmount +
        (orderType == 'delivery' ? deliveryCharge : 0);
    return t < 0 ? 0 : t;
  }
}

class PosController extends GetxController implements GetxService {
  final PosServiceInterface posServiceInterface;
  PosController({required this.posServiceInterface});

  final List<PosCartModel> _cartList = [];
  List<PosCartModel> get cartList => _cartList;

  List<PosCustomerModel>? _customerList;
  List<PosCustomerModel>? get customerList => _customerList;

  PosCustomerModel? _selectedCustomer;
  PosCustomerModel? get selectedCustomer => _selectedCustomer;

  String _orderType = 'take_away'; // delivery | take_away | dine_in
  String get orderType => _orderType;

  String _paymentMethod =
      'cash_on_delivery'; // cash_on_delivery | digital_payment | card | wallet
  String get paymentMethod => _paymentMethod;

  String _paymentStatus = 'unpaid'; // paid | unpaid
  String get paymentStatus => _paymentStatus;

  double _discountAmount = 0.0;
  double get discountAmount => _discountAmount;

  double _couponDiscountAmount = 0.0;
  double get couponDiscountAmount => _couponDiscountAmount;

  String? _couponCode;
  String? get couponCode => _couponCode;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // ---- Held ("parked") orders ------------------------------------------
  // Lets the cashier start a fresh order without losing the current one:
  // hold it, work on the new order, and come back to any held order later.
  final List<PosHeldOrder> _heldOrders = [];
  List<PosHeldOrder> get heldOrders => _heldOrders;
  int _heldOrderCounter = 0;

  /// Sets the current in-progress order aside and clears the active cart so
  /// a brand new order can be started. Returns false (and shows a message)
  /// if there is nothing to hold.
  bool holdCurrentOrderAndStartNew() {
    if (_cartList.isEmpty) {
      showCustomSnackBar('السلة فارغة، لا يوجد طلب لتعليقه'.tr);
      return false;
    }
    _heldOrderCounter++;
    _heldOrders.add(
      PosHeldOrder(
        id: 'held_${DateTime.now().microsecondsSinceEpoch}',
        heldAt: DateTime.now(),
        cartList: List<PosCartModel>.from(_cartList),
        customer: _selectedCustomer,
        orderType: _orderType,
        paymentMethod: _paymentMethod,
        paymentStatus: _paymentStatus,
        discountAmount: _discountAmount,
        couponDiscountAmount: _couponDiscountAmount,
        couponCode: _couponCode,
        deliveryCharge: _deliveryCharge,
        label: 'طلب معلّق $_heldOrderCounter',
      ),
    );
    _startFreshOrderState();
    showCustomSnackBar(
      'تم تعليق الطلب، يمكنك استئنافه لاحقًا'.tr,
      isError: false,
    );
    update();
    return true;
  }

  /// Restores a held order as the active one. If there is already an
  /// unsaved order in progress, it is held first so nothing is lost.
  void resumeHeldOrder(String heldOrderId) {
    final int index = _heldOrders.indexWhere((o) => o.id == heldOrderId);
    if (index == -1) return;

    if (_cartList.isNotEmpty) {
      holdCurrentOrderAndStartNew();
    }

    final PosHeldOrder held = _heldOrders.removeAt(index);
    _cartList
      ..clear()
      ..addAll(held.cartList);
    _selectedCustomer = held.customer;
    _orderType = held.orderType;
    _paymentMethod = held.paymentMethod;
    _paymentStatus = held.paymentStatus;
    _discountAmount = held.discountAmount;
    _couponDiscountAmount = held.couponDiscountAmount;
    _couponCode = held.couponCode;
    _deliveryCharge = held.deliveryCharge;
    update();
  }

  void deleteHeldOrder(String heldOrderId) {
    _heldOrders.removeWhere((o) => o.id == heldOrderId);
    update();
  }

  /// Resets the active-order fields without touching the held-orders list.
  void _startFreshOrderState() {
    _cartList.clear();
    _discountAmount = 0.0;
    _couponDiscountAmount = 0.0;
    _couponCode = null;
    _selectedCustomer = null;
    // Deliberately NOT resetting _deliveryCharge: the same delivery fee
    // commonly applies to the next order too, so it's kept until the
    // cashier changes it.
  }

  double _deliveryCharge = 0.0;
  double get deliveryCharge => _deliveryCharge;

  void setDeliveryCharge(double charge) {
    _deliveryCharge = charge;
    update();
  }

  void setOrderType(String type) {
    _orderType = type;
    update();
  }

  void setPaymentMethod(String method) {
    _paymentMethod = method;
    update();
  }

  void setPaymentStatus(String status) {
    _paymentStatus = status;
    update();
  }

  void setDiscount(double amount) {
    _discountAmount = amount;
    update();
  }

  void addToCart(
    Item item, {
    int quantity = 1,
    List<AddOns>? addOns,
    String? selectedVariant,
  }) {
    int index = _cartList.indexWhere((element) => element.item.id == item.id);
    double itemPrice = item.price ?? 0.0;
    double itemDiscount = item.discount ?? 0.0;

    if (index != -1) {
      _cartList[index].quantity += quantity;
    } else {
      _cartList.add(
        PosCartModel(
          item: item,
          price: itemPrice,
          discountAmount: itemDiscount,
          quantity: quantity,
          addOns: addOns,
          selectedVariant: selectedVariant,
        ),
      );
    }
    showCustomSnackBar('تم إضافة ${item.name} إلى السلة'.tr, isError: false);
    update();
  }

  void updateQuantity(int index, bool isIncrement) {
    if (isIncrement) {
      _cartList[index].quantity++;
    } else {
      if (_cartList[index].quantity > 1) {
        _cartList[index].quantity--;
      } else {
        _cartList.removeAt(index);
      }
    }
    update();
  }

  void removeFromCart(int index) {
    _cartList.removeAt(index);
    update();
  }

  void clearCart() {
    _startFreshOrderState();
    update();
  }

  double get subTotal {
    double total = 0;
    for (var cart in _cartList) {
      total += (cart.price * cart.quantity);
      if (cart.addOns != null) {
        for (var addon in cart.addOns!) {
          total += (addon.price ?? 0);
        }
      }
    }
    return total;
  }

  double get grandTotal {
    double deliveryFee = _orderType == 'delivery' ? _deliveryCharge : 0.0;
    double total =
        subTotal - _discountAmount - _couponDiscountAmount + deliveryFee;
    return total < 0 ? 0 : total;
  }

  Future<void> searchCustomers(String search) async {
    if (search.trim().isEmpty) return;
    _customerList = await posServiceInterface.searchCustomers(search);
    update();
  }

  void selectCustomer(PosCustomerModel? customer) {
    _selectedCustomer = customer;
    update();
  }

  bool _isCustomerLoading = false;
  bool get isCustomerLoading => _isCustomerLoading;

  Future<bool> addCustomer(
    String fName,
    String lName,
    String phone,
    String? email,
  ) async {
    _isCustomerLoading = true;
    update();

    PosCustomerModel customer = PosCustomerModel(
      fName: fName,
      lName: lName,
      phone: phone,
      email: email,
    );
    Response response = await posServiceInterface.addCustomer(customer);
    _isCustomerLoading = false;

    if ((response.statusCode == 200 || response.statusCode == 201) &&
        response.body != null) {
      if (response.body is Map && response.body['status'] == false) {
        showCustomSnackBar(
          response.body['message'] ?? 'فشلت إضافة العميل'.tr,
          isError: true,
        );
        update();
        return false;
      }

      String message = 'تم إضافة العميل بنجاح'.tr;
      if (response.body is Map && response.body['message'] != null) {
        message = response.body['message'];
      }

      showCustomSnackBar(message, isError: false);

      if (response.body is Map && response.body['data'] != null) {
        PosCustomerModel createdCustomer = PosCustomerModel.fromJson(
          response.body['data'],
        );
        selectCustomer(createdCustomer);
      } else if (response.body is Map && response.body['id'] != null) {
        customer.id = response.body['id'];
        selectCustomer(customer);
      } else {
        selectCustomer(customer);
      }

      update();
      return true;
    } else {
      ApiChecker.checkApi(response);
      update();
      return false;
    }
  }

  Future<bool> applyCoupon(String code) async {
    if (_cartList.isEmpty) {
      showCustomSnackBar('السلة فارغة'.tr);
      return false;
    }
    _isLoading = true;
    update();
    Response response = await posServiceInterface.applyCoupon(
      code,
      _selectedCustomer?.id,
      subTotal,
    );
    _isLoading = false;
    if (response.statusCode == 200 && response.body != null) {
      _couponCode = code;
      _couponDiscountAmount =
          double.tryParse(response.body['discount'].toString()) ?? 0.0;
      showCustomSnackBar('تم تطبيق الكوبون بنجاح'.tr, isError: false);
      update();
      return true;
    } else {
      ApiChecker.checkApi(response);
      update();
      return false;
    }
  }

  Future<bool> placeOrder({
    String? address,
    String? note,
    String? house,
    String? floor,
  }) async {
    if (_cartList.isEmpty) {
      showCustomSnackBar('السلة فارغة، أضف منتجات أولاً'.tr);
      return false;
    }
    if (_orderType == 'delivery' &&
        (address == null || address.trim().isEmpty)) {
      showCustomSnackBar('يرجى كتابة عنوان التوصيل'.tr);
      return false;
    }

    _isLoading = true;
    update();

    List<Map<String, dynamic>> cartPayload = [];
    for (var cart in _cartList) {
      List<Map<String, dynamic>> addOnsList = [];
      if (cart.addOns != null) {
        for (var addOn in cart.addOns!) {
          addOnsList.add({'id': addOn.id, 'quantity': 1, 'price': addOn.price});
        }
      }

      cartPayload.add({
        'item_id': cart.item.id,
        'item_type': 'Item',
        'price': cart.price,
        'quantity': cart.quantity,
        'variant': cart.selectedVariant,
        'add_ons': addOnsList,
      });
    }

    // Append house and floor to address for safety
    String finalAddress = address ?? '';
    if (house != null && house.trim().isNotEmpty) {
      finalAddress += ', عمارة: $house';
    }
    if (floor != null && floor.trim().isNotEmpty) {
      finalAddress += ', شقة: $floor';
    }

    ProfileModel? profile = Get.isRegistered<ProfileController>()
        ? Get.find<ProfileController>().profileModel
        : null;
    String? creatorName = profile != null
        ? '${profile.fName ?? ''} ${profile.lName ?? ''}'.trim()
        : null;
    int? creatorId = profile?.employeeInfo?.id ?? profile?.id;
    bool isEmployee = profile?.employeeInfo != null;

    Map<String, dynamic> body = {
      'customer_id': _selectedCustomer?.id,
      'order_type': _orderType,
      'payment_method': _paymentMethod,
      'payment_status': _paymentStatus,
      'order_amount': grandTotal,
      'discount_amount': _discountAmount,
      'coupon_discount_amount': _couponDiscountAmount,
      'delivery_charge': _orderType == 'delivery' ? _deliveryCharge : 0.0,
      'coupon_code': _couponCode,
      'address': finalAddress,
      'house': house,
      'floor': floor,
      'order_note': note,
      'cart': cartPayload,
      'created_by': creatorId,
      'creator_type': isEmployee ? 'employee' : 'vendor',
      'creator_name': (creatorName != null && creatorName.isNotEmpty)
          ? creatorName
          : null,
      'created_by_name': (creatorName != null && creatorName.isNotEmpty)
          ? creatorName
          : null,
      'employee_id': profile?.employeeInfo?.id,
      'seller_id': profile?.id,
    };

    Response response = await posServiceInterface.placeOrder(body);
    _isLoading = false;

    if ((response.statusCode == 200 || response.statusCode == 201) &&
        response.body != null) {
      if (response.body is Map && response.body['status'] == false) {
        showCustomSnackBar(
          response.body['message'] ?? 'فشلت عملية إنشاء الطلب'.tr,
          isError: true,
        );
        update();
        return false;
      }

      String message =
          (response.body is Map && response.body['message'] != null)
          ? response.body['message']
          : 'تم تقديم الطلب بنجاح'.tr;

      showCustomSnackBar(message, isError: false);
      clearCart();
      update();
      return true;
    } else if (response.statusCode == 1 &&
        PosLocalDb.instance.isSupportedPlatform) {
      // No internet connection on desktop: queue the order locally instead
      // of losing it. It will be pushed automatically once back online.
      final String queueId = await PosOfflineRepository.instance.enqueue(
        type: PosQueueActionType.placeOrder,
        endpoint: AppConstants.placeOrderUri,
        body: body,
      );
      await PosOfflineRepository.instance.recordLocalOrder(
        queueId: queueId,
        total: grandTotal,
        itemCount: cartPayload.length,
        customerLabel: _selectedCustomer?.fullName,
      );
      if (Get.isRegistered<PosSyncService>()) {
        Get.find<PosSyncService>().syncNow();
      }
      showCustomSnackBar(
        'لا يوجد اتصال بالإنترنت، تم حفظ الطلب محلياً وسيُرسل تلقائياً عند عودة الاتصال'
            .tr,
        isError: false,
      );
      clearCart();
      update();
      return true;
    } else {
      ApiChecker.checkApi(response);
      update();
      return false;
    }
  }
}
