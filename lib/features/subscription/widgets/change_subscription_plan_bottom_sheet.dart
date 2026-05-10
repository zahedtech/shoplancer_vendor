import 'package:card_swiper/card_swiper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart_store/common/widgets/custom_bottom_sheet_widget.dart';
import 'package:sixam_mart_store/common/widgets/custom_button_widget.dart';
import 'package:sixam_mart_store/features/auth/controllers/auth_controller.dart';
import 'package:sixam_mart_store/features/business/domain/models/package_model.dart';
import 'package:sixam_mart_store/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart_store/features/subscription/controllers/subscription_controller.dart';
import 'package:sixam_mart_store/features/subscription/widgets/renew_subscription_plan_bottom_sheet.dart';
import 'package:sixam_mart_store/features/subscription/widgets/subscription_dialog_widget.dart';
import 'package:sixam_mart_store/util/dimensions.dart';
import 'package:sixam_mart_store/util/images.dart';
import 'package:sixam_mart_store/util/styles.dart';

class ChangeSubscriptionPlanBottomSheet extends StatefulWidget {
  final bool businessIsCommission;
  const ChangeSubscriptionPlanBottomSheet({
    super.key,
    required this.businessIsCommission,
  });

  @override
  State<ChangeSubscriptionPlanBottomSheet> createState() =>
      _ChangeSubscriptionPlanBottomSheetState();
}

