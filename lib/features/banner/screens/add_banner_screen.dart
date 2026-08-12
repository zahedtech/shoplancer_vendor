import 'dart:io';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shoplancer_vendor/common/models/config_model.dart';
import 'package:shoplancer_vendor/common/widgets/custom_image_widget.dart';
import 'package:shoplancer_vendor/features/splash/controllers/splash_controller.dart';
import 'package:shoplancer_vendor/features/store/controllers/store_controller.dart';
import 'package:shoplancer_vendor/features/banner/controllers/banner_controller.dart';
import 'package:shoplancer_vendor/features/banner/domain/models/store_banner_list_model.dart';
import 'package:shoplancer_vendor/util/dimensions.dart';
import 'package:shoplancer_vendor/util/styles.dart';
import 'package:shoplancer_vendor/common/widgets/custom_app_bar_widget.dart';
import 'package:shoplancer_vendor/common/widgets/custom_button_widget.dart';
import 'package:shoplancer_vendor/common/widgets/custom_snackbar_widget.dart';
import 'package:shoplancer_vendor/common/widgets/custom_text_field_widget.dart';
import 'package:shoplancer_vendor/features/store/domain/models/item_model.dart';

class AddBannerScreen extends StatefulWidget {
  final StoreBannerListModel? storeBannerListModel;
  const AddBannerScreen({super.key, this.storeBannerListModel});

  @override
  State<AddBannerScreen> createState() => _AddBannerScreenState();
}

