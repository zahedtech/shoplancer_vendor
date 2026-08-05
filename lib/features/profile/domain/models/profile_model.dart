import 'dart:convert';
import 'package:shoplancer_vendor/features/store/domain/models/item_model.dart';

class ProfileModel {
  int? id;
  String? fName;
  String? lName;
  String? phone;
  String? countryCode;
  String? email;
  String? createdAt;
  String? updatedAt;
  String? bankName;
  String? branch;
  String? holderName;
  String? accountNo;
  String? imageFullUrl;
  int? orderCount;
  int? todaysOrderCount;
  int? thisWeekOrderCount;
  int? thisMonthOrderCount;
  int? memberSinceDays;
  double? cashInHands;
  double? balance;
  double? totalEarning;
  double? todaysEarning;
  double? thisWeekEarning;
  double? thisMonthEarning;
  List<Store>? stores;
  List<String>? roles;
  EmployeeInfo? employeeInfo;
  List<Translation>? translations;
  double? withdrawAbleBalance;
  double? payableBalance;
  bool? adjustable;
  bool? overFlowWarning;
  bool? overFlowBlockWarning;
  double? pendingWithdraw;
  double? alreadyWithdrawn;
  String? dynamicBalanceType;
  double? dynamicBalance;
  bool? showPayNowButton;
  Subscription? subscription;
  SubscriptionOtherData? subscriptionOtherData;
  bool? subscriptionTransactions;
  int? outOfStockCount;
  double? totalCommissionCollected;
  String? storeUrl;
  String? storeQrCode;
  double? prepaidBalance;
  double? minPrepaidBalanceLimit;
  double? allowedCreditRemaining;
  bool? isSuspended;

  ProfileModel({
    this.id,
    this.fName,
    this.lName,
    this.phone,
    this.email,
    this.createdAt,
    this.updatedAt,
    this.bankName,
    this.branch,
    this.holderName,
    this.accountNo,
    this.imageFullUrl,
    this.orderCount,
    this.todaysOrderCount,
    this.thisWeekOrderCount,
    this.thisMonthOrderCount,
    this.memberSinceDays,
    this.cashInHands,
    this.balance,
    this.totalEarning,
    this.todaysEarning,
    this.thisWeekEarning,
    this.thisMonthEarning,
    this.stores,
    this.roles,
    this.employeeInfo,
    this.translations,
    this.withdrawAbleBalance,
    this.payableBalance,
    this.adjustable,
    this.overFlowWarning,
    this.overFlowBlockWarning,
    this.pendingWithdraw,
    this.alreadyWithdrawn,
    this.dynamicBalanceType,
    this.dynamicBalance,
    this.showPayNowButton,
    this.subscription,
    this.subscriptionOtherData,
    this.subscriptionTransactions,
    this.outOfStockCount,
    this.totalCommissionCollected,
    this.storeUrl,
    this.storeQrCode,
    this.prepaidBalance,
    this.minPrepaidBalanceLimit,
    this.allowedCreditRemaining,
    this.isSuspended,
  });

  ProfileModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    fName = json['f_name'];
    lName = json['l_name'];
    phone = json['phone'];
    countryCode = json['country_code'];
    email = json['email'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    bankName = json['bank_name'];
    branch = json['branch'];
    holderName = json['holder_name'];
    accountNo = json['account_no'];
    imageFullUrl = json['image_full_url'];
    orderCount = json['order_count'];
    todaysOrderCount = json['todays_order_count'];
    thisWeekOrderCount = json['this_week_order_count'];
    thisMonthOrderCount = json['this_month_order_count'];
    memberSinceDays = int.tryParse(json['member_since_days'].toString()) ?? 0;
    cashInHands = double.tryParse(json['cash_in_hands']?.toString() ?? '');
    balance = double.tryParse(json['balance']?.toString() ?? '');
    totalEarning = double.tryParse(json['total_earning']?.toString() ?? '');
    todaysEarning = double.tryParse(json['todays_earning']?.toString() ?? '');
    thisWeekEarning = double.tryParse(
      json['this_week_earning']?.toString() ?? '',
    );
    thisMonthEarning = double.tryParse(
      json['this_month_earning']?.toString() ?? '',
    );
    if (json['stores'] != null) {
      stores = [];
      json['stores'].forEach((v) {
        stores!.add(Store.fromJson(v));
      });
    }
    if (stores != null && stores!.isNotEmpty) {
      if (json['store_payment_methods'] != null) {
        Map<int, Map<int, StorePaymentMethod>> storeMethodMap = {};
        for (var method in json['store_payment_methods']) {
          int? storeId = method['store_id'];
          int? methodId = method['zone_payment_method_id'];
          if (storeId == null || methodId == null) {
            continue;
          }
          bool isActive =
              method['is_active'] == true || method['is_active'] == 1;
          Map<String, dynamic>? config;
          if (method['config'] is Map) {
            config = Map<String, dynamic>.from(method['config']);
          } else if (method['config'] is String &&
              (method['config'] as String).isNotEmpty) {
            try {
              config = Map<String, dynamic>.from(
                jsonDecode(method['config'] as String),
              );
            } catch (_) {
              config = null;
            }
          }
          storeMethodMap.putIfAbsent(storeId, () => {});
          storeMethodMap[storeId]![methodId] = StorePaymentMethod(
            isActive: isActive,
            configData: config,
          );
        }
        for (var store in stores!) {
          if (store.id != null && storeMethodMap[store.id] != null) {
            store.paymentMethods = storeMethodMap[store.id];
          }
        }
      }
    }
    if (json['roles'] != null) {
      roles = [];
      json['roles'].forEach((v) => roles!.add(v));
    }
    if (json['employee_info'] != null) {
      employeeInfo = EmployeeInfo.fromJson(json['employee_info']);
    }
    if (json['translations'] != null) {
      translations = [];
      json['translations'].forEach((v) {
        translations!.add(Translation.fromJson(v));
      });
    }
    withdrawAbleBalance = double.tryParse(
      json['withdraw_able_balance']?.toString() ?? '',
    );
    payableBalance = double.tryParse(json['Payable_Balance']?.toString() ?? '');
    adjustable = json['adjust_able'];
    overFlowWarning = json['over_flow_warning'];
    overFlowBlockWarning = json['over_flow_block_warning'];
    pendingWithdraw = double.tryParse(
      json['pending_withdraw']?.toString() ?? '',
    );
    alreadyWithdrawn = double.tryParse(
      json['total_withdrawn']?.toString() ?? '',
    );
    dynamicBalanceType = json['dynamic_balance_type'];
    dynamicBalance = double.tryParse(json['dynamic_balance']?.toString() ?? '');
    showPayNowButton = json['show_pay_now_button'];
    if (json['subscription'] != null) {
      subscription = Subscription.fromJson(json['subscription']);
    }
    subscriptionOtherData = json['subscription_other_data'] != null
        ? SubscriptionOtherData.fromJson(json['subscription_other_data'])
        : null;
    subscriptionTransactions = json['subscription_transactions'] ?? false;
    outOfStockCount = json['out_of_stock_count'];
    totalCommissionCollected = double.tryParse(
      json['total_commission_collected']?.toString() ?? '',
    );
    storeUrl = json['store_url'];
    storeQrCode = json['store_qr_code'];
    prepaidBalance = double.tryParse(json['prepaid_balance']?.toString() ?? '');
    minPrepaidBalanceLimit = double.tryParse(
      json['min_prepaid_balance_limit']?.toString() ?? '',
    );
    allowedCreditRemaining = double.tryParse(
      json['allowed_credit_remaining']?.toString() ?? '',
    );
    isSuspended =
        json['is_suspended'] == true ||
        json['is_suspended'] == 1 ||
        json['is_suspended'] == '1';
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['f_name'] = fName;
    data['l_name'] = lName;
    data['phone'] = phone;
    data['country_code'] = countryCode;
    data['email'] = email;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    data['bank_name'] = bankName;
    data['branch'] = branch;
    data['holder_name'] = holderName;
    data['account_no'] = accountNo;
    data['image_full_url'] = imageFullUrl;
    data['order_count'] = orderCount;
    data['todays_order_count'] = todaysOrderCount;
    data['this_week_order_count'] = thisWeekOrderCount;
    data['this_month_order_count'] = thisMonthOrderCount;
    data['member_since_days'] = memberSinceDays;
    data['cash_in_hands'] = cashInHands;
    data['balance'] = balance;
    data['total_earning'] = totalEarning;
    data['todays_earning'] = todaysEarning;
    data['this_week_earning'] = thisWeekEarning;
    data['this_month_earning'] = thisMonthEarning;
    if (stores != null) {
      data['stores'] = stores!.map((v) => v.toJson()).toList();
    }
    data['employee_info'] = employeeInfo;
    if (translations != null) {
      data['translations'] = translations!.map((v) => v.toJson()).toList();
    }
    data['withdraw_able_balance'] = withdrawAbleBalance;
    data['Payable_Balance'] = payableBalance;
    data['adjust_able'] = adjustable;
    data['over_flow_warning'] = overFlowWarning;
    data['over_flow_block_warning'] = overFlowBlockWarning;
    data['pending_withdraw'] = pendingWithdraw;
    data['total_withdrawn'] = alreadyWithdrawn;
    data['dynamic_balance_type'] = dynamicBalanceType;
    data['dynamic_balance'] = dynamicBalance;
    data['show_pay_now_button'] = showPayNowButton;
    data['subscription_transactions'] = subscriptionTransactions;
    data['out_of_stock_count'] = outOfStockCount;
    data['total_commission_collected'] = totalCommissionCollected;
    data['store_url'] = storeUrl;
    data['store_qr_code'] = storeQrCode;
    data['prepaid_balance'] = prepaidBalance;
    data['min_prepaid_balance_limit'] = minPrepaidBalanceLimit;
    data['allowed_credit_remaining'] = allowedCreditRemaining;
    data['is_suspended'] = isSuspended;
    return data;
  }
}

