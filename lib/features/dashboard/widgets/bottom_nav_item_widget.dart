import 'package:flutter/material.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:shoplancer_vendor/util/dimensions.dart';
import 'package:shoplancer_vendor/util/styles.dart';

class BottomNavItemWidget extends StatelessWidget {
  final String selectedIcon;
  final String unSelectedIcon;
  final String title;
  final Function? onTap;
  final bool isSelected;
  final GlobalKey? showcaseKey;
  final String? showcaseTitle;
  final String? showcaseDescription;

  const BottomNavItemWidget({
    super.key,
    this.onTap,
    this.isSelected = false,
    required this.title,
    required this.selectedIcon,
    required this.unSelectedIcon,
    this.showcaseKey,
    this.showcaseTitle,
    this.showcaseDescription,
  });

  @override
  Widget build(BuildContext context) {
    Widget child = InkWell(
      onTap: onTap as void Function()?,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            isSelected ? selectedIcon : unSelectedIcon,
            height: 25,
            width: 25,
            color: isSelected
                ? Theme.of(context).primaryColor
                : Theme.of(context).textTheme.bodyMedium!.color!,
          ),

          SizedBox(
            height: isSelected
                ? Dimensions.paddingSizeExtraSmall
                : Dimensions.paddingSizeSmall,
          ),

          Text(
            title,
            style: robotoRegular.copyWith(
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : Theme.of(context).textTheme.bodyMedium!.color!,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );

    if (showcaseKey != null && showcaseTitle != null && showcaseDescription != null) {
      child = Showcase(
        key: showcaseKey!,
        title: showcaseTitle!,
        description: showcaseDescription!,
        targetShapeBorder: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        tooltipBackgroundColor: Theme.of(context).primaryColor,
        textColor: Colors.white,
        titleTextStyle: robotoBold.copyWith(color: Colors.white, fontSize: 16),
        descTextStyle: robotoRegular.copyWith(
          color: Colors.white.withOpacity(0.9),
          fontSize: 13,
        ),
        child: child,
      );
    }

    return Expanded(child: child);
  }
}
