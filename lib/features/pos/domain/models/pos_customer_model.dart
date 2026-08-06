class PosCustomerModel {
  int? id;
  String? fName;
  String? lName;
  String? phone;
  String? email;
  String? text;

  PosCustomerModel({this.id, this.fName, this.lName, this.phone, this.email, this.text});

  PosCustomerModel.fromJson(Map<String, dynamic> json) {
    if (json['id'] is int) {
      id = json['id'];
    } else if (json['id'] is String) {
      id = int.tryParse(json['id']);
    } else {
      id = null;
    }
    fName = json['f_name'];
    lName = json['l_name'];
    phone = json['phone'];
    email = json['email'];
    text = json['text'];
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'f_name': fName,
      'l_name': lName,
      'phone': phone,
      'email': email,
      'text': text,
    };
  }

  String get fullName {
    if (text != null && text!.isNotEmpty) {
      return text!;
    }
    String name = '${fName ?? ''} ${lName ?? ''}'.trim();
    return name.isNotEmpty ? name : 'عميل زائر';
  }
}
