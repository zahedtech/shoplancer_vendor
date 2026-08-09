import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shoplancer_vendor/common/widgets/custom_app_bar_widget.dart';
import 'package:shoplancer_vendor/features/auth/controllers/auth_controller.dart';
import 'package:shoplancer_vendor/features/pos/data/local/pos_local_db.dart';
import 'package:shoplancer_vendor/features/pos/data/local/pos_sync_service.dart';
import 'package:shoplancer_vendor/features/profile/controllers/profile_controller.dart';
import 'package:shoplancer_vendor/helper/route_helper.dart';
import 'package:shoplancer_vendor/util/dimensions.dart';
import 'package:shoplancer_vendor/util/styles.dart';

/// Lightweight settings screen for the desktop cashier app: connection/sync
/// status, store info, and sign-out. Kept intentionally small — this is the
/// POS shell, not the full mobile settings screen.
class DesktopSettingsScreen extends StatelessWidget {
  const DesktopSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profileController = Get.find<ProfileController>();
    final bool hasSync = PosLocalDb.instance.isSupportedPlatform && Get.isRegistered<PosSyncService>();

    return Scaffold(
      appBar: CustomAppBarWidget(title: 'الإعدادات'.tr, isBackButtonExist: true),
      body: ListView(
        padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
        children: [
          Text('المتجر'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
              child: Text(
                profileController.profileModel?.stores?.isNotEmpty == true
                    ? (profileController.profileModel!.stores![0].name ?? '')
                    : '-',
                style: robotoMedium.copyWith(fontSize: 15),
              ),
            ),
          ),
          const SizedBox(height: 20),

          if (hasSync) ...[
            Text('حالة الاتصال والمزامنة'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
            const SizedBox(height: 8),
            Obx(() {
              final sync = Get.find<PosSyncService>();
              final bool online = sync.isOnlineRx.value;
              final int pending = sync.pendingCountRx.value;
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(online ? Icons.wifi : Icons.wifi_off, color: online ? Colors.green : Colors.red, size: 20),
                          const SizedBox(width: 8),
                          Text(online ? 'متصل بالإنترنت'.tr : 'غير متصل — العمل أوفلاين'.tr, style: robotoMedium),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.sync, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            pending == 0 ? 'كل العمليات متزامنة'.tr : '$pending ${'عملية بانتظار المزامنة'.tr}',
                            style: robotoMedium,
                          ),
                          const Spacer(),
                          if (pending > 0)
                            TextButton(
                              onPressed: () => sync.syncNow(),
                              child: Text('مزامنة الآن'.tr),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 20),
          ],

          Text('الحساب'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: Text('تسجيل الخروج'.tr, style: robotoMedium.copyWith(color: Colors.red)),
              onTap: () {
                Get.dialog(
                  AlertDialog(
                    title: Text('تسجيل الخروج'.tr),
                    content: Text('هل أنت متأكد من تسجيل الخروج؟'.tr),
                    actions: [
                      TextButton(onPressed: () => Get.back(), child: Text('إلغاء'.tr)),
                      ElevatedButton(
                        onPressed: () {
                          Get.back();
                          Get.find<AuthController>().clearSharedData();
                          Get.offAllNamed(RouteHelper.getSignInRoute());
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        child: Text('تسجيل الخروج'.tr),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
