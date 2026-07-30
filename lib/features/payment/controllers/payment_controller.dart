import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shoplancer_vendor/features/payment/domain/models/bank_info_body_model.dart';
import 'package:shoplancer_vendor/common/models/response_model.dart';
import 'package:shoplancer_vendor/features/payment/domain/models/offline_payment_method_model.dart';
import 'package:shoplancer_vendor/features/payment/domain/models/wallet_payment_model.dart';
import 'package:shoplancer_vendor/features/payment/domain/models/wallet_topup_request_model.dart';
import 'package:shoplancer_vendor/features/payment/domain/models/widthdrow_method_model.dart';
import 'package:shoplancer_vendor/features/payment/domain/models/withdraw_model.dart';
import 'package:shoplancer_vendor/features/profile/controllers/profile_controller.dart';
import 'package:shoplancer_vendor/util/styles.dart';
import 'package:shoplancer_vendor/common/widgets/custom_snackbar_widget.dart';
import 'package:get/get.dart';
import 'package:shoplancer_vendor/features/payment/domain/services/payment_service_interface.dart';

class PaymentController extends GetxController implements GetxService {
  final PaymentServiceInterface paymentServiceInterface;
  PaymentController({required this.paymentServiceInterface});

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<WithdrawModel>? _withdrawList;
  List<WithdrawModel>? get withdrawList => _withdrawList;

  late List<WithdrawModel> _allWithdrawList;

  double _pendingWithdraw = 0;
  double get pendingWithdraw => _pendingWithdraw;

  double _withdrawn = 0;
  double get withdrawn => _withdrawn;

  final List<String> _statusList = ['All', 'Pending', 'Approved', 'Denied'];
  List<String> get statusList => _statusList;

  int _filterIndex = 0;
  int get filterIndex => _filterIndex;

  List<WidthDrawMethodModel>? _widthDrawMethods;
  List<WidthDrawMethodModel>? get widthDrawMethods => _widthDrawMethods;

  int? _methodIndex = 0;
  int? get methodIndex => _methodIndex;

  List<DropdownMenuItem<int>> _methodList = [];
  List<DropdownMenuItem<int>> get methodList => _methodList;

  List<TextEditingController> _textControllerList = [];
  List<TextEditingController> get textControllerList => _textControllerList;

  List<MethodFields> _methodFields = [];
  List<MethodFields> get methodFields => _methodFields;

  List<FocusNode> _focusList = [];
  List<FocusNode> get focusList => _focusList;

  int _selectedIndex = 0;
  int get selectedIndex => _selectedIndex;

  List<Transactions>? _transactions;
  List<Transactions>? get transactions => _transactions;

  bool _adjustmentLoading = false;
  bool get adjustmentLoading => _adjustmentLoading;

  int _paymentIndex = 0;
  int get paymentIndex => _paymentIndex;

  String? _digitalPaymentName;
  String? get digitalPaymentName => _digitalPaymentName;

  List<OfflinePaymentMethodModel>? _offlinePaymentMethods;
  List<OfflinePaymentMethodModel>? get offlinePaymentMethods => _offlinePaymentMethods;

  List<WalletTopupRequestModel>? _topupRequests;
  List<WalletTopupRequestModel>? get topupRequests => _topupRequests;

  XFile? _rawReceiptImage;
  XFile? get rawReceiptImage => _rawReceiptImage;

  bool _isTopupSubmitting = false;
  bool get isTopupSubmitting => _isTopupSubmitting;

  Future<ResponseModel> makeCollectCashPayment(double amount, String paymentGatewayName) async {
    _isLoading = true;
    update();
    ResponseModel responseModel = await paymentServiceInterface.makeCollectCashPayment(amount, paymentGatewayName);
    _isLoading = false;
    update();
    return responseModel;
  }

  void setMethod({bool isUpdate = true}){
    _methodList = [];
    _textControllerList = [];
    _methodFields = [];
    _focusList = [];
    if(widthDrawMethods != null && widthDrawMethods!.isNotEmpty){
      for(int i=0; i< widthDrawMethods!.length; i++){
        _methodList.add(DropdownMenuItem<int>(value: i, child: SizedBox(
          width: Get.context!.width-100,
          child: Text(widthDrawMethods![i].methodName!, style: robotoBold),
        )));
      }
      _textControllerList = [];
      _methodFields = [];
      for (var field in widthDrawMethods![_methodIndex!].methodFields!) {
        _methodFields.add(field);
        _textControllerList.add(TextEditingController());
        _focusList.add(FocusNode());
      }
    }
    if(isUpdate) {
      update();
    }
  }

  void setMethodIndex(int? index) {
    _methodIndex = index;
  }

  Future<void> updateBankInfo(BankInfoBodyModel bankInfoBody) async {
    _isLoading = true;
    update();
    bool isSuccess = await paymentServiceInterface.updateBankInfo(bankInfoBody.toJson());
    if(isSuccess) {
      Get.find<ProfileController>().getProfile();
      Get.back();
      showCustomSnackBar('bank_info_updated'.tr, isError: false);
    }
    _isLoading = false;
    update();
  }

