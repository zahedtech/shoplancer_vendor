import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shoplancer_vendor/common/widgets/custom_app_bar_widget.dart';
import 'package:shoplancer_vendor/features/profile/controllers/profile_controller.dart';
import 'package:shoplancer_vendor/features/profile/domain/models/profile_model.dart';
import 'package:shoplancer_vendor/util/dimensions.dart';
import 'package:shoplancer_vendor/util/styles.dart';
import 'package:url_launcher/url_launcher.dart';

class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  InAppWebViewController? _webViewController;
  PullToRefreshController? _pullToRefreshController;
  double _progress = 0;
  bool _isLoading = true;
  String? _storeUrl;

  @override
  void initState() {
    super.initState();
    _initData();

    _pullToRefreshController = PullToRefreshController(
      settings: PullToRefreshSettings(
        color: Colors.purple,
      ),
      onRefresh: () async {
        if (defaultTargetPlatform == TargetPlatform.android) {
          _webViewController?.reload();
        } else if (defaultTargetPlatform == TargetPlatform.iOS) {
          _webViewController?.loadUrl(
            urlRequest: URLRequest(url: await _webViewController?.getUrl()),
          );
        }
      },
    );
  }

  Future<void> _initData() async {
    final profileController = Get.find<ProfileController>();
    if (profileController.profileModel == null) {
      await profileController.getProfile();
    }
    _resolvedStoreUrl(profileController);
  }

  void _resolvedStoreUrl(ProfileController profileController) {
    final profile = profileController.profileModel;
    if (profile != null) {
      String url = '';
      if (profile.storeUrl != null && profile.storeUrl!.trim().isNotEmpty) {
        url = profile.storeUrl!.trim();
      } else if (profile.stores != null && profile.stores!.isNotEmpty) {
        final store = profile.stores![0];
        final rawSlug = (store.slug?.trim().isNotEmpty ?? false) ? store.slug : store.name;
        if (rawSlug != null && rawSlug.trim().isNotEmpty) {
          url = 'https://store.shoplanser.com/${Uri.encodeComponent(rawSlug.trim())}';
        }
      }
      if (mounted && url.isNotEmpty) {
        setState(() {
          _storeUrl = url;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProfileController>(
      builder: (profileController) {
        final profile = profileController.profileModel;
        final String storeName = (profile?.stores != null && profile!.stores!.isNotEmpty)
            ? (profile.stores![0].name ?? 'my_store'.tr)
            : 'my_store'.tr;

        if (_storeUrl == null && profile != null) {
          _resolvedStoreUrl(profileController);
        }

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) async {
            if (_webViewController != null && await _webViewController!.canGoBack()) {
              _webViewController!.goBack();
            }
          },
          child: Scaffold(
            appBar: CustomAppBarWidget(
              title: storeName,
              isBackButtonExist: false,
              menuWidget: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.refresh, color: Theme.of(context).primaryColor),
                    onPressed: () {
                      _webViewController?.reload();
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.share, color: Theme.of(context).primaryColor),
                    onPressed: () {
                      if (_storeUrl != null && _storeUrl!.isNotEmpty) {
                        Share.share(_storeUrl!);
                      }
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.open_in_browser, color: Theme.of(context).primaryColor),
                    onPressed: () async {
                      if (_storeUrl != null && _storeUrl!.isNotEmpty) {
                        final uri = Uri.parse(_storeUrl!);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
            body: Stack(
              children: [
                if (_storeUrl != null && _storeUrl!.isNotEmpty)
                  InAppWebView(
                    initialUrlRequest: URLRequest(url: WebUri(_storeUrl!)),
                    initialSettings: InAppWebViewSettings(
                      useShouldOverrideUrlLoading: true,
                      mediaPlaybackRequiresUserGesture: false,
                      javaScriptEnabled: true,
                      domStorageEnabled: true,
                      databaseEnabled: true,
                      supportZoom: true,
                      transparentBackground: true,
                      isInspectable: kDebugMode,
                    ),
                    pullToRefreshController: _pullToRefreshController,
                    onWebViewCreated: (controller) {
                      _webViewController = controller;
                    },
                    onLoadStart: (controller, url) {
                      setState(() {
                        _isLoading = true;
                      });
                    },
                    onLoadStop: (controller, url) async {
                      _pullToRefreshController?.endRefreshing();
                      setState(() {
                        _isLoading = false;
                      });
                    },
                    onProgressChanged: (controller, progress) {
                      if (progress == 100) {
                        _pullToRefreshController?.endRefreshing();
                      }
                      setState(() {
                        _progress = progress / 100;
                      });
                    },
                  )
                else if (profileController.isLoading)
                  const Center(child: CircularProgressIndicator())
                else
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.storefront_outlined, size: 64, color: Colors.grey),
                        const SizedBox(height: Dimensions.paddingSizeDefault),
                        Text(
                          'store_link_not_found'.tr,
                          style: robotoMedium.copyWith(color: Theme.of(context).disabledColor),
                        ),
                        const SizedBox(height: Dimensions.paddingSizeDefault),
                        ElevatedButton(
                          onPressed: () => _initData(),
                          child: Text('retry'.tr),
                        ),
                      ],
                    ),
                  ),

                if (_isLoading && _progress < 1.0)
                  LinearProgressIndicator(
                    value: _progress > 0 ? _progress : null,
                    backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    color: Theme.of(context).primaryColor,
                    minHeight: 3,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