class Store {
  int? id;
  String? slug;
  String? name;
  String? phone;
  String? countryCode;
  String? email;
  String? logoFullUrl;
  String? latitude;
  String? longitude;
  String? address;
  double? minimumOrder;
  double? comission;
  bool? scheduleOrder;
  String? currency;
  String? createdAt;
  String? updatedAt;
  bool? freeDelivery;
  String? coverPhotoFullUrl;
  bool? delivery;
  bool? takeAway;
  double? tax;
  bool? reviewsSection;
  bool? itemSection;
  double? avgRating;
  int? ratingCount;
  int? totalOrder;
  int? totalItems;
  bool? active;
  bool? gstStatus;
  String? gstCode;
  int? selfDeliverySystem;
  bool? posSystem;
  double? minimumShippingCharge;
  double? maximumShippingCharge;
  double? perKmShippingCharge;
  double? deliveryPrice;
  String? deliveryTime;
  int? veg;
  int? nonVeg;
  int? orderPlaceToScheduleInterval;
  Module? module;
  Discount? discount;
  List<Schedules>? schedules;
  bool? prescriptionStatus;
  bool? cutlery;
  String? metaTitle;
  String? metaDescription;
  String? metaImageFullUrl;
  String? metaKeyWord;
  String? announcementMessage;
  String? storeBusinessModel;
  int? isAnnouncementActive;
  bool? extraPackagingStatus;
  double? extraPackagingAmount;
  bool? isHalalActive;
  double? minimumStockForWarning;
  Map<int, StorePaymentMethod>? paymentMethods;
  MetaSeoData? metaData;
  String? tiktok;
  String? instagram;
  String? facebook;
  String? whatsapp;
  int? defaultBanner;
  int? zoneId;

