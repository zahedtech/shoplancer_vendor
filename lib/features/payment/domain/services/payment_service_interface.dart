import 'package:shoplancer_vendor/common/models/response_model.dart';
import 'package:shoplancer_vendor/features/payment/domain/models/offline_payment_method_model.dart';
import 'package:shoplancer_vendor/features/payment/domain/models/wallet_payment_model.dart';
import 'package:shoplancer_vendor/features/payment/domain/models/wallet_topup_request_model.dart';
import 'package:shoplancer_vendor/features/payment/domain/models/widthdrow_method_model.dart';
import 'package:shoplancer_vendor/features/payment/domain/models/withdraw_model.dart';

abstract class PaymentServiceInterface {
  Future<bool> updateBankInfo(Map<String, dynamic> body);
  Future<List<WithdrawModel>?> getWithdrawList();
  Future<bool> requestWithdraw(Map<String?, String> data);
  Future<List<WidthDrawMethodModel>?> getWithdrawMethodList();
  Future<List<Transactions>?> getWalletPaymentList();
  Future<bool> makeWalletAdjustment();
  Future<ResponseModel> makeCollectCashPayment(double amount, String paymentGatewayName);
  Future<List<OfflinePaymentMethodModel>?> getOfflinePaymentMethods();
  Future<ResponseModel> submitTopupRequest(Map<String, String> body, dynamic receiptImage);
  Future<List<WalletTopupRequestModel>?> getTopupRequests();
  Future<Map<String, dynamic>?> getWalletInfo();
  double pendingWithdraw(List<WithdrawModel>? withdrawList);
  double withdrawn(List<WithdrawModel>? withdrawList);
}