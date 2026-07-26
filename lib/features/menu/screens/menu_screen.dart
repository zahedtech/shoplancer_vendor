import 'package:shoplancer_vendor/common/widgets/custom_app_bar_widget.dart';
import 'package:shoplancer_vendor/features/auth/domain/models/module_permission_model.dart';
import 'package:shoplancer_vendor/features/profile/controllers/profile_controller.dart';
import 'package:shoplancer_vendor/features/splash/controllers/splash_controller.dart';
import 'package:shoplancer_vendor/features/menu/domain/models/menu_model.dart';
import 'package:shoplancer_vendor/helper/responsive_helper.dart';
import 'package:shoplancer_vendor/helper/route_helper.dart';
import 'package:shoplancer_vendor/util/dimensions.dart';
import 'package:shoplancer_vendor/util/images.dart';
import 'package:shoplancer_vendor/features/menu/widgets/menu_button_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shoplancer_vendor/features/profile/domain/models/profile_model.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Store? store = Get.find<ProfileController>().profileModel != null
        ? Get.find<ProfileController>().profileModel!.stores![0]
        : null;
    ModulePermissionModel? modulePermission =
        Get.find<ProfileController>().modulePermission;

    final List<MenuModel> menuList = [];

    menuList.add(
      MenuModel(
        icon: '',
        title: 'edit_profile'.tr,
        route: RouteHelper.getUpdateProfileRoute(),
      ),
    );

    bool isEcommerce = store?.module?.moduleType == 'ecommerce';

    if (modulePermission!.item!) {
      if (!isEcommerce) {
        menuList.add(
          MenuModel(
            icon: Images.addFood,
            title: 'all_items'.tr,
            route: RouteHelper.getAllItemsRoute(),
            isBlocked: !store!.itemSection!,
          ),
        );
      }
      menuList.add(
        MenuModel(
          icon: Images.disbursementIcon,
          title: 'إدارة المنتجات',
          route: RouteHelper.getProductManagementRoute(),
          isBlocked: !(store?.itemSection ?? false),
        ),
      );
    }

    if (modulePermission.item!) {
      if (!isEcommerce) {
        menuList.add(
          MenuModel(
            icon: Images.pendingItemIcon,
            title: 'pending_item'.tr,
            route: RouteHelper.getPendingItemRoute(),
          ),
        );
      }
    }

    if (modulePermission.storeSetup!) {
      menuList.add(
        MenuModel(
          icon: Images.settingIcon,
          title:
              Get.find<SplashController>()
                  .configModel!
                  .moduleConfig!
                  .module!
                  .showRestaurantText!
              ? 'restaurant_config'.tr
              : 'store_config'.tr,
          route: RouteHelper.getStoreSettingsRoute(store!),
        ),
      );
    }

    if (modulePermission.category!) {
      menuList.add(
        MenuModel(
          icon: Images.categories,
          title: 'categories'.tr,
          route: RouteHelper.getCategoriesRoute(),
        ),
      );
    }

    if (modulePermission.banner!) {
      menuList.add(
        MenuModel(
          icon: Images.bannerIcon,
          title: 'banner'.tr,
          route: RouteHelper.getBannerListRoute(),
        ),
      );
    }

    if (modulePermission.deliveryman! || modulePermission.deliverymanList!) {
      if (store?.selfDeliverySystem == 1 &&
          store?.storeBusinessModel != 'subscription') {
        menuList.add(
          MenuModel(
            icon: Images.deliveryMan,
            iconColor: Colors.white,
            title: 'delivery_man'.tr,
            route: RouteHelper.getDeliveryManRoute(),
          ),
        );
      } else if (store?.selfDeliverySystem == 1 &&
          store?.storeBusinessModel == 'subscription' &&
          (Get.find<ProfileController>()
                  .profileModel!
                  .subscription!
                  .selfDelivery ==
              1)) {
        menuList.add(
          MenuModel(
            icon: Images.deliveryMan,
            iconColor: Colors.white,
            title: 'delivery_man'.tr,
            route: RouteHelper.getDeliveryManRoute(),
            isNotSubscribe:
                store?.storeBusinessModel == 'subscription' &&
                Get.find<ProfileController>()
                        .profileModel!
                        .subscription!
                        .selfDelivery ==
                    0,
          ),
        );
      }
    }

    if (store?.module!.moduleType != 'food') {
      menuList.add(
        MenuModel(
          icon: Images.warning,
          iconColor: Colors.white,
          title: 'low_stock'.tr,
          route: RouteHelper.getLowStockRoute(),
        ),
      );
    }

    /*if (modulePermission.reviews!) {
      menuList.add(
        MenuModel(
          icon: Images.review,
          title: 'reviews'.tr,
          route: RouteHelper.getCustomerReviewRoute(),
          isNotSubscribe:
              store?.storeBusinessModel == 'subscription' &&
              Get.find<ProfileController>()
                      .profileModel!
                      .subscription!
                      .review ==
                  0,
        ),
      );
    }*/

    if (modulePermission.businessPlan!) {
      menuList.add(
        MenuModel(
          icon: Images.mySubscriptionIcon,
          title: 'my_business_plan'.tr,
          route: RouteHelper.getMySubscriptionRoute(),
        ),
      );
    }

    if (store?.module!.moduleType == 'food' && modulePermission.addon!) {
      menuList.add(
        MenuModel(
          icon: Images.addon,
          title: 'addons'.tr,
          route: RouteHelper.getAddonsRoute(),
        ),
      );
    }

    /*if (modulePermission.chat!) {
      menuList.add(
        MenuModel(
          icon: Images.chat,
          title: 'conversation'.tr,
          route: RouteHelper.getConversationListRoute(),
          isNotSubscribe:
              (store?.storeBusinessModel == 'subscription' &&
              Get.find<ProfileController>().profileModel!.subscription!.chat ==
                  0),
        ),
      );
    }*/

    menuList.add(
      MenuModel(
        icon: Images.whatsapp,
        title: 'الدعم الفني',
        route: 'https://wa.me/+201036860264',
        isWhatsApp: true,
      ),
    );

    menuList.add(
      MenuModel(
        icon: Images.adsMenu,
        title: 'social_media'.tr,
        route: RouteHelper.getSocialMediaRoute(),
      ),
    );

    // menuList.add(
    //   MenuModel(
    //     icon: Images.language,
    //     title: 'language'.tr,
    //     route: '',
    //     isLanguage: true,
    //   ),
    // );

    if (modulePermission.coupon!) {
      menuList.add(
        MenuModel(
          icon: Images.coupon,
          title: 'coupon'.tr,
          route: RouteHelper.getCouponRoute(),
        ),
      );
    }

    if (modulePermission.expenseReport! || modulePermission.vatReport!) {
      menuList.add(
        MenuModel(
          icon: Images.expense,
          title: 'reports'.tr,
          route: RouteHelper.getReportsRoute(),
        ),
      );
    }

    // if (modulePermission.disbursementReport! ||
    //     modulePermission.walletMethod!) {
    //   if (Get.find<SplashController>().configModel!.disbursementType ==
    //       'automated') {
    //     menuList.add(
    //       MenuModel(
    //         icon: Images.disbursementIcon,
    //         title: 'disbursement'.tr,
    //         route: RouteHelper.getDisbursementMenuRoute(),
    //       ),
    //     );
    //   }
    // }
    if (modulePermission.storeSetup!) {
      menuList.add(
        MenuModel(
          icon: Images.wallet,
          title: 'payment_method'.tr,
          route: '',
          isPaymentMethods: true,
        ),
      );
    }

    menuList.add(
      MenuModel(
        icon: Images.settingIcon,
        title: 'settings'.tr,
        route: RouteHelper.getSettingRoute(),
      ),
    );

    return Scaffold(
      backgroundColor: Theme.of(context).cardColor,
      appBar: CustomAppBarWidget(title: 'menu'.tr),
      body: Padding(
        padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            childAspectRatio: ResponsiveHelper.isTab(context)
                ? 1 / 1.5
                : (1 / 1.22),
            crossAxisSpacing: Dimensions.paddingSizeExtraSmall,
            mainAxisSpacing: Dimensions.paddingSizeExtraSmall,
          ),
          itemCount: menuList.length,
          itemBuilder: (context, index) {
            return MenuButtonWidget(
              menu: menuList[index],
              isProfile: index == 0,
              isLogout: false,
            );
          },
        ),
      ),
    );
  }
}