  Store({
    this.id,
    this.slug,
    this.name,
    this.phone,
    this.countryCode,
    this.email,
    this.logoFullUrl,
    this.latitude,
    this.longitude,
    this.address,
    this.minimumOrder,
    this.comission,
    this.scheduleOrder,
    this.currency,
    this.createdAt,
    this.updatedAt,
    this.freeDelivery,
    this.coverPhotoFullUrl,
    this.delivery,
    this.takeAway,
    this.tax,
    this.reviewsSection,
    this.itemSection,
    this.avgRating,
    this.ratingCount,
    this.totalOrder,
    this.totalItems,
    this.active,
    this.gstStatus,
    this.gstCode,
    this.selfDeliverySystem,
    this.posSystem,
    this.minimumShippingCharge,
    this.maximumShippingCharge,
    this.perKmShippingCharge,
    this.deliveryPrice,
    this.deliveryTime,
    this.veg,
    this.nonVeg,
    this.orderPlaceToScheduleInterval,
    this.module,
    this.discount,
    this.schedules,
    this.prescriptionStatus,
    this.cutlery,
    this.metaTitle,
    this.metaDescription,
    this.metaKeyWord,
    this.metaImageFullUrl,
    this.announcementMessage,
    this.storeBusinessModel,
    this.isAnnouncementActive,
    this.extraPackagingStatus,
    this.extraPackagingAmount,
    this.isHalalActive,
    this.minimumStockForWarning,
    this.paymentMethods,
    this.facebook,
    this.instagram,
    this.tiktok,
    this.whatsapp,
    this.defaultBanner,
    this.zoneId,
  });

