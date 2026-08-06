import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:shoplancer_vendor/features/payment/controllers/payment_controller.dart';
import 'package:shoplancer_vendor/helper/price_converter_helper.dart';
import 'package:shoplancer_vendor/util/dimensions.dart';
import 'package:shoplancer_vendor/util/styles.dart';
import 'package:shoplancer_vendor/common/widgets/custom_app_bar_widget.dart';

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {

  @override
  void initState() {
    Get.find<PaymentController>().getWalletPaymentList();
    super.initState();
  }

  String _formatTransactionDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      DateTime dateTime;
      if (dateStr.contains('T')) {
        dateTime = DateTime.parse(dateStr).toLocal();
      } else {
        dateTime = DateFormat('yyyy-MM-dd HH:mm:ss').parse(dateStr).toLocal();
      }
      return DateFormat('M/d h:mm').format(dateTime);
    } catch (_) {
      return dateStr;
    }
  }

  String _translateTransactionMethod(String? method) {
    if (method == null) return '';
    final isArabic = Get.locale?.languageCode == 'ar';
    if (method == 'order_credit') {
      return isArabic ? 'مستحقات الطلبات' : 'Order Credit';
    } else if (method == 'cash_collection') {
      return isArabic ? 'تحصيل نقدي' : 'Cash Collection';
    }
    return method.replaceAll('_', ' ').capitalize!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBarWidget(title: 'payment_history'.tr),

      body: GetBuilder<PaymentController>(builder: (paymentController) {
        return paymentController.transactions != null ? paymentController.transactions!.isNotEmpty ? ListView.builder(
          itemCount: paymentController.transactions!.length,
          shrinkWrap: true,
          padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeDefault, left: Dimensions.paddingSizeDefault, right: Dimensions.paddingSizeDefault),
          physics: const BouncingScrollPhysics(),
          itemBuilder: (context, index) {
            return Column(children: [

              Padding(
                padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeLarge),
                child: Row(children: [

                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                      Text(PriceConverterHelper.convertPrice(paymentController.transactions![index].amount), style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeDefault)),
                      const SizedBox(height: Dimensions.paddingSizeExtraSmall),

                      Text('${'paid_via'.tr} ${_translateTransactionMethod(paymentController.transactions![index].method)}', style: robotoRegular.copyWith(
                        fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).disabledColor,
                      )),

                    ]),
                  ),

                  Text(_formatTransactionDate(paymentController.transactions![index].paymentTime),
                    style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor),
                  ),

                ]),
              ),

              const Divider(height: 1),
            ]);
          },
        ) : Center(child: Text('no_transaction_found'.tr)) : const Center(child: CircularProgressIndicator());
      }),
    );
  }
}
