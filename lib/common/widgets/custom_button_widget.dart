import 'package:get/get.dart';
import 'package:shoplancer_vendor/util/dimensions.dart';
import 'package:shoplancer_vendor/util/styles.dart';
import 'package:flutter/material.dart';

class CustomButtonWidget extends StatelessWidget {
  final Function? onPressed;
  final String buttonText;
  final String? loadingText;
  final bool transparent;
  final EdgeInsets? margin;
  final double? height;
  final double? width;
  final double? fontSize;
  final Color? color;
  final IconData? icon;
  final double radius;
  final FontWeight? fontWeight;
  final bool isViewReply;
  final Color? textColor;
  final Color? iconColor;
  final bool isLoading;
  final bool isBorder;
  final Color? borderColor;

  const CustomButtonWidget({
    super.key,
    this.onPressed,
    required this.buttonText,
    this.loadingText,
    this.transparent = false,
    this.margin,
    this.iconColor,
    this.isLoading = false,
    this.width,
    this.height,
    this.fontSize,
    this.color,
    this.icon,
    this.radius = Dimensions.radiusDefault,
    this.fontWeight,
    this.isViewReply = false,
    this.textColor,
    this.isBorder = false,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final ButtonStyle flatButtonStyle = TextButton.styleFrom(
      backgroundColor: onPressed == null
          ? Theme.of(context).disabledColor
          : transparent
              ? Colors.transparent
              : color ?? Theme.of(context).primaryColor,
      minimumSize: Size(
        width != null ? width! : 1170,
        height != null ? height! : 50,
      ),
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
        side: isBorder
            ? BorderSide(
                color: borderColor ??
                    Theme.of(context).disabledColor.withValues(alpha: 0.5),
              )
            : BorderSide.none,
      ),
    );

    final Color effectiveTextColor = textColor ??
        (transparent || isViewReply
            ? Theme.of(context).primaryColor
            : Colors.white);

    Widget button = TextButton(
      onPressed: isLoading ? null : onPressed as void Function()?,
      style: flatButtonStyle,
      child: isLoading
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(effectiveTextColor),
                    strokeWidth: 2.2,
                  ),
                ),
                const SizedBox(width: Dimensions.paddingSizeSmall),
                Flexible(
                  fit: FlexFit.loose,
                  child: Text(
                    loadingText ?? 'جاري الحفظ...'.tr,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: robotoMedium.copyWith(
                      color: effectiveTextColor,
                      fontSize: fontSize ?? Dimensions.fontSizeDefault,
                      fontWeight: fontWeight ?? FontWeight.w600,
                    ),
                  ),
                ),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                icon != null
                    ? Icon(
                        icon,
                        color: transparent
                            ? Theme.of(context).primaryColor
                            : iconColor ?? Theme.of(context).cardColor,
                        size: 20,
                      )
                    : const SizedBox(),
                SizedBox(width: icon != null ? Dimensions.paddingSizeExtraSmall : 0),
                Flexible(
                  fit: FlexFit.loose,
                  child: Text(
                    buttonText,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: robotoBold.copyWith(
                      color: effectiveTextColor,
                      fontSize: fontSize ?? Dimensions.fontSizeLarge,
                      fontWeight: fontWeight ?? FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
    );

    if (width != null || height != null) {
      button = SizedBox(
        width: width,
        height: height,
        child: button,
      );
    }

    return Padding(
      padding: margin == null ? const EdgeInsets.all(0) : margin!,
      child: button,
    );
  }
}
