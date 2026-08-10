import 'package:country_code_picker/country_code_picker.dart';
import 'package:shoplancer_vendor/common/widgets/custom_asset_image_widget.dart';
import 'package:shoplancer_vendor/util/dimensions.dart';
import 'package:shoplancer_vendor/util/styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shoplancer_vendor/common/widgets/code_picker_widget.dart';

class CustomTextFieldWidget extends StatefulWidget {
  final String hintText;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final FocusNode? nextFocus;
  final TextInputType inputType;
  final TextInputAction inputAction;
  final bool isPassword;
  final Function? onChanged;
  final Function? onSubmit;
  final bool isEnabled;
  final int maxLines;
  final TextCapitalization capitalization;
  final String? prefixImage;
  final IconData? prefixIcon;
  final double prefixSize;
  final double iconSize;
  final bool divider;
  final bool showTitle;
  final bool isAmount;
  final bool isNumber;
  final bool showBorder;
  final bool isPhone;
  final String? countryDialCode;
  final Function(CountryCode countryCode)? onCountryChanged;
  final Color? borderColor;
  final bool showLabelText;
  final bool required;
  final String? labelText;
  final String? Function(String?)? validator;
  final double? labelTextSize;
  final Widget? suffixChild;
  final int? maxLength;
  final bool hideEnableText;
  final Function? onEditingComplete;
  final String? prefixText;

  const CustomTextFieldWidget({
    super.key,
    this.hintText = 'Write something...',
    this.controller,
    this.focusNode,
    this.nextFocus,
    this.isEnabled = true,
    this.inputType = TextInputType.text,
    this.inputAction = TextInputAction.next,
    this.maxLines = 1,
    this.onSubmit,
    this.onChanged,
    this.prefixImage,
    this.capitalization = TextCapitalization.none,
    this.isPassword = false,
    this.divider = false,
    this.showTitle = false,
    this.isAmount = false,
    this.isNumber = false,
    this.isPhone = false,
    this.countryDialCode,
    this.onCountryChanged,
    this.prefixIcon,
    this.prefixSize = Dimensions.paddingSizeSmall,
    this.iconSize = 18,
    this.borderColor,
    this.showBorder = true,
    this.showLabelText = true,
    this.required = false,
    this.labelText,
    this.validator,
    this.labelTextSize,
    this.suffixChild,
    this.maxLength,
    this.hideEnableText = false,
    this.onEditingComplete,
    this.prefixText,
  });

  @override
  CustomTextFieldWidgetState createState() => CustomTextFieldWidgetState();
}

class CustomTextFieldWidgetState extends State<CustomTextFieldWidget> {
  bool _obscureText = true;
  late int currentLength;

