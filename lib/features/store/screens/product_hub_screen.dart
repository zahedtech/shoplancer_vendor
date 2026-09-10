import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shoplancer_vendor/common/widgets/custom_app_bar_widget.dart';
import 'package:shoplancer_vendor/common/widgets/custom_snackbar_widget.dart';
import 'package:shoplancer_vendor/features/auth/domain/models/module_permission_model.dart';
import 'package:shoplancer_vendor/features/profile/controllers/profile_controller.dart';
import 'package:shoplancer_vendor/features/profile/domain/models/profile_model.dart';
import 'package:shoplancer_vendor/features/subscription/controllers/subscription_controller.dart';
import 'package:shoplancer_vendor/helper/responsive_helper.dart';
import 'package:shoplancer_vendor/helper/route_helper.dart';
import 'package:shoplancer_vendor/util/dimensions.dart';
import 'package:shoplancer_vendor/util/images.dart';
import 'package:shoplancer_vendor/util/styles.dart';

class ProductHubItemModel {
  final String title;
  final String description;
  final String route;
  final IconData iconData;
  final String? imageAsset;
  final Color color;
  final bool isBlocked;
  final bool isNotSubscribe;

  ProductHubItemModel({
    required this.title,
    required this.description,
    required this.route,
    required this.iconData,
    this.imageAsset,
    required this.color,
    this.isBlocked = false,
    this.isNotSubscribe = false,
  });
}

class ProductHubScreen extends StatelessWidget {
  const ProductHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Store? store = Get.find<ProfileController>().profileModel != null
        ? Get.find<ProfileController>().profileModel!.stores![0]
        : null;
    ModulePermissionModel? modulePermission =
        Get.find<ProfileController>().modulePermission;

    final List<ProductHubItemModel> items = [];

    bool isEcommerce = store?.module?.moduleType == 'ecommerce';
    bool isBlocked = !(store?.itemSection ?? false);

    if (modulePermission != null) {
      // 1. إدارة المنتجات (الرئيسية)
      if (modulePermission.item!) {
        items.add(
          ProductHubItemModel(
            title: 'إدارة المنتجات',
            description: 'تحكم شامل، باركود، وتعديل فوري للأسعار',
            route: RouteHelper.getProductManagementRoute(),
            iconData: Icons.inventory_2_rounded,
            color: const Color(0xFF2563EB),
            isBlocked: isBlocked,
          ),
        );

        // 2. إضافة منتج جديد
        items.add(
          ProductHubItemModel(
            title: 'add_new_product'.tr,
            description: 'إضافة صنف أو منتج جديد إلى متجرك',
            route: RouteHelper.getAddItemRoute(null),
            iconData: Icons.add_circle_outline_rounded,
            imageAsset: Images.addFood,
            color: const Color(0xFF10B981),
            isBlocked: isBlocked,
          ),
        );

        // 3. تعديل الأسعار السريع
        items.add(
          ProductHubItemModel(
            title: 'quick_price_update'.tr,
            description: 'تحديث أسعار المنتجات بشكل جماعي وسريع',
            route: RouteHelper.getProductPriceUpdateCategoriesRoute(),
            iconData: Icons.price_change_rounded,
            color: const Color(0xFF8B5CF6),
            isBlocked: isBlocked,
          ),
        );
      }

      // 4. الأقسام والتصنيفات
      if (modulePermission.category!) {
        items.add(
          ProductHubItemModel(
            title: 'categories'.tr,
            description: 'إدارة وتنسيق أقسام وتصنيفات المتجر',
            route: RouteHelper.getCategoriesRoute(),
            iconData: Icons.category_rounded,
            imageAsset: Images.categories,
            color: const Color(0xFFF59E0B),
          ),
        );
      }

      // 5. نواقص المخزون
      if (store?.module?.moduleType != 'food') {
        items.add(
          ProductHubItemModel(
            title: 'low_stock'.tr,
            description: 'متابعة المنتجات التي قاربت على النفاد',
            route: RouteHelper.getLowStockRoute(),
            iconData: Icons.warning_amber_rounded,
            imageAsset: Images.warning,
            color: const Color(0xFFEF4444),
          ),
        );
      }

      // 6. المنتجات غير النشطة
      if (modulePermission.item!) {
        items.add(
          ProductHubItemModel(
            title: 'inactive_products'.tr,
            description: 'عرض المنتجات المتوقفة وإعادة تفعيلها',
            route: RouteHelper.getInactiveProductsRoute(),
            iconData: Icons.pause_circle_outline_rounded,
            color: const Color(0xFF64748B),
            isBlocked: isBlocked,
          ),
        );
      }

      // 7. الماركات
      if (modulePermission.category!) {
        items.add(
          ProductHubItemModel(
            title: 'brands_management'.tr,
            description: 'إدارة الماركات والعلامات التجارية',
            route: RouteHelper.getBrandsRoute(),
            iconData: Icons.branding_watermark_rounded,
            color: const Color(0xFF0EA5E9),
          ),
        );
      }

      // 8. كل المنتجات (قائمة)
      if (modulePermission.item! && !isEcommerce) {
        items.add(
          ProductHubItemModel(
            title: 'all_items'.tr,
            description: 'استعراض جميع المنتجات في شكل قائمة',
            route: RouteHelper.getAllItemsRoute(),
            iconData: Icons.grid_view_rounded,
            color: const Color(0xFF6366F1),
            isBlocked: isBlocked,
          ),
        );
      }

      // 9. المنتجات المعلقة
      if (modulePermission.item! && !isEcommerce) {
        items.add(
          ProductHubItemModel(
            title: 'pending_item'.tr,
            description: 'مراجعة المنتجات في انتظار الموافقة',
            route: RouteHelper.getPendingItemRoute(),
            iconData: Icons.pending_actions_rounded,
            imageAsset: Images.pendingItemIcon,
            color: const Color(0xFFF97316),
          ),
        );
      }

      // 10. الإضافات (للمطاعم)
      if (store?.module?.moduleType == 'food' && modulePermission.addon!) {
        items.add(
          ProductHubItemModel(
            title: 'addons'.tr,
            description: 'إدارة الإضافات والخيارات للوجبات',
            route: RouteHelper.getAddonsRoute(),
            iconData: Icons.extension_rounded,
            imageAsset: Images.addon,
            color: const Color(0xFFEC4899),
          ),
        );
      }
    }

