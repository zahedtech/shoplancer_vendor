import 'package:shoplancer_vendor/features/store/domain/models/item_model.dart';

class PosCartModel {
  Item item;
  double price;
  double discountAmount;
  int quantity;
  List<AddOns>? addOns;
  String? selectedVariant;

  PosCartModel({
    required this.item,
    required this.price,
    required this.discountAmount,
    required this.quantity,
    this.addOns,
    this.selectedVariant,
  });
}
