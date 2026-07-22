import 'package:shoplancer_vendor/features/splash/controllers/splash_controller.dart';
import 'package:get/get.dart';

class PriceConverterHelper {
  static String convertPrice(
    double? price, {
    double? discount,
    String? discountType,
    int? asFixed,
  }) {
    double finalPrice = price ?? 0.0;
    if (discount != null && discountType != null) {
      if (discountType == 'amount') {
        finalPrice = finalPrice - discount;
      } else if (discountType == 'percent') {
        finalPrice = finalPrice - ((discount / 100) * finalPrice);
      }
    }
    final config = Get.find<SplashController>().configModel;
    bool isRightSide = config?.currencySymbolDirection == 'right';
    final currencySymbol = config?.currencySymbol ?? '';
    final digitAfterDecimalPoint = config?.digitAfterDecimalPoint ?? 2;

    return '${isRightSide ? '' : '$currencySymbol '}'
        '${finalPrice.toStringAsFixed(asFixed ?? digitAfterDecimalPoint).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}'
        '${isRightSide ? ' $currencySymbol' : ''}';
  }

  static double? convertWithDiscount(
    double? price,
    double? discount,
    String? discountType,
  ) {
    if (price == null) return null;
    double finalPrice = price;
    if (discountType == 'amount') {
      finalPrice = finalPrice - (discount ?? 0.0);
    } else if (discountType == 'percent') {
      finalPrice = finalPrice - (((discount ?? 0.0) / 100) * finalPrice);
    }
    return finalPrice;
  }

  static double calculation(
    double amount,
    double? discount,
    String type,
    int quantity,
  ) {
    double calculatedAmount = 0;
    double finalDiscount = discount ?? 0.0;
    if (type == 'amount') {
      calculatedAmount = finalDiscount * quantity;
    } else if (type == 'percent') {
      calculatedAmount = (finalDiscount / 100) * (amount * quantity);
    }
    return calculatedAmount;
  }

  static String percentageCalculation(
    String price,
    String discount,
    String discountType,
  ) {
    final currencySymbol = Get.find<SplashController>().configModel?.currencySymbol ?? '';
    return '$discount${discountType == 'percent' ? '%' : currencySymbol} OFF';
  }
}