class _ChangeSubscriptionPlanBottomSheetState
    extends State<ChangeSubscriptionPlanBottomSheet> {
  SwiperController swiperController = SwiperController();
  int activePackageIndex = -1;
  bool isFirstTime = false;

  @override
  void initState() {
    super.initState();
    _fetchPackages();
  }

  Future<void> _fetchPackages() async {
    if (Get.find<SubscriptionController>().packageList == null) {
      isFirstTime = true;
    }
    await Get.find<SubscriptionController>().getPackageList().then((value) {
      if (Get.find<SubscriptionController>().packageList!.isNotEmpty) {
        Future.delayed(Duration(seconds: isFirstTime ? 1 : 0), () {
          swiperController.move(activePackageIndex);
        });
      }
    });
    Get.find<SubscriptionController>().initializeRenew();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SubscriptionController>(
      builder: (subscriptionController) {
        bool businessIsCommission =
            subscriptionController
                .profileModel!
                .stores![0]
                .storeBusinessModel ==
            'commission';
        bool businessIsUnsubscribed =
            subscriptionController
                .profileModel!
                .stores![0]
                .storeBusinessModel ==
            'unsubscribed';
        bool businessIsNone =
            subscriptionController
                .profileModel!
                .stores![0]
                .storeBusinessModel ==
            'none';
        bool isRentalModule =
            Get.find<AuthController>().getModuleType() == 'rental';

        if (subscriptionController.packageList != null) {
          for (var element in subscriptionController.packageList!) {
            if (subscriptionController.profileModel!.subscription != null) {
              if (subscriptionController
                      .profileModel!
                      .subscription!
                      .package!
                      .id ==
                  element.id) {
                activePackageIndex = subscriptionController.packageList!
                    .indexOf(element);
                if (kDebugMode) {
                  print('active package : $activePackageIndex');
                }
              }
            }
          }
        }

        return subscriptionController.packageList != null
            ? Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(Dimensions.radiusExtraLarge),
                    topRight: Radius.circular(Dimensions.radiusExtraLarge),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(
                        top: Dimensions.paddingSizeLarge,
                        bottom: Dimensions.paddingSizeDefault,
                      ),
                      height: 5,
                      width: 50,
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).disabledColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(
                          Dimensions.radiusSmall,
                        ),
                      ),
                    ),

                    Text(
                      (businessIsNone ||
                              (businessIsUnsubscribed &&
                                  (subscriptionController
                                          .profileModel
                                          ?.subscription ==
                                      null)))
                          ? 'chose_a_business'.tr
                          : 'change_subscription_plan'.tr,
                      style: robotoBold.copyWith(
                        fontSize: Dimensions.fontSizeLarge,
                      ),
                    ),
                    const SizedBox(height: Dimensions.paddingSizeDefault),

                    Text(
                      (businessIsNone ||
                              (businessIsUnsubscribed &&
                                  (subscriptionController
                                          .profileModel
                                          ?.subscription ==
                                      null)))
                          ? 'chose_a_business_plan_to_get_better_experience'.tr
                          : 'renew_or_shift_your_plan_to_get_better_experience'
                                .tr,
                      style: robotoRegular.copyWith(
                        fontSize: Dimensions.fontSizeSmall,
                        color: Theme.of(
                          context,
                        ).textTheme.bodyLarge!.color?.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(height: Dimensions.paddingSizeDefault),

                    // Primary Toggle: Commission vs Subscription
                    Container(
                      height: 45,
                      padding: const EdgeInsets.all(2),
                      margin: const EdgeInsets.symmetric(
                        horizontal: Dimensions.paddingSizeDefault,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(
                          Dimensions.radiusDefault,
                        ),
                        border: Border.all(
                          color: Theme.of(context).primaryColor,
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                subscriptionController.isSelectChange(
                                  false,
                                ); // Mode 0: Commission
                              },
                              child: Container(
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: !subscriptionController.isSelect
                                      ? Theme.of(context).primaryColor
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(
                                    Dimensions.radiusDefault - 2,
                                  ),
                                ),
                                child: Text(
                                  'commission'.tr,
                                  style: robotoMedium.copyWith(
                                    color: !subscriptionController.isSelect
                                        ? Colors.white
                                        : Theme.of(context).primaryColor,
                                    fontSize: Dimensions.fontSizeSmall,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 2),
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                subscriptionController.isSelectChange(
                                  true,
                                ); // Mode 1: Subscription
                              },
                              child: Container(
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: subscriptionController.isSelect
                                      ? Theme.of(context).primaryColor
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(
                                    Dimensions.radiusDefault - 2,
                                  ),
                                ),
                                child: Text(
                                  'subscription'.tr,
                                  style: robotoMedium.copyWith(
                                    color: subscriptionController.isSelect
                                        ? Colors.white
                                        : Theme.of(context).primaryColor,
                                    fontSize: Dimensions.fontSizeSmall,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: Dimensions.paddingSizeLarge),

                    if (subscriptionController.isSelect) ...[
                      Container(
                        height: 45,
                        padding: const EdgeInsets.all(4),
                        margin: const EdgeInsets.symmetric(
                          horizontal: Dimensions.paddingSizeDefault,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).disabledColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(
                            Dimensions.radiusDefault,
                          ),
                        ),
                        child: Row(
                          children: [
                            _subscriptionTypeButton(
                              subscriptionController,
                              0,
                              '1_to_3_month'.tr,
                            ),
                            const SizedBox(width: 4),
                            _subscriptionTypeButton(
                              subscriptionController,
                              1,
                              '4_to_6_month'.tr,
                            ),
                            const SizedBox(width: 4),
                            _subscriptionTypeButton(
                              subscriptionController,
                              2,
                              'more_than_6_month'.tr,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: Dimensions.paddingSizeDefault),
                    ],

                    Expanded(
                      child: !subscriptionController.isSelect
                          ? ListView.builder(
                              itemCount: 1,
                              padding: const EdgeInsets.symmetric(
                                horizontal: Dimensions.paddingSizeDefault,
                              ),
                              itemBuilder: (context, index) {
                                Packages package = Packages(
                                  id: -1,
                                  packageName: 'commission_base_plan'.tr,
                                  price: Get.find<SplashController>()
                                      .configModel!
                                      .adminCommission,
                                  description:
                                      'vendor_will_give_admin_commission_each_order'
                                          .tr,
                                );
                                bool isCommission = true;
                                bool isSelected = widget.businessIsCommission;

                                return Container(
                                  margin: const EdgeInsets.only(
                                    bottom: Dimensions.paddingSizeLarge,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Theme.of(
                                            context,
                                          ).primaryColor.withValues(alpha: 0.05)
                                        : Theme.of(context).cardColor,
                                    borderRadius: BorderRadius.circular(
                                      Dimensions.radiusLarge,
                                    ),
                                    border: Border.all(
                                      color: isSelected
                                          ? Theme.of(context).primaryColor
                                          : Theme.of(context).disabledColor
                                                .withValues(alpha: 0.2),
                                      width: isSelected ? 2 : 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: isSelected
                                            ? Theme.of(context).primaryColor
                                                  .withValues(alpha: 0.1)
                                            : Colors.black.withValues(
                                                alpha: 0.03,
                                              ),
                                        blurRadius: 10,
                                        spreadRadius: 0,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(
                                          Dimensions.paddingSizeLarge,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? Theme.of(context).primaryColor
                                              : Theme.of(context).disabledColor
                                                    .withValues(alpha: 0.05),
                                          borderRadius:
                                              const BorderRadius.vertical(
                                                top: Radius.circular(
                                                  Dimensions.radiusLarge - 2,
                                                ),
                                              ),
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    package.packageName ?? '',
                                                    style: robotoBold.copyWith(
                                                      fontSize: Dimensions
                                                          .fontSizeLarge,
                                                      color: isSelected
                                                          ? Theme.of(
                                                              context,
                                                            ).cardColor
                                                          : Theme.of(context)
                                                                .textTheme
                                                                .bodyLarge
                                                                ?.color,
                                                    ),
                                                  ),
                                                  const SizedBox(
                                                    height: Dimensions
                                                        .paddingSizeExtraSmall,
                                                  ),
                                                  Text(
                                                    '${package.price}%',
                                                    style: robotoBold.copyWith(
                                                      fontSize: 22,
                                                      color: isSelected
                                                          ? Theme.of(
                                                              context,
                                                            ).cardColor
                                                          : Theme.of(
                                                              context,
                                                            ).primaryColor,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            if (isSelected)
                                              Container(
                                                padding: const EdgeInsets.all(
                                                  4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Theme.of(
                                                    context,
                                                  ).cardColor,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(
                                                  Icons.check,
                                                  color: Theme.of(
                                                    context,
                                                  ).primaryColor,
                                                  size: 18,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(
                                          Dimensions.paddingSizeLarge,
                                        ),
                                        child: Text(
                                          package.description ?? '',
                                          style: robotoRegular.copyWith(
                                            color: Theme.of(context)
                                                .textTheme
                                                .bodyLarge
                                                ?.color
                                                ?.withValues(alpha: 0.7),
                                            fontSize: Dimensions.fontSizeSmall,
                                            height: 1.5,
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          left: Dimensions.paddingSizeLarge,
                                          right: Dimensions.paddingSizeLarge,
                                          bottom: Dimensions.paddingSizeLarge,
                                        ),
                                        child: !subscriptionController.isLoading
                                            ? CustomButtonWidget(
                                                color: isSelected
                                                    ? Theme.of(
                                                        context,
                                                      ).primaryColor
                                                    : Theme.of(context)
                                                          .disabledColor
                                                          .withValues(
                                                            alpha: 0.2,
                                                          ),
                                                textColor: isSelected
                                                    ? Colors.white
                                                    : Theme.of(context)
                                                          .textTheme
                                                          .bodyLarge
                                                          ?.color,
                                                buttonText: isSelected
                                                    ? 'current_plan'.tr
                                                    : 'shift_this_plan'.tr,
                                                radius:
                                                    Dimensions.radiusDefault,
                                                onPressed: isSelected
                                                    ? null
                                                    : () {
                                                        Get.dialog(
                                                          SubscriptionDialogWidget(
                                                            icon:
                                                                Images.support,
                                                            title:
                                                                'are_you_sure'
                                                                    .tr,
                                                            description:
                                                                'you_want_to_migrate_to_commission'
                                                                    .tr,
                                                            onYesPressed: () {
                                                              subscriptionController.renewBusinessPlan(
                                                                storeId: subscriptionController
                                                                    .profileModel!
                                                                    .stores![0]
                                                                    .id
                                                                    .toString(),
                                                                isCommission:
                                                                    true,
                                                              );
                                                            },
                                                          ),
                                                          useSafeArea: false,
                                                        );
                                                      },
                                              )
                                            : const Center(
                                                child: SizedBox(
                                                  height: 35,
                                                  width: 35,
                                                  child:
                                                      CircularProgressIndicator(
                                                        color: Colors.white,
                                                      ),
                                                ),
                                              ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            )
                          : subscriptionController.packageList!.isNotEmpty
                          ? ListView.builder(
                              itemCount: subscriptionController.packageList!
                                  .where((p) {
                                    int months = (p.validity ?? 0) ~/ 30;
                                    if (subscriptionController
                                            .subscriptionTypeIndex ==
                                        0)
                                      return months >= 1 && months <= 3;
                                    if (subscriptionController
                                            .subscriptionTypeIndex ==
                                        1)
                                      return months >= 4 && months <= 6;
                                    return months > 6;
                                  })
                                  .length,
                              padding: const EdgeInsets.symmetric(
                                horizontal: Dimensions.paddingSizeDefault,
                              ),
                              itemBuilder: (context, index) {
                                List<Packages> filteredList =
                                    subscriptionController.packageList!.where((
                                      p,
                                    ) {
                                      int months = (p.validity ?? 0) ~/ 30;
                                      if (subscriptionController
                                              .subscriptionTypeIndex ==
                                          0)
                                        return months >= 1 && months <= 3;
                                      if (subscriptionController
                                              .subscriptionTypeIndex ==
                                          1)
                                        return months >= 4 && months <= 6;
                                      return months > 6;
                                    }).toList();

                                Packages package = filteredList[index];
                                bool isCommission = package.id == -1;
                                int originalIndex = subscriptionController
                                    .packageList!
                                    .indexOf(package);
                                bool isSelected =
                                    subscriptionController
                                        .activeSubscriptionIndex ==
                                    originalIndex;

                                return Container(
                                  margin: const EdgeInsets.only(
                                    bottom: Dimensions.paddingSizeLarge,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Theme.of(
                                            context,
                                          ).primaryColor.withValues(alpha: 0.05)
                                        : Theme.of(context).cardColor,
                                    borderRadius: BorderRadius.circular(
                                      Dimensions.radiusLarge,
                                    ),
                                    border: Border.all(
                                      color: isSelected
                                          ? Theme.of(context).primaryColor
                                          : Theme.of(context).disabledColor
                                                .withValues(alpha: 0.2),
                                      width: isSelected ? 2 : 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: isSelected
                                            ? Theme.of(context).primaryColor
                                                  .withValues(alpha: 0.1)
                                            : Colors.black.withValues(
                                                alpha: 0.03,
                                              ),
                                        blurRadius: 10,
                                        spreadRadius: 0,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Header Section
                                      Container(
                                        padding: const EdgeInsets.all(
                                          Dimensions.paddingSizeLarge,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? Theme.of(context).primaryColor
                                              : Theme.of(context).disabledColor
                                                    .withValues(alpha: 0.05),
                                          borderRadius:
                                              const BorderRadius.vertical(
                                                top: Radius.circular(
                                                  Dimensions.radiusLarge - 2,
                                                ),
                                              ),
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    package.packageName ?? '',
                                                    style: robotoBold.copyWith(
                                                      fontSize: Dimensions
                                                          .fontSizeLarge,
                                                      color: isSelected
                                                          ? Theme.of(
                                                              context,
                                                            ).cardColor
                                                          : Theme.of(context)
                                                                .textTheme
                                                                .bodyLarge
                                                                ?.color,
                                                    ),
                                                  ),
                                                  const SizedBox(
                                                    height: Dimensions
                                                        .paddingSizeExtraSmall,
                                                  ),
                                                  Row(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment.end,
                                                    children: [
                                                      Text(
                                                        isCommission
                                                            ? '${package.price}%'
                                                            : 'EGP ${package.price}', // Assuming PriceConverterHelper logic is complex, simple symbol for now or use the helper
                                                        style: robotoBold.copyWith(
                                                          fontSize: 22,
                                                          color: isSelected
                                                              ? Theme.of(
                                                                  context,
                                                                ).cardColor
                                                              : Theme.of(
                                                                  context,
                                                                ).primaryColor,
                                                        ),
                                                      ),
                                                      if (!isCommission) ...[
                                                        const SizedBox(
                                                          width: Dimensions
                                                              .paddingSizeExtraSmall,
                                                        ),
                                                        Text(
                                                          '/ ${package.validity} ${package.validity! >= 365
                                                              ? 'yearly'.tr
                                                              : package.validity! >= 180
                                                              ? '6_month'.tr
                                                              : package.validity! >= 90
                                                              ? '3_month'.tr
                                                              : 'days'.tr}',
                                                          style: robotoRegular.copyWith(
                                                            fontSize: Dimensions
                                                                .fontSizeSmall,
                                                            color: isSelected
                                                                ? Theme.of(
                                                                        context,
                                                                      )
                                                                      .cardColor
                                                                      .withValues(
                                                                        alpha:
                                                                            0.8,
                                                                      )
                                                                : Theme.of(
                                                                    context,
                                                                  ).disabledColor,
                                                          ),
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                            if (isSelected)
                                              Container(
                                                padding: const EdgeInsets.all(
                                                  4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Theme.of(
                                                    context,
                                                  ).cardColor,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(
                                                  Icons.check,
                                                  color: Theme.of(
                                                    context,
                                                  ).primaryColor,
                                                  size: 18,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),

                                      // Features Section
                                      Padding(
                                        padding: const EdgeInsets.all(
                                          Dimensions.paddingSizeLarge,
                                        ),
                                        child: isCommission
                                            ? Text(
                                                package.description ?? '',
                                                style: robotoRegular.copyWith(
                                                  color: Theme.of(context)
                                                      .textTheme
                                                      .bodyLarge
                                                      ?.color
                                                      ?.withValues(alpha: 0.7),
                                                  fontSize:
                                                      Dimensions.fontSizeSmall,
                                                  height: 1.5,
                                                ),
                                              )
                                            : Column(
                                                children: [
                                                  _buildFeatureItem(
                                                    context,
                                                    '${isRentalModule ? 'max_trip'.tr : 'max_order'.tr} (${package.maxOrder?.tr})',
                                                  ),
                                                  _buildFeatureItem(
                                                    context,
                                                    '${isRentalModule ? 'max_vehicle'.tr : 'max_product'.tr} (${package.maxProduct?.tr})',
                                                  ),
                                                  if (package.pos != 0)
                                                    _buildFeatureItem(
                                                      context,
                                                      'pos'.tr,
                                                    ),
                                                  if (package.mobileApp != 0)
                                                    _buildFeatureItem(
                                                      context,
                                                      'mobile_app'.tr,
                                                    ),
                                                  if (package.chat != 0)
                                                    _buildFeatureItem(
                                                      context,
                                                      'chat'.tr,
                                                    ),
                                                  if (package.review != 0)
                                                    _buildFeatureItem(
                                                      context,
                                                      'review'.tr,
                                                    ),
                                                  if (package.selfDelivery != 0)
                                                    _buildFeatureItem(
                                                      context,
                                                      'self_delivery'.tr,
                                                    ),
                                                ],
                                              ),
                                      ),

                                      // Action Button Section
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          left: Dimensions.paddingSizeLarge,
                                          right: Dimensions.paddingSizeLarge,
                                          bottom: Dimensions.paddingSizeLarge,
                                        ),
                                        child: !subscriptionController.isLoading
                                            ? CustomButtonWidget(
                                                color: isSelected
                                                    ? Theme.of(
                                                        context,
                                                      ).primaryColor
                                                    : Theme.of(context)
                                                          .disabledColor
                                                          .withValues(
                                                            alpha: 0.2,
                                                          ),
                                                textColor: isSelected
                                                    ? Colors.white
                                                    : Theme.of(context)
                                                          .textTheme
                                                          .bodyLarge
                                                          ?.color,
                                                buttonText:
                                                    (subscriptionController
                                                                .isActivePackage !=
                                                            null &&
                                                        subscriptionController
                                                            .isActivePackage! &&
                                                        activePackageIndex !=
                                                            -1 &&
                                                        (!isCommission &&
                                                            !widget
                                                                .businessIsCommission))
                                                    ? 'renew'.tr
                                                    : (isCommission &&
                                                          widget
                                                              .businessIsCommission)
                                                    ? 'current_plan'.tr
                                                    : (businessIsNone ||
                                                          (businessIsUnsubscribed &&
                                                              (subscriptionController
                                                                      .profileModel
                                                                      ?.subscription ==
                                                                  null)))
                                                    ? 'purchase'.tr
                                                    : 'shift_this_plan'.tr,
                                                radius:
                                                    Dimensions.radiusDefault,
                                                onPressed:
                                                    (isCommission &&
                                                        widget
                                                            .businessIsCommission)
                                                    ? null
                                                    : () {
                                                        subscriptionController
                                                            .selectSubscriptionCard(
                                                              originalIndex,
                                                            );
                                                        subscriptionController
                                                            .activePackage(
                                                              activePackageIndex ==
                                                                  originalIndex,
                                                            );

                                                        if (((subscriptionController
                                                                        .isActivePackage! &&
                                                                    activePackageIndex !=
                                                                        -1) &&
                                                                (businessIsUnsubscribed ||
                                                                    businessIsNone)) ||
                                                            (businessIsUnsubscribed &&
                                                                (subscriptionController
                                                                        .profileModel!
                                                                        .subscription ==
                                                                    null) &&
                                                                (Get.find<
                                                                          SplashController
                                                                        >()
                                                                        .configModel!
                                                                        .subscriptionBusinessModel !=
                                                                    0) &&
                                                                (Get.find<
                                                                              AuthController
                                                                            >()
                                                                            .packageModel !=
                                                                        null &&
                                                                    Get.find<
                                                                          AuthController
                                                                        >()
                                                                        .packageModel!
                                                                        .packages!
                                                                        .isNotEmpty)) ||
                                                            businessIsNone) {
                                                          showCustomBottomSheet(
                                                            child: RenewSubscriptionPlanBottomSheet(
                                                              isRenew: true,
                                                              package: package,
                                                              checkProductLimitModel:
                                                                  null,
                                                              nonSubscription:
                                                                  businessIsNone ||
                                                                  (businessIsUnsubscribed &&
                                                                      (subscriptionController
                                                                              .profileModel
                                                                              ?.subscription ==
                                                                          null)),
                                                            ),
                                                          );
                                                        } else if ((isCommission &&
                                                                (businessIsUnsubscribed ||
                                                                    businessIsNone)) ||
                                                            isCommission) {
                                                          Get.dialog(
                                                            SubscriptionDialogWidget(
                                                              icon: Images
                                                                  .support,
                                                              title:
                                                                  'are_you_sure'
                                                                      .tr,
                                                              description:
                                                                  'you_want_to_migrate_to_commission'
                                                                      .tr,
                                                              onYesPressed: () {
                                                                subscriptionController.renewBusinessPlan(
                                                                  storeId: subscriptionController
                                                                      .profileModel!
                                                                      .stores![0]
                                                                      .id
                                                                      .toString(),
                                                                  isCommission:
                                                                      true,
                                                                );
                                                              },
                                                            ),
                                                            useSafeArea: false,
                                                          );
                                                        } else {
                                                          subscriptionController.getProductLimit(
                                                            storeId:
                                                                subscriptionController
                                                                    .profileModel!
                                                                    .stores![0]
                                                                    .id!,
                                                            packageId:
                                                                package.id!,
                                                            activePackage:
                                                                subscriptionController
                                                                    .packageList![businessIsCommission
                                                                    ? subscriptionController
                                                                          .activeSubscriptionIndex
                                                                    : activePackageIndex],
                                                            package: package,
                                                          );
                                                        }
                                                      },
                                              )
                                            : const Center(
                                                child: SizedBox(
                                                  height: 35,
                                                  width: 35,
                                                  child:
                                                      CircularProgressIndicator(
                                                        color: Colors.white,
                                                      ),
                                                ),
                                              ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            )
                          : Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [Text('no_package_available'.tr)],
                              ),
                            ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              )
            : const Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget _buildFeatureItem(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check,
              size: 14,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(width: Dimensions.paddingSizeSmall),
          Expanded(
            child: Text(
              title,
              style: robotoRegular.copyWith(
                fontSize: Dimensions.fontSizeSmall,
                color: Theme.of(
                  context,
                ).textTheme.bodyLarge?.color?.withValues(alpha: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _subscriptionTypeButton(
    SubscriptionController subscriptionController,
    int index,
    String text,
  ) {
    bool isSelected = subscriptionController.subscriptionTypeIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => subscriptionController.setSubscriptionTypeIndex(index),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Colors.transparent,
            borderRadius: BorderRadius.circular(Dimensions.radiusDefault - 2),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: robotoMedium.copyWith(
              color: isSelected
                  ? Colors.white
                  : Theme.of(context).disabledColor,
              fontSize: 11,
            ),
          ),
        ),
      ),
    );
  }
}
