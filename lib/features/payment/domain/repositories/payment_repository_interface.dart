import 'package:shoplancer_vendor/interface/repository_interface.dart';

abstract class PaymentRepositoryInterface implements RepositoryInterface {
  Future<dynamic> requestWithdraw(Map<String?, String> data);
  Future<dynamic> getWithdrawMethodList();
  Future<dynamic> getWalletPaymentList();
  Future<dynamic> makeWalletAdjustment();
  Future<dynamic> makeCollectCashPayment(double amount, String paymentGatewayName);
  Future<dynamic> getOfflinePaymentMethods();
  Future<dynamic> submitTopupRequest(Map<String, String> body, dynamic receiptImage);
  Future<dynamic> getTopupRequests();
  Future<dynamic> getWalletInfo();
}