  Store.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    zoneId = json['zone_id'];
    slug = json['slug'] ?? json['slug_name'];
    name = json['name'];
    phone = json['phone'];
    countryCode = json['country_code'];
    email = json['email'];
    logoFullUrl = json['logo_full_url'];
    latitude = json['latitude'];
    longitude = json['longitude'];
    address = json['address'];
    minimumOrder = json['minimum_order']?.toDouble();
    comission = json['comission']?.toDouble();
    scheduleOrder = json['schedule_order'];
    currency = json['currency'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    freeDelivery = json['free_delivery'];
    coverPhotoFullUrl = json['cover_photo_full_url'];
    delivery = json['delivery'];
    takeAway = json['take_away'];
    tax = json['tax']?.toDouble();
    reviewsSection = json['reviews_section'];
    itemSection = json['item_section'];
    avgRating = json['avg_rating']?.toDouble();
    ratingCount = json['rating_count'];
    totalItems = json['total_items'];
    totalOrder = json['total_order'];
    active =
        json['active'] == true || json['active'] == 1 || json['active'] == '1';
    gstStatus = json['gst_status'];
    gstCode = json['gst_code'];
    selfDeliverySystem = json['self_delivery_system'];
    posSystem = json['pos_system'];
    minimumShippingCharge = json['minimum_shipping_charge'] != null
        ? json['minimum_shipping_charge']?.toDouble()
        : 0.0;
    maximumShippingCharge = json['maximum_shipping_charge']?.toDouble();
    perKmShippingCharge = json['per_km_shipping_charge'] != null
        ? json['per_km_shipping_charge']?.toDouble()
        : 0.0;
    deliveryPrice = json['delivery_price'] != null
        ? double.tryParse(json['delivery_price'].toString())
        : null;
    deliveryTime = json['delivery_time'];
    veg = json['veg'];
    nonVeg = json['non_veg'];
    orderPlaceToScheduleInterval = json['order_place_to_schedule_interval'];
    module = json['module'] != null ? Module.fromJson(json['module']) : null;
    discount = json['discount'] != null
        ? Discount.fromJson(json['discount'])
        : null;
    if (json['schedules'] != null) {
      schedules = <Schedules>[];
      json['schedules'].forEach((v) {
        schedules!.add(Schedules.fromJson(v));
      });
    }
    prescriptionStatus = json['prescription_order'];
    cutlery = json['cutlery'];
    metaTitle = json['meta_title'];
    metaDescription = json['meta_description'];
    metaImageFullUrl = json['meta_image_full_url'];
    metaKeyWord = json['meta_key_word'];
    announcementMessage = json['announcement_message'];
    storeBusinessModel = json['store_business_model'];
    isAnnouncementActive = json['announcement'];
    extraPackagingStatus = json['extra_packaging_status'] ?? false;
    extraPackagingAmount = json['extra_packaging_amount']?.toDouble();
    isHalalActive = json['halal_tag_status'] ?? false;
    minimumStockForWarning = json['minimum_stock_for_warning']?.toDouble();
    facebook = json['facebook'];
    instagram = json['instagram'];
    tiktok = json['tiktok'];
    whatsapp = json['whatsapp'];
    if (json['methods'] != null) {
      paymentMethods = {};
      (json['methods'] as Map).forEach((key, value) {
        int? methodId = int.tryParse(key.toString());
        if (methodId != null) {
          paymentMethods![methodId] = StorePaymentMethod.fromJson(value);
        }
      });
    } else if (json['payment_methods'] != null) {
      paymentMethods = {};
      for (var method in json['payment_methods']) {
        int? methodId = method['id'];
        if (methodId == null) {
          continue;
        }
        bool isActive =
            method['pivot']?['is_active'] == 1 ||
            method['pivot']?['is_active'] == true ||
            method['is_active'] == 1 ||
            method['is_active'] == true;
        Map<String, dynamic>? config;
        if (method['config_data'] is Map) {
          config = Map<String, dynamic>.from(method['config_data']);
        } else if (method['pivot']?['config'] is Map) {
          config = Map<String, dynamic>.from(method['pivot']?['config']);
        }
        paymentMethods![methodId] = StorePaymentMethod(
          isActive: isActive,
          configData: config,
        );
      }
    }
    metaData = json['meta_data'] != null
        ? MetaSeoData.fromJson(json['meta_data'])
        : null;
    defaultBanner = json['default_banner'] != null
        ? int.tryParse(json['default_banner'].toString())
        : (json['defalut_banner'] != null
              ? int.tryParse(json['defalut_banner'].toString())
              : null);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['slug'] = slug;
    data['name'] = name;
    data['phone'] = phone;
    data['country_code'] = countryCode;
    data['email'] = email;
    data['logo_full_url'] = logoFullUrl;
    data['latitude'] = latitude;
    data['longitude'] = longitude;
    data['address'] = address;
    data['minimum_order'] = minimumOrder;
    data['comission'] = comission;
    data['schedule_order'] = scheduleOrder;
    data['currency'] = currency;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    data['free_delivery'] = freeDelivery;
    data['cover_photo_full_url'] = coverPhotoFullUrl;
    data['delivery'] = delivery;
    data['take_away'] = takeAway;
    data['tax'] = tax;
    data['reviews_section'] = reviewsSection;
    data['item_section'] = itemSection;
    data['avg_rating'] = avgRating;
    data['rating_count '] = ratingCount;
    data['total_items'] = totalItems;
    data['total_order'] = totalOrder;
    data['active'] = active;
    data['gst_status'] = gstStatus;
    data['gst_code'] = gstCode;
    data['self_delivery_system'] = selfDeliverySystem;
    data['pos_system'] = posSystem;
    data['minimum_shipping_charge'] = minimumShippingCharge;
    data['maximum_shipping_charge'] = maximumShippingCharge;
    data['per_km_shipping_charge'] = perKmShippingCharge;
    data['delivery_price'] = deliveryPrice;
    data['delivery_time'] = deliveryTime;
    data['veg'] = veg;
    data['non_veg'] = nonVeg;
    data['order_place_to_schedule_interval'] = orderPlaceToScheduleInterval;
    if (module != null) {
      data['module'] = module!.toJson();
    }
    if (discount != null) {
      data['discount'] = discount!.toJson();
    }
    if (schedules != null) {
      data['schedules'] = schedules!.map((v) => v.toJson()).toList();
    }
    data['prescription_order'] = prescriptionStatus;
    data['cutlery'] = cutlery;
    data['meta_title'] = metaTitle;
    data['meta_description'] = metaDescription;
    data['meta_image_full_url'] = metaImageFullUrl;
    data['meta_key_word'] = metaKeyWord;
    data['announcement_message'] = announcementMessage;
    data['store_business_model'] = storeBusinessModel;
    data['announcement'] = isAnnouncementActive;
    data['extra_packaging_status'] = extraPackagingStatus;
    data['extra_packaging_amount'] = extraPackagingAmount;
    data['halal_tag_status'] = isHalalActive;
    data['minimum_stock_for_warning'] = minimumStockForWarning;
    data['facebook'] = facebook;
    data['instagram'] = instagram;
    data['tiktok'] = tiktok;
    data['whatsapp'] = whatsapp;
    if (paymentMethods != null) {
      data['methods'] = paymentMethods!.map(
        (key, value) => MapEntry(key.toString(), value.toJson()),
      );
    }
    if (metaData != null) {
      data['meta_data'] = metaData!.toJson();
    }
    data['default_banner'] = defaultBanner;
    return data;
  }
}

