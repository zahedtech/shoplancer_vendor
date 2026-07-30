import 'package:shoplancer_vendor/features/payment/domain/models/offline_payment_method_model.dart';

class WalletTopupRequestModel {
  int? id;
  int? vendorId;
  int? offlinePaymentMethodId;
  double? amount;
  String? receiptImage;
  String? receiptImageFullUrl;
  String? notes;
  String? status; // 'pending', 'approved', 'rejected'
  String? rejectionReason;
  String? createdAt;
  OfflinePaymentMethodModel? paymentMethod;

  WalletTopupRequestModel({
    this.id,
    this.vendorId,
    this.offlinePaymentMethodId,
    this.amount,
    this.receiptImage,
    this.receiptImageFullUrl,
    this.notes,
    this.status,
    this.rejectionReason,
    this.createdAt,
    this.paymentMethod,
  });

  WalletTopupRequestModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    vendorId = json['vendor_id'];
    offlinePaymentMethodId = json['offline_payment_method_id'];
    amount = json['amount']?.toDouble();
    receiptImage = json['receipt_image'];
    receiptImageFullUrl = json['receipt_image_full_url'];
    notes = json['notes'];
    status = json['status'];
    rejectionReason = json['rejection_reason'];
    createdAt = json['created_at'];
    if (json['payment_method'] != null) {
      paymentMethod = OfflinePaymentMethodModel.fromJson(json['payment_method']);
    } else if (json['offline_payment_method'] != null) {
      paymentMethod = OfflinePaymentMethodModel.fromJson(json['offline_payment_method']);
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['vendor_id'] = vendorId;
    data['offline_payment_method_id'] = offlinePaymentMethodId;
    data['amount'] = amount;
    data['receipt_image'] = receiptImage;
    data['receipt_image_full_url'] = receiptImageFullUrl;
    data['notes'] = notes;
    data['status'] = status;
    data['rejection_reason'] = rejectionReason;
    data['created_at'] = createdAt;
    if (paymentMethod != null) {
      data['payment_method'] = paymentMethod!.toJson();
    }
    return data;
  }
}
