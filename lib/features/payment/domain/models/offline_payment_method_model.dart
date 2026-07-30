class OfflinePaymentMethodModel {
  int? id;
  String? methodName;
  String? accountName;
  String? accountNumber;
  String? instructions;
  bool? status;

  OfflinePaymentMethodModel({
    this.id,
    this.methodName,
    this.accountName,
    this.accountNumber,
    this.instructions,
    this.status,
  });

  OfflinePaymentMethodModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    methodName = json['method_name'];
    accountName = json['account_name'];
    accountNumber = json['account_number'];
    instructions = json['instructions'];
    status = json['status'] == 1 || json['status'] == true;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['method_name'] = methodName;
    data['account_name'] = accountName;
    data['account_number'] = accountNumber;
    data['instructions'] = instructions;
    data['status'] = status;
    return data;
  }
}