class StorePaymentMethod {
  bool isActive;
  Map<String, dynamic>? configData;

  StorePaymentMethod({required this.isActive, this.configData});

  factory StorePaymentMethod.fromJson(dynamic json) {
    if (json == null) {
      return StorePaymentMethod(isActive: false);
    }
    return StorePaymentMethod(
      isActive: json['is_active'] == 1 || json['is_active'] == true,
      configData: json['config_data'] != null
          ? Map<String, dynamic>.from(json['config_data'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {'is_active': isActive ? 1 : 0, 'config_data': configData};
  }
}

class MetaSeoData {
  String? metaIndex;
  String? metaNoFollow;
  String? metaNoArchive;
  String? metaNoSnippet;
  String? metaMaxSnippet;
  String? metaNoImageIndex;
  String? metaMaxImagePreview;
  String? metaMaxSnippetValue;
  String? metaMaxVideoPreview;
  String? metaMaxImagePreviewValue;
  String? metaMaxVideoPreviewValue;

  MetaSeoData({
    this.metaIndex,
    this.metaNoFollow,
    this.metaNoArchive,
    this.metaNoSnippet,
    this.metaMaxSnippet,
    this.metaNoImageIndex,
    this.metaMaxImagePreview,
    this.metaMaxSnippetValue,
    this.metaMaxVideoPreview,
    this.metaMaxImagePreviewValue,
    this.metaMaxVideoPreviewValue,
  });

  MetaSeoData.fromJson(Map<String, dynamic> json) {
    metaIndex = json['meta_index']?.toString();
    metaNoFollow = json['meta_no_follow']?.toString();
    metaNoArchive = json['meta_no_archive']?.toString();
    metaNoSnippet = json['meta_no_snippet']?.toString();
    metaMaxSnippet = json['meta_max_snippet']?.toString();
    metaNoImageIndex = json['meta_no_image_index']?.toString();
    metaMaxImagePreview = json['meta_max_image_preview']?.toString();
    metaMaxSnippetValue = json['meta_max_snippet_value']?.toString();
    metaMaxVideoPreview = json['meta_max_video_preview']?.toString();
    metaMaxImagePreviewValue = json['meta_max_image_preview_value']?.toString();
    metaMaxVideoPreviewValue = json['meta_max_video_preview_value']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['meta_index'] = metaIndex;
    data['meta_no_follow'] = metaNoFollow;
    data['meta_no_archive'] = metaNoArchive;
    data['meta_no_snippet'] = metaNoSnippet;
    data['meta_max_snippet'] = metaMaxSnippet;
    data['meta_no_image_index'] = metaNoImageIndex;
    data['meta_max_image_preview'] = metaMaxImagePreview;
    data['meta_max_snippet_value'] = metaMaxSnippetValue;
    data['meta_max_video_preview'] = metaMaxVideoPreview;
    data['meta_max_image_preview_value'] = metaMaxImagePreviewValue;
    data['meta_max_video_preview_value'] = metaMaxVideoPreviewValue;
    return data;
  }
}

class EmployeeInfo {
  int? id;
  String? fName;
  String? lName;
  String? phone;
  String? email;
  String? imageFullUrl;
  int? employeeRoleId;
  int? storeId;

  EmployeeInfo({
    this.id,
    this.fName,
    this.lName,
    this.phone,
    this.email,
    this.imageFullUrl,
    this.employeeRoleId,
    this.storeId,
  });

  EmployeeInfo.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    fName = json['f_name'];
    lName = json['l_name'];
    phone = json['phone'];
    email = json['email'];
    imageFullUrl = json['image_full_url'];
    employeeRoleId = json['employee_role_id'];
    storeId = json['store_id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['f_name'] = fName;
    data['l_name'] = lName;
    data['phone'] = phone;
    data['email'] = email;
    data['image_full_url'] = imageFullUrl;
    data['employee_role_id'] = employeeRoleId;
    data['store_id'] = storeId;
    return data;
  }
}

class Discount {
  int? id;
  String? startDate;
  String? endDate;
  String? startTime;
  String? endTime;
  double? minPurchase;
  double? maxDiscount;
  double? discount;
  String? discountType;
  int? storeId;
  String? createdAt;
  String? updatedAt;

  Discount({
    this.id,
    this.startDate,
    this.endDate,
    this.startTime,
    this.endTime,
    this.minPurchase,
    this.maxDiscount,
    this.discount,
    this.discountType,
    this.storeId,
    this.createdAt,
    this.updatedAt,
  });

  Discount.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    startDate = json['start_date'];
    endDate = json['end_date'];
    startTime = json['start_time'];
    endTime = json['end_time'];
    minPurchase = json['min_purchase']?.toDouble();
    maxDiscount = json['max_discount']?.toDouble();
    discount = json['discount']?.toDouble();
    discountType = json['discount_type'] == 'flat'
        ? 'amount'
        : json['discount_type'];
    storeId = json['store_id'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['start_date'] = startDate;
    data['end_date'] = endDate;
    data['start_time'] = startTime;
    data['end_time'] = endTime;
    data['min_purchase'] = minPurchase;
    data['max_discount'] = maxDiscount;
    data['discount'] = discount;
    data['discount_type'] = discountType;
    data['store_id'] = storeId;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    return data;
  }
}

class Schedules {
  int? id;
  int? storeId;
  int? day;
  String? openingTime;
  String? closingTime;

  Schedules({
    this.id,
    this.storeId,
    this.day,
    this.openingTime,
    this.closingTime,
  });

  Schedules.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    storeId = json['store_id'];
    day = json['day'];
    openingTime = json['opening_time'].substring(0, 5);
    closingTime = json['closing_time'].substring(0, 5);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['store_id'] = storeId;
    data['day'] = day;
    data['opening_time'] = openingTime;
    data['closing_time'] = closingTime;
    return data;
  }
}

class Module {
  int? id;
  String? moduleName;
  String? moduleType;
  String? thumbnail;
  String? status;
  int? storesCount;
  String? createdAt;
  String? updatedAt;

  Module({
    this.id,
    this.moduleName,
    this.moduleType,
    this.thumbnail,
    this.status,
    this.storesCount,
    this.createdAt,
    this.updatedAt,
  });

  Module.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    moduleName = json['module_name'];
    moduleType = json['module_type'];
    thumbnail = json['thumbnail'];
    status = json['status'];
    storesCount = json['stores_count'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['module_name'] = moduleName;
    data['module_type'] = moduleType;
    data['thumbnail'] = thumbnail;
    data['status'] = status;
    data['stores_count'] = storesCount;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    return data;
  }
}

class Subscription {
  int? id;
  int? packageId;
  int? storeId;
  String? expiryDate;
  String? maxOrder;
  String? maxProduct;
  int? pos;
  int? mobileApp;
  int? chat;
  int? review;
  int? selfDelivery;
  int? status;
  int? isTrial;
  int? totalPackageRenewed;
  String? createdAt;
  String? updatedAt;
  String? renewedAt;
  int? isCanceled;
  String? canceledBy;
  int? validity;
  Package? package;

  Subscription({
    this.id,
    this.packageId,
    this.storeId,
    this.expiryDate,
    this.maxOrder,
    this.maxProduct,
    this.pos,
    this.mobileApp,
    this.chat,
    this.review,
    this.selfDelivery,
    this.status,
    this.isTrial,
    this.totalPackageRenewed,
    this.createdAt,
    this.updatedAt,
    this.renewedAt,
    this.isCanceled,
    this.canceledBy,
    this.validity,
    this.package,
  });

  Subscription.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    packageId = json['package_id'];
    storeId = json['store_id'];
    expiryDate = json['expiry_date'];
    maxOrder = json['max_order'];
    maxProduct = json['max_product'];
    pos = json['pos'] ?? 0;
    mobileApp = json['mobile_app'] ?? 0;
    chat = json['chat'] ?? 0;
    review = json['review'] ?? 0;
    selfDelivery = json['self_delivery'];
    status = json['status'];
    isTrial = json['is_trial'];
    totalPackageRenewed = json['total_package_renewed'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    renewedAt = json['renewed_at'];
    isCanceled = json['is_canceled'];
    canceledBy = json['canceled_by'];
    validity = json['validity'];
    package = json['package'] != null
        ? Package.fromJson(json['package'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['package_id'] = packageId;
    data['store_id'] = storeId;
    data['expiry_date'] = expiryDate;
    data['max_order'] = maxOrder;
    data['max_product'] = maxProduct;
    data['pos'] = pos;
    data['mobile_app'] = mobileApp;
    data['chat'] = chat;
    data['review'] = review;
    data['self_delivery'] = selfDelivery;
    data['status'] = status;
    data['total_package_renewed'] = totalPackageRenewed;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    data['renewed_at'] = renewedAt;
    data['is_canceled'] = isCanceled;
    data['canceled_by'] = canceledBy;
    data['validity'] = validity;
    if (package != null) {
      data['package'] = package!.toJson();
    }
    return data;
  }
}

class Package {
  int? id;
  String? packageName;
  double? price;
  int? validity;
  String? maxOrder;
  String? maxProduct;
  int? pos;
  int? mobileApp;
  int? chat;
  int? review;
  int? selfDelivery;
  int? status;
  int? def;
  String? colour;
  String? text;
  String? createdAt;
  String? updatedAt;

  Package({
    this.id,
    this.packageName,
    this.price,
    this.validity,
    this.maxOrder,
    this.maxProduct,
    this.pos,
    this.mobileApp,
    this.chat,
    this.review,
    this.selfDelivery,
    this.status,
    this.def,
    this.colour,
    this.text,
    this.createdAt,
    this.updatedAt,
  });

  Package.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    packageName = json['package_name'];
    price = json['price']?.toDouble();
    validity = json['validity'];
    maxOrder = json['max_order'];
    maxProduct = json['max_product'];
    pos = json['pos'];
    mobileApp = json['mobile_app'];
    chat = json['chat'];
    review = json['review'];
    selfDelivery = json['self_delivery'];
    status = json['status'];
    def = json['default'];
    colour = json['colour'];
    text = json['text'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['package_name'] = packageName;
    data['price'] = price;
    data['validity'] = validity;
    data['max_order'] = maxOrder;
    data['max_product'] = maxProduct;
    data['pos'] = pos;
    data['mobile_app'] = mobileApp;
    data['chat'] = chat;
    data['review'] = review;
    data['self_delivery'] = selfDelivery;
    data['status'] = status;
    data['default'] = def;
    data['colour'] = colour;
    data['text'] = text;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    return data;
  }
}

class SubscriptionOtherData {
  double? totalBill;
  int? maxProductUpload;
  double? pendingBill;

  SubscriptionOtherData({
    this.totalBill,
    this.maxProductUpload,
    this.pendingBill,
  });

  SubscriptionOtherData.fromJson(Map<String, dynamic> json) {
    totalBill = json['total_bill']?.toDouble();
    maxProductUpload = json['max_product_uploads'];
    pendingBill = json['pending_bill']?.toDouble();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['total_bill'] = totalBill;
    data['max_product_uploads'] = maxProductUpload;
    data['pending_bill'] = pendingBill;
    return data;
  }
}