    return Scaffold(
      backgroundColor: Theme.of(context).cardColor,
      appBar: CustomAppBarWidget(title: 'products_control'.tr),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: ResponsiveHelper.isTab(context) ? 3 : 2,
                childAspectRatio: ResponsiveHelper.isTab(context) ? 1.35 : 1.15,
                crossAxisSpacing: Dimensions.paddingSizeDefault,
                mainAxisSpacing: Dimensions.paddingSizeDefault,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return _buildProductHubCard(context, item);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductHubCard(BuildContext context, ProductHubItemModel item) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (item.isBlocked) {
            showCustomSnackBar('this_feature_is_blocked_by_admin'.tr);
          } else if (item.isNotSubscribe) {
            showCustomSnackBar('you_have_no_available_subscription'.tr);
          } else {
            if (!Get.find<SubscriptionController>().isTrialEndModalShown) {
              Get.find<SubscriptionController>()
                  .trialEndBottomSheet()
                  .then((trialEnd) {
                if (trialEnd) {
                  Get.toNamed(item.route);
                } else {
                  Get.find<SubscriptionController>()
                      .setTrialEndModalShown(true);
                }
              });
            } else {
              Get.toNamed(item.route);
            }
          }
        },
        borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
        child: Container(
          padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
            border: Border.all(
              color: Get.isDarkMode
                  ? const Color(0xFF2A2A2A)
                  : item.color.withOpacity(0.12),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Get.isDarkMode
                    ? Colors.black.withOpacity(0.3)
                    : item.color.withOpacity(0.06),
                blurRadius: 12,
                spreadRadius: 0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top Row: Icon container + Arrow
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: item.color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      item.iconData,
                      color: item.color,
                      size: 24,
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: Theme.of(context).disabledColor.withOpacity(0.5),
                  ),
                ],
              ),

              // Bottom Section: Title + Short Description
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: robotoBold.copyWith(
                      fontSize: Dimensions.fontSizeDefault,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.description,
                    style: robotoRegular.copyWith(
                      fontSize: Dimensions.fontSizeExtraSmall,
                      color: Theme.of(context).disabledColor,
                      height: 1.25,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