  Future<void> getWithdrawList() async {
    List<WithdrawModel>? withdrawList = await paymentServiceInterface.getWithdrawList();
    if(withdrawList != null) {
      _withdrawList = [];
      _allWithdrawList = [];
      _pendingWithdraw = 0;
      _withdrawn = 0;
      _withdrawList!.addAll(withdrawList);
      _allWithdrawList.addAll(withdrawList);
      _pendingWithdraw = paymentServiceInterface.pendingWithdraw(_withdrawList);
      _withdrawn = paymentServiceInterface.withdrawn(_withdrawList);
    }
    update();
  }

  Future<List<WidthDrawMethodModel>?> getWithdrawMethodList() async {
    List<WidthDrawMethodModel>? widthDrawMethods = await paymentServiceInterface.getWithdrawMethodList();
    if(widthDrawMethods != null) {
      _widthDrawMethods = [];
      _widthDrawMethods!.addAll(widthDrawMethods);
    }
    update();
    return _widthDrawMethods;
  }

  void setIndex(int index) {
    _selectedIndex = index;
    update();
  }

  Future<void> getWalletPaymentList() async {
    _transactions = null;
    List<Transactions>? transactions = await paymentServiceInterface.getWalletPaymentList();
    if(transactions != null) {
      _transactions = [];
      _transactions!.addAll(transactions);
    }
    update();
  }

  Future<void> makeWalletAdjustment() async {
    _adjustmentLoading = true;
    update();
    bool isSuccess = await paymentServiceInterface.makeWalletAdjustment();
    if(isSuccess) {
      Get.back();
      Get.find<ProfileController>().getProfile();
      showCustomSnackBar('wallet_adjustment_successfully'.tr, isError: false);
    }else {
      Get.back();
    }
    _adjustmentLoading = false;
    update();
  }

  void filterWithdrawList(int index) {
    _filterIndex = index;
    _withdrawList = [];
    if(index == 0) {
      _withdrawList!.addAll(_allWithdrawList);
    }else {
      for (var withdraw in _allWithdrawList) {
        if(withdraw.status == _statusList[index]) {
          _withdrawList!.add(withdraw);
        }
      }
    }
    update();
  }

  Future<void> requestWithdraw(Map<String?, String> data) async {
    _isLoading = true;
    update();
    bool isSuccess = await paymentServiceInterface.requestWithdraw(data);
    if(isSuccess) {
      Get.back();
      getWithdrawList();
      Get.find<ProfileController>().getProfile();
      showCustomSnackBar('request_sent_successfully'.tr, isError: false);
    }
    _isLoading = false;
    update();
  }

  void setPaymentIndex(int index){
    _paymentIndex = index;
    update();
  }

  void changeDigitalPaymentName(String? name, {bool canUpdate = true}){
    _digitalPaymentName = name;
    if(canUpdate) {
      update();
    }
  }

  bool _isPickerActive = false;

  void pickReceiptImage(ImageSource source) async {
    if (_isPickerActive) return;
    _isPickerActive = true;
    try {
      final XFile? image = await ImagePicker().pickImage(source: source);
      if (image != null) {
        _rawReceiptImage = image;
        update();
      }
    } catch (e) {
      debugPrint('Error picking receipt image: $e');
    } finally {
      _isPickerActive = false;
    }
  }

  void clearReceiptImage() {
    _rawReceiptImage = null;
    update();
  }

  Future<void> getOfflinePaymentMethods() async {
    List<OfflinePaymentMethodModel>? methods = await paymentServiceInterface.getOfflinePaymentMethods();
    if (methods != null) {
      _offlinePaymentMethods = [];
      _offlinePaymentMethods!.addAll(methods);
    }
    update();
  }

  Future<bool> submitTopupRequest({
    required int offlineMethodId,
    required double amount,
    String? notes,
  }) async {
    if (_rawReceiptImage == null) {
      showCustomSnackBar('please_upload_transfer_receipt'.tr);
      return false;
    }
    _isTopupSubmitting = true;
    update();

    Map<String, String> body = {
      'offline_payment_method_id': offlineMethodId.toString(),
      'amount': amount.toString(),
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    };

    ResponseModel responseModel = await paymentServiceInterface.submitTopupRequest(body, _rawReceiptImage);
    _isTopupSubmitting = false;

    if (responseModel.isSuccess) {
      _rawReceiptImage = null;
      showCustomSnackBar(responseModel.message, isError: false);
      getTopupRequests();
      getWalletInfo();
      Get.find<ProfileController>().getProfile();
      update();
      return true;
    } else {
      showCustomSnackBar(responseModel.message);
      update();
      return false;
    }
  }

  Future<void> getTopupRequests() async {
    List<WalletTopupRequestModel>? requests = await paymentServiceInterface.getTopupRequests();
    if (requests != null) {
      _topupRequests = [];
      _topupRequests!.addAll(requests);
    }
    update();
  }

  Future<void> getWalletInfo() async {
    Map<String, dynamic>? walletInfo = await paymentServiceInterface.getWalletInfo();
    if (walletInfo != null && Get.isRegistered<ProfileController>() && Get.find<ProfileController>().profileModel != null) {
      var profile = Get.find<ProfileController>().profileModel!;
      profile.prepaidBalance = walletInfo['prepaid_balance']?.toDouble();
      profile.minPrepaidBalanceLimit = walletInfo['min_prepaid_balance_limit']?.toDouble();
      profile.allowedCreditRemaining = walletInfo['allowed_credit_remaining']?.toDouble();
      profile.isSuspended = walletInfo['is_suspended'];
      Get.find<ProfileController>().update();
    }
    update();
  }

}