class _AddBannerScreenState extends State<AddBannerScreen>
    with TickerProviderStateMixin {
  static const String _bannerTypeImage = 'image';
  static const String _bannerTypeText = 'text';
  static const String _defaultBackgroundColor = '#00A082';
  static const List<String> backgroundColorOptions = [
    '#00A082',
    '#FF8A00',
    '#EF4444',
    '#2563EB',
    '#7C3AED',
    '#111827',
  ];

  final TextEditingController _urlController = TextEditingController();
  final List<TextEditingController> _titleController = [];
  final List<TextEditingController> _subtitleController = [];
  final TextEditingController _customColorController = TextEditingController();

  final List<FocusNode> _titleFocusNode = [];
  // ignore: unused_field
  final FocusNode _urlFocusNode = FocusNode();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final List<Language>? _languageList =
      Get.find<SplashController>().configModel!.language;

  late bool _update;
  late String _bannerType;
  late String _backgroundColorHex;
  StoreBannerListModel? _storeBannerListModel;

  @override
  void initState() {
    super.initState();
    Get.find<StoreController>().pickImage(true, true);
    _update = widget.storeBannerListModel != null;
    _storeBannerListModel = widget.storeBannerListModel;
    if (widget.storeBannerListModel != null) {
      bool isImage =
          widget.storeBannerListModel!.type == 'image' ||
          (widget.storeBannerListModel!.imageFullUrl ?? '').isNotEmpty;
      _bannerType = isImage ? _bannerTypeImage : _bannerTypeText;
    } else {
      _bannerType = _bannerTypeImage;
    }
    _backgroundColorHex =
        widget.storeBannerListModel?.backgroundColor ?? _defaultBackgroundColor;

    if (_update) {
      List<Translation> translation = _storeBannerListModel?.translations ?? [];
      for (int index = 0; index < _languageList!.length; index++) {
        _titleController.add(TextEditingController());
        _subtitleController.add(TextEditingController());
        _titleFocusNode.add(FocusNode());
        if (translation.isNotEmpty) {
          for (var t in translation) {
            if (_languageList[index].key == t.locale && t.key == 'title') {
              _titleController[index].text = t.value ?? '';
            }
            if (_languageList[index].key == t.locale && t.key == 'subtitle') {
              _subtitleController[index].text = t.value ?? '';
            }
          }
        }

        if (_titleController[index].text.isEmpty && index == 0) {
          _titleController[index].text = _storeBannerListModel?.title ?? '';
        }
        if (_subtitleController[index].text.isEmpty && index == 0) {
          _subtitleController[index].text =
              _storeBannerListModel?.subTitle ?? '';
        }
      }
    } else {
      for (int index = 0; index < _languageList!.length; index++) {
        _titleController.add(TextEditingController());
        _subtitleController.add(TextEditingController());
        _titleFocusNode.add(FocusNode());
      }
      _storeBannerListModel = StoreBannerListModel();
    }
    _urlController.text = widget.storeBannerListModel?.defaultLink ?? '';
    _customColorController.text = _backgroundColorHex;
  }

  @override
  void dispose() {
    _customColorController.dispose();
    _urlController.dispose();
    for (var controller in _titleController) {
      controller.dispose();
    }
    for (var controller in _subtitleController) {
      controller.dispose();
    }
    for (var node in _titleFocusNode) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBarWidget(
        title: _update ? 'update_banner'.tr : 'add_banner'.tr,
      ),

      body: GetBuilder<BannerController>(
        builder: (bannerController) {
          return GetBuilder<StoreController>(
            builder: (storeController) {
              return Column(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(
                        Dimensions.paddingSizeDefault,
                      ),
                      child: Form(
                        key: _formKey,
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('banner'.tr, style: robotoBold),
                              const SizedBox(
                                height: Dimensions.paddingSizeSmall,
                              ),
                              Container(
                                padding: const EdgeInsets.all(
                                  Dimensions.paddingSizeSmall,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(
                                    Dimensions.radiusDefault,
                                  ),
                                  border: Border.all(
                                    color: Theme.of(
                                      context,
                                    ).disabledColor.withValues(alpha: 0.2),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: InkWell(
                                        onTap: () {
                                          setState(() {
                                            _bannerType = _bannerTypeImage;
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            vertical:
                                                Dimensions.paddingSizeSmall,
                                          ),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              Dimensions.radiusDefault,
                                            ),
                                            color:
                                                _bannerType == _bannerTypeImage
                                                ? Theme.of(context).primaryColor
                                                : Colors.transparent,
                                            border: Border.all(
                                              color: Theme.of(context)
                                                  .disabledColor
                                                  .withValues(alpha: 0.3),
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              'image'.tr,
                                              style: robotoMedium.copyWith(
                                                color:
                                                    _bannerType ==
                                                        _bannerTypeImage
                                                    ? Colors.white
                                                    : Theme.of(context)
                                                          .textTheme
                                                          .bodyLarge
                                                          ?.color,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(
                                      width: Dimensions.paddingSizeSmall,
                                    ),
                                    Expanded(
                                      child: InkWell(
                                        onTap: () {
                                          setState(() {
                                            _bannerType = _bannerTypeText;
                                            storeController.pickImage(
                                              true,
                                              true,
                                            );
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            vertical:
                                                Dimensions.paddingSizeSmall,
                                          ),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              Dimensions.radiusDefault,
                                            ),
                                            color:
                                                _bannerType == _bannerTypeText
                                                ? Theme.of(context).primaryColor
                                                : Colors.transparent,
                                            border: Border.all(
                                              color: Theme.of(context)
                                                  .disabledColor
                                                  .withValues(alpha: 0.3),
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              'text'.tr,
                                              style: robotoMedium.copyWith(
                                                color:
                                                    _bannerType ==
                                                        _bannerTypeText
                                                    ? Colors.white
                                                    : Theme.of(context)
                                                          .textTheme
                                                          .bodyLarge
                                                          ?.color,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(
                                height: Dimensions.paddingSizeLarge,
                              ),

                              if (_bannerType == _bannerTypeText) ...[
                                RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: 'title'.tr,
                                        style: robotoBold.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).textTheme.bodyLarge?.color,
                                        ),
                                      ),
                                      TextSpan(
                                        text: ' *'.tr,
                                        style: robotoMedium.copyWith(
                                          color: Colors.red,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(
                                  height: Dimensions.paddingSizeSmall,
                                ),
                                Container(
                                  padding: const EdgeInsets.all(
                                    Dimensions.paddingSizeDefault,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(
                                      Dimensions.radiusDefault,
                                    ),
                                    border: Border.all(
                                      color: Theme.of(
                                        context,
                                      ).disabledColor.withValues(alpha: 0.2),
                                    ),
                                  ),
                                  child: CustomTextFieldWidget(
                                    hintText: 'enter_title'.tr,
                                    showLabelText: false,
                                    controller: _titleController[0],
                                    capitalization: TextCapitalization.words,
                                    focusNode: _titleFocusNode[0],
                                    inputAction: TextInputAction.done,
                                    showTitle: false,
                                    required: true,
                                    onChanged: (value) {
                                      setState(() {});
                                    },
                                    validator: (value) {
                                      if (_bannerType == _bannerTypeText) {
                                        if (value == null ||
                                            value.trim().isEmpty) {
                                          return 'enter_title'.tr;
                                        }
                                      }
                                      return null;
                                    },
                                  ),
                                ),

                                // if (false)
                                //   const SizedBox(
                                //     height: Dimensions.paddingSizeLarge,
                                //   ),
                                Text('subtitle'.tr, style: robotoBold),
                                const SizedBox(
                                  height: Dimensions.paddingSizeSmall,
                                ),
                                Container(
                                  padding: const EdgeInsets.all(
                                    Dimensions.paddingSizeDefault,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(
                                      Dimensions.radiusDefault,
                                    ),
                                    border: Border.all(
                                      color: Theme.of(
                                        context,
                                      ).disabledColor.withValues(alpha: 0.2),
                                    ),
                                  ),
                                  child: CustomTextFieldWidget(
                                    hintText: 'enter_subtitle'.tr,
                                    showLabelText: false,
                                    controller: _subtitleController[0],
                                    capitalization: TextCapitalization.words,
                                    inputAction: TextInputAction.done,
                                    showTitle: false,
                                    onChanged: (value) {
                                      setState(() {});
                                    },
                                  ),
                                ),
                                // if (false)
                                //   const SizedBox(
                                //     height: Dimensions.paddingSizeLarge,
                                //   ),

                                // if (false)
                                //   Text(
                                //     'banner_background_color'.tr,
                                //     style: robotoBold,
                                //   ),
                                // if (false)
                                //   const SizedBox(
                                //     height: Dimensions.paddingSizeSmall,
                                //   ),
                                // if (false)
                                //   Container(
                                //     width: double.infinity,
                                //     padding: const EdgeInsets.all(
                                //       Dimensions.paddingSizeDefault,
                                //     ),
                                //     decoration: BoxDecoration(
                                //       borderRadius: BorderRadius.circular(
                                //         Dimensions.radiusDefault,
                                //       ),
                                //       border: Border.all(
                                //         color: Theme.of(
                                //           context,
                                //         ).disabledColor.withValues(alpha: 0.2),
                                //       ),
                                //     ),
                                //     child: Column(
                                //       crossAxisAlignment:
                                //           CrossAxisAlignment.start,
                                //       children: [
                                //         Wrap(
                                //           spacing: Dimensions.paddingSizeSmall,
                                //           runSpacing:
                                //               Dimensions.paddingSizeSmall,
                                //           children: _backgroundColorOptions.map(
                                //             (colorHex) {
                                //               final bool isSelected =
                                //                   _backgroundColorHex ==
                                //                   colorHex;
                                //               final Color color = _colorFromHex(
                                //                 colorHex,
                                //               );

                                //               return InkWell(
                                //                 onTap: () {
                                //                   setState(() {
                                //                     _backgroundColorHex =
                                //                         colorHex;
                                //                     _customColorController
                                //                             .text =
                                //                         colorHex;
                                //                   });
                                //                 },
                                //                 borderRadius:
                                //                     BorderRadius.circular(
                                //                       Dimensions.radiusDefault,
                                //                     ),
                                //                 child: Container(
                                //                   height: 42,
                                //                   width: 42,
                                //                   alignment: Alignment.center,
                                //                   decoration: BoxDecoration(
                                //                     color: color,
                                //                     borderRadius:
                                //                         BorderRadius.circular(
                                //                           Dimensions
                                //                               .radiusDefault,
                                //                         ),
                                //                     border: Border.all(
                                //                       color: isSelected
                                //                           ? Theme.of(context)
                                //                                 .textTheme
                                //                                 .bodyLarge!
                                //                                 .color!
                                //                           : Colors.white
                                //                                 .withValues(
                                //                                   alpha: 0.5,
                                //                                 ),
                                //                       width: isSelected ? 2 : 1,
                                //                     ),
                                //                   ),
                                //                   child: isSelected
                                //                       ? const Icon(
                                //                           Icons.check,
                                //                           color: Colors.white,
                                //                           size: 20,
                                //                         )
                                //                       : null,
                                //                 ),
                                //               );
                                //             },
                                //           ).toList(),
                                //         ),
                                //         const SizedBox(
                                //           height: Dimensions.paddingSizeDefault,
                                //         ),
                                //         Row(
                                //           children: [
                                //             Expanded(
                                //               child: CustomTextFieldWidget(
                                //                 hintText: '#00A082',
                                //                 labelText:
                                //                     'custom_color_hex'.tr,
                                //                 controller:
                                //                     _customColorController,
                                //                 inputType: TextInputType.text,
                                //                 showLabelText: true,
                                //                 onChanged: (text) {
                                //                   if (text.startsWith('#') &&
                                //                       text.length == 7) {
                                //                     setState(() {
                                //                       _backgroundColorHex =
                                //                           text;
                                //                     });
                                //                   } else if (!text.startsWith(
                                //                         '#',
                                //                       ) &&
                                //                       text.length == 6) {
                                //                     setState(() {
                                //                       _backgroundColorHex =
                                //                           '#$text';
                                //                     });
                                //                   }
                                //                 },
                                //               ),
                                //             ),
                                //             const SizedBox(
                                //               width:
                                //                   Dimensions.paddingSizeSmall,
                                //             ),
                                //             InkWell(
                                //               onTap: () {
                                //                 _openColorPickerDialog();
                                //               },
                                //               child: Container(
                                //                 height: 50,
                                //                 width: 50,
                                //                 decoration: BoxDecoration(
                                //                   borderRadius:
                                //                       BorderRadius.circular(
                                //                         Dimensions
                                //                             .radiusDefault,
                                //                       ),
                                //                   color: _colorFromHex(
                                //                     _backgroundColorHex,
                                //                   ),
                                //                   border: Border.all(
                                //                     color: Theme.of(
                                //                       context,
                                //                     ).primaryColor,
                                //                     width: 2,
                                //                   ),
                                //                 ),
                                //                 child: const Icon(
                                //                   Icons.colorize,
                                //                   color: Colors.white,
                                //                 ),
                                //               ),
                                //             ),
                                //           ],
                                //         ),
                                //       ],
                                //     ),
                                //   ),
                                // if (false)
                                //   const SizedBox(
                                //     height: Dimensions.paddingSizeLarge,
                                //   ),

                                // Real-Time Preview
                                Text('live_preview'.tr, style: robotoBold),
                                const SizedBox(
                                  height: Dimensions.paddingSizeSmall,
                                ),
                                Container(
                                  height: 125,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(
                                      Dimensions.radiusDefault,
                                    ),
                                    gradient: LinearGradient(
                                      colors: [
                                        _colorFromHex(_backgroundColorHex),
                                        _colorFromHex(
                                          _backgroundColorHex,
                                        ).withValues(alpha: 0.72),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: _colorFromHex(
                                          _backgroundColorHex,
                                        ).withValues(alpha: 0.3),
                                        blurRadius: 10,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: Stack(
                                    children: [
                                      Positioned(
                                        top: -20,
                                        right: -20,
                                        child: Container(
                                          width: 100,
                                          height: 100,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.white.withValues(
                                              alpha: 0.08,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        bottom: -30,
                                        left: 10,
                                        child: Container(
                                          width: 80,
                                          height: 80,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.white.withValues(
                                              alpha: 0.05,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Center(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal:
                                                Dimensions.paddingSizeLarge,
                                          ),
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  _titleController[0]
                                                          .text
                                                          .isEmpty
                                                      ? 'your_banner_text_here'
                                                            .tr
                                                      : _titleController[0]
                                                            .text,
                                                  textAlign: TextAlign.center,
                                                  style: robotoBold.copyWith(
                                                    fontSize: 24,
                                                    color: Colors.white,
                                                    shadows: [
                                                      Shadow(
                                                        color: Colors.black
                                                            .withValues(
                                                              alpha: 0.25,
                                                            ),
                                                        offset: const Offset(
                                                          0,
                                                          2,
                                                        ),
                                                        blurRadius: 4,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  _subtitleController[0]
                                                          .text
                                                          .isEmpty
                                                      ? 'your_banner_subtitle_here'
                                                            .tr
                                                      : _subtitleController[0]
                                                            .text,
                                                  textAlign: TextAlign.center,
                                                  style: robotoRegular.copyWith(
                                                    fontSize: 14,
                                                    color: Colors.white
                                                        .withValues(alpha: 0.9),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        top: 8,
                                        left: 8,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(
                                              alpha: 0.2,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                width: 6,
                                                height: 6,
                                                decoration: const BoxDecoration(
                                                  color: Colors.greenAccent,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                'live'.tr.toUpperCase(),
                                                style: robotoMedium.copyWith(
                                                  fontSize: 8,
                                                  color: Colors.white,
                                                  letterSpacing: 1,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // if (false)
                                //   const SizedBox(
                                //     height: Dimensions.paddingSizeLarge,
                                //   ),
                              ],

                              if (_bannerType == _bannerTypeImage) ...[
                                RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: 'upload_banner'.tr,
                                        style: robotoBold.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).textTheme.bodyLarge?.color,
                                        ),
                                      ),
                                      TextSpan(
                                        text: ' *'.tr,
                                        style: robotoMedium.copyWith(
                                          color: Colors.red,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(
                                  height: Dimensions.paddingSizeSmall,
                                ),

                                Container(
                                  padding: const EdgeInsets.all(
                                    Dimensions.paddingSizeDefault,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(
                                      Dimensions.radiusDefault,
                                    ),
                                    border: Border.all(
                                      color: Theme.of(
                                        context,
                                      ).disabledColor.withValues(alpha: 0.5),
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      DottedBorder(
                                        options: RoundedRectDottedBorderOptions(
                                          color: Theme.of(context).disabledColor
                                              .withValues(alpha: 0.5),
                                          strokeWidth: 1,
                                          radius: const Radius.circular(
                                            Dimensions.radiusSmall,
                                          ),
                                        ),
                                        child: SizedBox(
                                          height: 125,
                                          width: Get.width,
                                          child: Align(
                                            alignment: Alignment.center,
                                            child: Stack(
                                              children: [
                                                ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        Dimensions.radiusSmall,
                                                      ),
                                                  child:
                                                      storeController.rawLogo !=
                                                          null
                                                      ? GetPlatform.isWeb
                                                            ? Image.network(
                                                                storeController
                                                                    .rawLogo!
                                                                    .path,
                                                                width:
                                                                    Get.width,
                                                                height: 125,
                                                                fit: BoxFit
                                                                    .cover,
                                                              )
                                                            : Image.file(
                                                                File(
                                                                  storeController
                                                                          .rawLogo
                                                                          ?.path ??
                                                                      '',
                                                                ),
                                                                width:
                                                                    Get.width,
                                                                height: 125,
                                                                fit: BoxFit
                                                                    .cover,
                                                              )
                                                      : widget.storeBannerListModel ==
                                                            null
                                                      ? SizedBox(
                                                          width: context.width,
                                                          height: 125,
                                                        )
                                                      : CustomImageWidget(
                                                          image:
                                                              widget
                                                                  .storeBannerListModel
                                                                  ?.imageFullUrl ??
                                                              '',
                                                          height: 125,
                                                          width: Get.width,
                                                          fit: BoxFit.cover,
                                                        ),
                                                ),

                                                Positioned(
                                                  right: 0,
                                                  left: 0,
                                                  top: 0,
                                                  bottom: 0,
                                                  child: InkWell(
                                                    onTap: () => storeController
                                                        .pickImage(true, false),
                                                    child: Column(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        if (storeController
                                                                    .rawLogo ==
                                                                null &&
                                                            (widget
                                                                        .storeBannerListModel
                                                                        ?.imageFullUrl ==
                                                                    null ||
                                                                widget
                                                                    .storeBannerListModel!
                                                                    .imageFullUrl!
                                                                    .isEmpty)) ...[
                                                          const Icon(
                                                            Icons.cloud_upload,
                                                            color: Colors.teal,
                                                          ),
                                                          const SizedBox(
                                                            height: Dimensions
                                                                .paddingSizeSmall,
                                                          ),
                                                          Text(
                                                            "drag_drop_file_or_browse_file"
                                                                .tr,
                                                            style: robotoRegular.copyWith(
                                                              color: Theme.of(
                                                                context,
                                                              ).disabledColor,
                                                              fontSize: Dimensions
                                                                  .fontSizeSmall,
                                                            ),
                                                          ),
                                                        ],
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(
                                        height: Dimensions.paddingSizeDefault,
                                      ),

                                      Align(
                                        alignment: Alignment.center,
                                        child: Text(
                                          "banner_images_ration_3:1".tr,
                                          style: robotoMedium.copyWith(
                                            fontSize: Dimensions.fontSizeSmall,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(
                                        height:
                                            Dimensions.paddingSizeExtraSmall,
                                      ),

                                      Align(
                                        alignment: Alignment.center,
                                        child: Text(
                                          "image_format_maximum_size_2mb".tr,
                                          style: robotoRegular.copyWith(
                                            fontSize: Dimensions.fontSizeSmall,
                                            color: Theme.of(context)
                                                .disabledColor
                                                .withValues(alpha: 0.5),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(
                        Dimensions.paddingSizeSmall,
                      ),
                      child: CustomButtonWidget(
                        isLoading: bannerController.isLoading,
                        buttonText: _update
                            ? 'update_banner'.tr
                            : 'add_banner'.tr,
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            bool isImageBanner =
                                _bannerType == _bannerTypeImage;
                            if (isImageBanner &&
                                !_update &&
                                storeController.rawLogo == null) {
                              showCustomSnackBar('upload_a_banner'.tr);
                            } else {
                              List<Translation> translations = [];
                              String titleText = isImageBanner
                                  ? 'Banner Image'
                                  : _titleController[0].text.trim();
                              String subtitleText = isImageBanner
                                  ? ''
                                  : _subtitleController[0].text.trim();
                              String defaultLinkText = 'https://example.com';

                              for (
                                int index = 0;
                                index < _languageList!.length;
                                index++
                              ) {
                                translations.add(
                                  Translation(
                                    locale: _languageList[index].key,
                                    key: 'title',
                                    value: titleText,
                                  ),
                                );
                                if (!isImageBanner) {
                                  translations.add(
                                    Translation(
                                      locale: _languageList[index].key,
                                      key: 'subtitle',
                                      value: subtitleText,
                                    ),
                                  );
                                }
                              }
                              _storeBannerListModel?.id =
                                  _storeBannerListModel?.id;
                              _storeBannerListModel?.translations = [];
                              _storeBannerListModel?.translations!.addAll(
                                translations,
                              );
                              _storeBannerListModel?.defaultLink =
                                  defaultLinkText;
                              _storeBannerListModel?.type = _bannerType;
                              _storeBannerListModel?.backgroundColor =
                                  isImageBanner ? null : _backgroundColorHex;
                              if (_update) {
                                bannerController.updateBanner(
                                  banner: _storeBannerListModel,
                                  image: isImageBanner
                                      ? storeController.rawLogo
                                      : null,
                                );
                              } else {
                                bannerController.addBanner(
                                  banner: _storeBannerListModel,
                                  image: isImageBanner
                                      ? storeController.rawLogo
                                      : null,
                                );
                              }
                            }
                          }
                        },
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Color _colorFromHex(String hexColor) {
    final String normalized = hexColor.replaceAll('#', '');
    try {
      return Color(int.parse('FF$normalized', radix: 16));
    } catch (e) {
      return const Color(0xFF00A082);
    }
  }

  void openColorPickerDialog() {
    final List<String> pickerColors = [
      '#FF1744',
      '#F50057',
      '#D500F9',
      '#651FFF',
      '#3D5AFE',
      '#2979FF',
      '#00E5FF',
      '#1DE9B6',
      '#00E676',
      '#76FF03',
      '#C6FF00',
      '#FFEA00',
      '#FFC400',
      '#FF9100',
      '#FF3D00',
      '#3E2723',
      '#9E9E9E',
      '#607D8B',
      '#000000',
      '#111827',
      '#00A082',
      '#FF8A00',
      '#EF4444',
      '#2563EB',
    ];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('select_color'.tr, style: robotoBold),
          content: SizedBox(
            width: 300,
            child: GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: pickerColors.length,
              itemBuilder: (context, index) {
                final colorHex = pickerColors[index];
                return InkWell(
                  onTap: () {
                    setState(() {
                      _backgroundColorHex = colorHex;
                      _customColorController.text = colorHex;
                    });
                    Navigator.pop(context);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: _colorFromHex(colorHex),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _backgroundColorHex == colorHex
                            ? Colors.black
                            : Colors.grey.withValues(alpha: 0.3),
                        width: _backgroundColorHex == colorHex ? 2 : 1,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('close'.tr, style: robotoMedium),
            ),
          ],
        );
      },
    );
  }
}
