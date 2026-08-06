import 'dart:convert';
import 'package:shoplancer_vendor/features/store/domain/models/item_model.dart';

class OrderDetailsModel {
  int? id;
  int? itemId;
  int? orderId;
  double? price;
  Item? itemDetails;
  List<Variation>? variation;
  List<FoodVariation>? foodVariation;
  List<AddOn>? addOns;
  double? discountOnItem;
  String? discountType;
  double? quantity;
  double? taxAmount;
  String? variant;
  String? createdAt;
  String? updatedAt;
  int? itemCampaignId;
  double? totalAddOnPrice;

  OrderDetailsModel({
    this.id,
    this.itemId,
    this.orderId,
    this.price,
    this.itemDetails,
    this.variation,
    this.foodVariation,
    this.addOns,
    this.discountOnItem,
    this.discountType,
    this.quantity,
    this.taxAmount,
    this.variant,
    this.createdAt,
    this.updatedAt,
    this.itemCampaignId,
    this.totalAddOnPrice,
  });

  OrderDetailsModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    itemId = json['item_id'];
    orderId = json['order_id'];
    price = json['price'] != null ? double.tryParse(json['price'].toString()) : 0.0;
    if (json['item_details'] != null && json['item_details'] is Map<String, dynamic>) {
      itemDetails = Item.fromJson(json['item_details']);
    }
    variation = [];
    foodVariation = [];
    if (json['variation'] != null) {
      dynamic varData = json['variation'];
      if (varData is String && varData.isNotEmpty) {
        try {
          varData = jsonDecode(varData);
        } catch (_) {}
      }

      if (varData is List && varData.isNotEmpty) {
        for (var element in varData) {
          if (element is Map) {
            Map<String, dynamic> map = Map<String, dynamic>.from(element);
            if (map.containsKey('values')) {
              foodVariation!.add(FoodVariation.fromJson(map));
            } else {
              variation!.add(Variation.fromJson(map));
            }
          }
        }
      }
    }
    if (json['add_ons'] != null && json['add_ons'] is List) {
      addOns = [];
      for (var v in json['add_ons']) {
        if (v is Map<String, dynamic>) {
          addOns!.add(AddOn.fromJson(v));
        }
      }
    }
    discountOnItem = json['discount_on_item'] != null ? double.tryParse(json['discount_on_item'].toString()) : 0.0;
    discountType = json['discount_type'] == 'flat' ? 'amount' : json['discount_type'];
    quantity = json['quantity'] != null ? double.tryParse(json['quantity'].toString()) : null;
    taxAmount = json['tax_amount'] != null ? double.tryParse(json['tax_amount'].toString()) : 0.0;
    variant = json['variant']?.toString();
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    itemCampaignId = json['item_campaign_id'];
    totalAddOnPrice = json['total_add_on_price'] != null ? double.tryParse(json['total_add_on_price'].toString()) : 0.0;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['item_id'] = itemId;
    data['order_id'] = orderId;
    data['price'] = price;
    if (itemDetails != null) {
      data['item_details'] = itemDetails!.toJson();
    }
    if (variation != null) {
      data['variation'] = variation!.map((v) => v.toJson()).toList();
    } else if (foodVariation != null) {
      data['variation'] = foodVariation!.map((v) => v.toJson()).toList();
    }
    if (addOns != null) {
      data['add_ons'] = addOns!.map((v) => v.toJson()).toList();
    }
    data['discount_on_item'] = discountOnItem;
    data['discount_type'] = discountType;
    data['quantity'] = quantity;
    data['tax_amount'] = taxAmount;
    data['variant'] = variant;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    data['item_campaign_id'] = itemCampaignId;
    data['total_add_on_price'] = totalAddOnPrice;
    return data;
  }
}

class AddOn {
  String? name;
  double? price;
  int? quantity;

  AddOn({this.name, this.price, this.quantity});

  AddOn.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    price = json['price'] != null ? double.tryParse(json['price'].toString()) : 0.0;
    quantity = json['quantity'] != null ? int.tryParse(json['quantity'].toString()) : 1;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    data['price'] = price;
    data['quantity'] = quantity;
    return data;
  }
}