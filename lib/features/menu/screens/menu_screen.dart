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

    bool isEcommerce = store?.module?.moduleType == 'ecommerce';

    // ------------------- 1. Products & Inventory (المنتجات والمخزون) -------------------
    if (modulePermission!.item!) {
      menuList.add(
        MenuModel(
          icon: '',
          iconData: Icons.inventory_rounded,
          title: 'إدارة المنتجات',
          route: RouteHelper.getProductManagementRoute(),
          isBlocked: !(store?.itemSection ?? false),
        ),
      );

      menuList.add(
        MenuModel(
          icon: '',
          iconData: Icons.price_change_rounded,
          title: 'تعديل الأسعار السريع',
          route: RouteHelper.getProductPriceUpdateRoute(),
          isBlocked: !(store?.itemSection ?? false),
        ),
      );

      if (!isEcommerce) {
        menuList.add(
          MenuModel(
            icon: '',
            iconData: Icons.grid_view_rounded,
            title: 'all_items'.tr,
            route: RouteHelper.getAllItemsRoute(),
            isBlocked: !store!.itemSection!,
          ),
        );
      }
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

    if (store?.module!.moduleType == 'food' && modulePermission.addon!) {
      menuList.add(
        MenuModel(
          icon: Images.addon,
          title: 'addons'.tr,
          route: RouteHelper.getAddonsRoute(),
        ),
      );
    }

    // // ------------------- 2. Marketing & Operations (التسويق والعمليات) -------------------
    // if (modulePermission.coupon!) {
    //   menuList.add(
    //     MenuModel(
    //       icon: Images.coupon,
    //       title: 'coupon'.tr,
    //       route: RouteHelper.getCouponRoute(),
    //     ),
    //   );
    // }

    if (modulePermission.banner!) {
      menuList.add(
        MenuModel(
          icon: Images.bannerIcon,
          title: 'banner'.tr,
          route: RouteHelper.getBannerListRoute(),
        ),
      );
    }

    menuList.add(
      MenuModel(
        icon: Images.adsMenu,
        title: 'social_media'.tr,
        route: RouteHelper.getSocialMediaRoute(),
      ),
    );

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

    if (modulePermission.expenseReport! || modulePermission.vatReport!) {
      menuList.add(
        MenuModel(
          icon: Images.expense,
          title: 'reports'.tr,
          route: RouteHelper.getReportsRoute(),
        ),
      );
    }

    // ------------------- 3. Settings & Account (الإعدادات والحساب والدعم) -------------------
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
      menuList.add(
        MenuModel(
          icon: Images.wallet,
          title: 'payment_method'.tr,
          route: '',
          isPaymentMethods: true,
        ),
      );
    }

    if (modulePermission.businessPlan! && !GetPlatform.isIOS) {
      menuList.add(
        MenuModel(
          icon: Images.mySubscriptionIcon,
          title: 'my_business_plan'.tr,
          route: RouteHelper.getMySubscriptionRoute(),
        ),
      );
    }

    menuList.add(
      MenuModel(
        icon: '',
        title: 'edit_profile'.tr,
        route: RouteHelper.getUpdateProfileRoute(),
      ),
    );

    menuList.add(
      MenuModel(
        icon: Images.settingIcon,
        title: 'settings'.tr,
        route: RouteHelper.getSettingRoute(),
      ),
    );

    menuList.add(
      MenuModel(
        icon: Images.whatsapp,
        title: 'الدعم الفني',
        route: 'https://wa.me/+201036860264',
        isWhatsApp: true,
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
              isProfile:
                  menuList[index].route == RouteHelper.getUpdateProfileRoute(),
              isLogout: false,
            );
          },
        ),
      ),
    );
  }
}