  @override
  void initState() {
    super.initState();
      currentLength = widget.controller?.text.length ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    // final maxLength = widget.maxLength;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        widget.showTitle
            ? Text(
                widget.hintText,
                style: robotoRegular.copyWith(
                  fontSize: Dimensions.fontSizeSmall,
                ),
              )
            : const SizedBox(),
        SizedBox(
          height: widget.showTitle ? Dimensions.paddingSizeExtraSmall : 0,
        ),

        TextFormField(
          maxLines: widget.maxLines,
          controller: widget.controller,
          focusNode: widget.focusNode,
          validator: widget.validator,
          style: robotoRegular.copyWith(
            fontSize: Dimensions.fontSizeLarge,
            color: widget.isEnabled
                ? Theme.of(context).textTheme.bodyLarge?.color
                : Theme.of(context).textTheme.bodyLarge?.color,
          ),
          textInputAction: widget.inputAction,
          keyboardType: widget.isAmount
              ? const TextInputType.numberWithOptions(decimal: true)
              : widget.isNumber
              ? TextInputType.number
              : widget.inputType,
          cursorColor: Theme.of(context).primaryColor,
          textCapitalization: widget.capitalization,
          enabled: widget.isEnabled,
          autofocus: false,
          maxLength: widget.maxLength,
          autofillHints: widget.inputType == TextInputType.name
              ? [AutofillHints.name]
              : widget.inputType == TextInputType.emailAddress
              ? [AutofillHints.email]
              : widget.inputType == TextInputType.phone
              ? [AutofillHints.telephoneNumber]
              : widget.inputType == TextInputType.streetAddress
              ? [AutofillHints.fullStreetAddress]
              : widget.inputType == TextInputType.url
              ? [AutofillHints.url]
              : widget.inputType == TextInputType.visiblePassword
              ? [AutofillHints.password]
              : null,
          obscureText: widget.isPassword ? _obscureText : false,
          inputFormatters: widget.inputType == TextInputType.phone
              ? <TextInputFormatter>[
                  FilteringTextInputFormatter.allow(RegExp('[0-9+]')),
                ]
              : widget.isAmount
              ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))]
              : widget.isNumber
              ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9]'))]
              : null,
          decoration: InputDecoration(
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
              borderSide: BorderSide(
                style: widget.showBorder ? BorderStyle.solid : BorderStyle.none,
                color: Theme.of(context).disabledColor.withValues(alpha: 0.5),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
              borderSide: BorderSide(
                style: widget.showBorder ? BorderStyle.solid : BorderStyle.none,
                color: Theme.of(context).disabledColor.withValues(alpha: 0.5),
              ),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
              borderSide: BorderSide(
                style: widget.showBorder ? BorderStyle.solid : BorderStyle.none,
                color: Theme.of(context).disabledColor.withValues(alpha: 0.5),
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
              borderSide: BorderSide(
                style: widget.showBorder ? BorderStyle.solid : BorderStyle.none,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
              borderSide: BorderSide(
                style: widget.showBorder ? BorderStyle.solid : BorderStyle.none,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            isDense: true,
            hintText: widget.hintText,
            fillColor: Theme.of(context).cardColor,
            hintStyle: robotoRegular.copyWith(
              fontSize: Dimensions.fontSizeDefault,
              color: Theme.of(context).disabledColor,
            ),
            filled: true,
            floatingLabelBehavior:
                (widget.showLabelText &&
                    widget.labelText != null &&
                    widget.labelText!.isNotEmpty)
                ? FloatingLabelBehavior.auto
                : FloatingLabelBehavior.never,
            labelStyle:
                (widget.showLabelText &&
                    widget.labelText != null &&
                    widget.labelText!.isNotEmpty)
                ? robotoRegular.copyWith(
                    fontSize: Dimensions.fontSizeLarge,
                    color: Theme.of(context).disabledColor,
                  )
                : null,
            errorStyle: robotoRegular.copyWith(
              fontSize: Dimensions.fontSizeSmall,
            ),

            label:
                (widget.showLabelText &&
                    widget.labelText != null &&
                    widget.labelText!.isNotEmpty)
                ? Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: widget.labelText!,
                          style: robotoRegular.copyWith(
                            fontSize:
                                widget.labelTextSize ??
                                Dimensions.fontSizeLarge,
                            color: Theme.of(
                              context,
                            ).disabledColor.withValues(alpha: .75),
                          ),
                        ),
                        if (widget.required)
                          TextSpan(
                            text: ' *',
                            style: robotoRegular.copyWith(
                              color: Theme.of(context).colorScheme.error,
                              fontSize: Dimensions.fontSizeLarge,
                            ),
                          ),
                      ],
                    ),
                  )
                : null,

            prefixIcon: widget.prefixText != null
                ? ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(Dimensions.radiusDefault),
                      bottomLeft: Radius.circular(Dimensions.radiusDefault),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).disabledColor.withOpacity(0.08),
                        border: Border(
                          right: BorderSide(
                            color: Theme.of(
                              context,
                            ).disabledColor.withOpacity(0.25),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Text(
                        widget.prefixText!,
                        style: robotoMedium.copyWith(
                          color: Theme.of(
                            context,
                          ).disabledColor.withOpacity(0.8),
                          fontSize: Dimensions.fontSizeDefault,
                        ),
                      ),
                    ),
                  )
                : widget.isPhone
                ? SizedBox(
                    width: 95,
                    child: Row(
                      children: [
                        Container(
                          width: 85,
                          height: 50,
                          decoration: const BoxDecoration(
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(Dimensions.radiusSmall),
                              bottomLeft: Radius.circular(
                                Dimensions.radiusSmall,
                              ),
                            ),
                          ),
                          margin: const EdgeInsets.only(right: 0),
                          padding: const EdgeInsets.only(left: 5),
                          child: Center(
                            child: CodePickerWidget(
                              flagWidth: 25,
                              padding: EdgeInsets.zero,
                              onChanged: widget.onCountryChanged,
                              initialSelection: widget.countryDialCode,
                              backgroundColor: Theme.of(context).cardColor,
                              dialogBackgroundColor: Theme.of(
                                context,
                              ).cardColor,
                              favorite: [widget.countryDialCode!],
                              textStyle: robotoRegular.copyWith(
                                fontSize: Dimensions.fontSizeDefault,
                                color: Theme.of(
                                  context,
                                ).textTheme.bodyMedium!.color,
                              ),
                            ),
                          ),
                        ),

                        Container(
                          height: 20,
                          width: 2,
                          color: Theme.of(context).disabledColor,
                        ),
                      ],
                    ),
                  )
                : widget.prefixImage != null && widget.prefixIcon == null
                ? Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: widget.prefixSize,
                    ),
                    child: CustomAssetImageWidget(
                      widget.prefixImage!,
                      height: 25,
                      width: 25,
                      fit: BoxFit.scaleDown,
                    ),
                  )
                : widget.prefixImage == null && widget.prefixIcon != null
                ? Icon(
                    widget.prefixIcon,
                    size: widget.iconSize,
                    color: Theme.of(
                      context,
                    ).disabledColor.withValues(alpha: 0.4),
                  )
                : null,
            prefixIconConstraints: widget.prefixText != null
                ? const BoxConstraints(minWidth: 0, minHeight: 0)
                : null,
            suffixIcon: widget.isPassword
                ? IconButton(
                    icon: Icon(
                      _obscureText ? Icons.visibility_off : Icons.visibility,
                      color: Theme.of(
                        context,
                      ).disabledColor.withValues(alpha: 0.3),
                    ),
                    onPressed: _toggle,
                  )
                : widget.suffixChild,
          ),
          onFieldSubmitted: (text) => widget.nextFocus != null
              ? FocusScope.of(context).requestFocus(widget.nextFocus)
              : widget.onSubmit != null
              ? widget.onSubmit!(text)
              : null,
          onChanged: widget.onChanged as void Function(String)?,
          onEditingComplete: widget.onEditingComplete as void Function()?,
        ),

        widget.divider
            ? const Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: Dimensions.paddingSizeLarge,
                ),
                child: Divider(),
              )
            : const SizedBox(),
      ],
    );
  }

  void _toggle() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }
}
