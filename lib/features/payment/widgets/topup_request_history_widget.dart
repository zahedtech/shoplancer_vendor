import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shoplancer_vendor/features/payment/controllers/payment_controller.dart';
import 'package:shoplancer_vendor/features/payment/domain/models/wallet_topup_request_model.dart';
import 'package:shoplancer_vendor/helper/price_converter_helper.dart';
import 'package:shoplancer_vendor/util/dimensions.dart';
import 'package:shoplancer_vendor/util/styles.dart';

class TopupRequestHistoryWidget extends StatefulWidget {
  const TopupRequestHistoryWidget({super.key});

  @override
  State<TopupRequestHistoryWidget> createState() => _TopupRequestHistoryWidgetState();
}

class _TopupRequestHistoryWidgetState extends State<TopupRequestHistoryWidget> {
  @override
  void initState() {
    super.initState();
    Get.find<PaymentController>().getTopupRequests();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<PaymentController>(
      builder: (paymentController) {
        if (paymentController.topupRequests == null) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (paymentController.topupRequests!.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: Text(
                'no_topup_requests_found'.tr,
                style: robotoRegular.copyWith(color: Theme.of(context).disabledColor),
              ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: paymentController.topupRequests!.length,
          itemBuilder: (context, index) {
            WalletTopupRequestModel request = paymentController.topupRequests![index];
            Color statusColor;
            String statusText;

            if (request.status == 'approved') {
              statusColor = Colors.green;
              statusText = 'approved'.tr;
            } else if (request.status == 'rejected') {
              statusColor = Theme.of(context).colorScheme.error;
              statusText = 'rejected'.tr;
            } else {
              statusColor = Colors.amber.shade800;
              statusText = 'pending'.tr;
            }

            return Container(
              margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
              padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                border: Border.all(color: Theme.of(context).disabledColor.withValues(alpha: 0.15)),
                boxShadow: Get.isDarkMode
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.grey[200]!,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        PriceConverterHelper.convertPrice(request.amount),
                        style: robotoBold.copyWith(
                          fontSize: Dimensions.fontSizeLarge,
                          color: Theme.of(context).primaryColor,
                        ),
                        textDirection: TextDirection.ltr,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Dimensions.paddingSizeSmall,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                          border: Border.all(color: statusColor, width: 0.8),
                        ),
                        child: Text(
                          statusText,
                          style: robotoMedium.copyWith(
                            fontSize: Dimensions.fontSizeExtraSmall,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                  if (request.paymentMethod != null) ...[
                    Text(
                      '${'payment_method'.tr}: ${request.paymentMethod!.methodName ?? ''}',
                      style: robotoRegular.copyWith(
                        fontSize: Dimensions.fontSizeSmall,
                        color: Theme.of(context).disabledColor,
                      ),
                    ),
                  ],
                  if (request.createdAt != null) ...[
                    Text(
                      request.createdAt!,
                      style: robotoRegular.copyWith(
                        fontSize: Dimensions.fontSizeExtraSmall,
                        color: Theme.of(context).disabledColor,
                      ),
                    ),
                  ],
                  if (request.status == 'rejected' &&
                      request.rejectionReason != null &&
                      request.rejectionReason!.isNotEmpty) ...[
                    const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                    Container(
                      padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.error.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                      ),
                      child: Text(
                        '${'rejection_reason'.tr}: ${request.rejectionReason}',
                        style: robotoRegular.copyWith(
                          fontSize: Dimensions.fontSizeExtraSmall,
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}
