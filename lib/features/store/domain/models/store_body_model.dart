import 'dart:convert';

class StoreBodyModel {
  String? translation;
  String? minDeliveryTime;
  String? maxDeliveryTime;
  String? lat;
  String? lng;
  String? fName;
  String? lName;
  String? phone;
  String? email;
  String? password;
  String? zoneId;
  String? moduleId;
  String? deliveryTimeType;
  String? businessPlan;
  String? packageId;
  List<String>? pickUpZoneIds;
  String? tin;
  String? tinExpireDate;
  String? deliveryPrice;
  String? openingTime;
  String? closingTime;
  String? isOpen24Hours;
  String? slug;
  String? websiteColor;

  StoreBodyModel({
    this.translation,
    this.minDeliveryTime,
    this.maxDeliveryTime,
    this.lat,
    this.lng,
    this.fName,
    this.lName,
    this.phone,
    this.email,
    this.password,
    this.zoneId,
    this.moduleId,
    this.deliveryTimeType,
    this.businessPlan,
    this.packageId,
    this.pickUpZoneIds,
    this.tin,
    this.tinExpireDate,
    this.deliveryPrice,
    this.openingTime,
    this.closingTime,
    this.isOpen24Hours,
    this.slug,
    this.websiteColor,
  });

  StoreBodyModel.fromJson(Map<String, dynamic> json) {
    translation = json['translations'];
    minDeliveryTime = json['min_delivery_time'];
    maxDeliveryTime = json['max_delivery_time'];
    lat = json['lat'];
    lng = json['lng'];
    fName = json['f_name'];
    lName = json['l_name'];
    phone = json['phone'];
    email = json['email'];
    password = json['password'];
    zoneId = json['zone_id'];
    moduleId = json['module_id'];
    deliveryTimeType = json['delivery_time_type'];
    businessPlan = json['business_plan'];
    packageId = json['package_id'];
    if (json['pickup_zone_id'] != null) {
      pickUpZoneIds = json['pickup_zone_id'].cast<String>();
    }
    tin = json['tin'];
    tinExpireDate = json['tin_expire_date'];
    deliveryPrice = json['delivery_price'];
    openingTime = json['opening_time'];
    closingTime = json['closing_time'];
    isOpen24Hours = json['is_open_24_hours'];
    slug = json['slug'];
    websiteColor = json['website_color'];
  }

  Map<String, String> toJson() {
    final Map<String, String> data = <String, String>{};
    data['translations'] = translation!;
    data['minimum_delivery_time'] = minDeliveryTime!;
    data['maximum_delivery_time'] = maxDeliveryTime!;
    data['latitude'] = lat!;
    data['longitude'] = lng!;
    data['f_name'] = fName!;
    data['l_name'] = lName!;
    data['phone'] = phone!;
    data['email'] = email!;
    data['password'] = password!;
    data['zone_id'] = zoneId!;
    data['module_id'] = moduleId!;
    data['delivery_time_type'] = deliveryTimeType!;
    data['business_plan'] = businessPlan ?? '';
    data['package_id'] = packageId!;
    if (pickUpZoneIds != null) {
      data['pickup_zone_id'] = json.encode(pickUpZoneIds);
    }
    data['tin'] = tin ?? '';
    data['tin_expire_date'] = tinExpireDate ?? '';
    data['delivery_price'] = deliveryPrice ?? '';
    data['opening_time'] = openingTime ?? '';
    data['closing_time'] = closingTime ?? '';
    data['is_open_24_hours'] = isOpen24Hours ?? '0';
    data['slug'] = slug ?? '';
    data['website_color'] = websiteColor ?? '';
    return data;
  }
}