import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shoplancer_vendor/features/address/controllers/address_controller.dart';
import 'package:shoplancer_vendor/features/auth/controllers/auth_controller.dart';
import 'package:shoplancer_vendor/util/dimensions.dart';
import 'package:shoplancer_vendor/util/styles.dart';
import 'package:shoplancer_vendor/common/widgets/custom_button_widget.dart';
import 'package:shoplancer_vendor/common/widgets/custom_snackbar_widget.dart';
import 'package:shoplancer_vendor/features/auth/widgets/min_max_time_picker_widget.dart';

class CustomTimePickerWidget extends StatefulWidget {
  const CustomTimePickerWidget({super.key});

  @override
  State<CustomTimePickerWidget> createState() => _CustomTimePickerWidgetState();
}

class _CustomTimePickerWidgetState extends State<CustomTimePickerWidget> {
  late TextEditingController _minTimeController;
  late TextEditingController _maxTimeController;
  final List<String> _unitKeys = ['minute', 'hours', 'days'];

  @override
  void initState() {
    super.initState();
    final authController = Get.find<AuthController>();
    _minTimeController = TextEditingController(text: authController.storeMinTime);
    _maxTimeController = TextEditingController(text: authController.storeMaxTime);

    _minTimeController.addListener(() {
      authController.minTimeChange(_minTimeController.text);
    });
    _maxTimeController.addListener(() {
      authController.maxTimeChange(_maxTimeController.text);
    });
  }

  @override
  void dispose() {
    _minTimeController.dispose();
    _maxTimeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    AddressController addressController = Get.find<AddressController>();

    bool isRental = addressController.moduleList != null && addressController.selectedModuleIndex != -1 &&
        addressController.moduleList![addressController.selectedModuleIndex!].moduleType == 'rental';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge)),
      insetPadding: const EdgeInsets.all(30),
      clipBehavior: Clip.antiAliasWithSaveLayer,
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
        child: GetBuilder<AuthController>(builder: (authController) {

          return Column(mainAxisSize: MainAxisSize.min, children: [

            Text(
              isRental ? 'estimated_pickup_time_time'.tr : 'estimated_delivery_time'.tr ,
              style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeLarge),
            ),
            const SizedBox(height: Dimensions.paddingSizeSmall),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
              child: Text(
                'this_item_will_be_shown_in_the_user_app_website'.tr,
                style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeLarge,color: Theme.of(context).disabledColor),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: Dimensions.paddingSizeLarge),

            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [

              SizedBox(
                width: 70,
                child: Text(
                  'minimum'.tr,
                  style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeLarge,color: Theme.of(context).disabledColor),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(),

              SizedBox(
                width: 75,
                child: Text(
                  'maximum'.tr,
                  style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeLarge,color: Theme.of(context).disabledColor),
                  textAlign: TextAlign.center,
                ),
              ),

              SizedBox(
                width: 70,
                child: Text(
                  'unit'.tr,
                  style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeLarge,color: Theme.of(context).disabledColor),
                  textAlign: TextAlign.center,
                ),
              ),

            ]),
            const SizedBox(height: Dimensions.paddingSizeDefault),

            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [

              Expanded(
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).disabledColor.withOpacity(0.5), width: 0.5),
                    borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                  ),
                  child: TextField(
                    controller: _minTimeController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: robotoMedium,
                    decoration: InputDecoration(
                      hintText: 'minimum'.tr,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              const Text('-', style: robotoBold),
              const SizedBox(width: 10),

              Expanded(
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).disabledColor.withOpacity(0.5), width: 0.5),
                    borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                  ),
                  child: TextField(
                    controller: _maxTimeController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: robotoMedium,
                    decoration: InputDecoration(
                      hintText: 'maximum'.tr,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).disabledColor.withOpacity(0.5), width: 0.5),
                  borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _unitKeys.contains(authController.storeTimeUnit) ? authController.storeTimeUnit : _unitKeys[0],
                    items: _unitKeys.map((String key) {
                      return DropdownMenuItem<String>(
                        value: key,
                        child: Text(key.tr, style: robotoMedium),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        authController.timeUnitChange(value);
                        authController.setDeliveryTimeTypeIndex(value, false);
                      }
                    },
                  ),
                ),
              ),

            ]),

            Padding(
              padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeLarge),
              child: Text(
                '${authController.storeMinTime} - ${authController.storeMaxTime} ${authController.storeTimeUnit.tr}',
                style: robotoBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge),
              ),
            ),

            CustomButtonWidget(
              width: 200,
              buttonText: 'save'.tr,
              onPressed: (){
                int? min;
                int? max;
                try{
                  min = int.parse(authController.storeMinTime);
                  max = int.parse(authController.storeMaxTime);
                }catch(e){
                  log(e.toString());
                }

                if(min == null){
                  showCustomSnackBar(isRental ? 'minimum_pickup_time_can_not_be_empty' : 'minimum_delivery_time_can_not_be_empty'.tr);
                }else if(max == null){
                  showCustomSnackBar(isRental ? 'maximum_pickup_time_can_not_be_empty' : 'maximum_delivery_time_can_not_be_empty'.tr);
                }else if(authController.storeTimeUnit.isEmpty){
                  showCustomSnackBar('time_unit_can_not_be_empty'.tr);
                }else if(min < max){
                  Get.back();
                }else{
                  showCustomSnackBar(isRental ? 'maximum_pickup_time_can_not_be_smaller_then_minimum_pickup_time' : 'maximum_delivery_time_can_not_be_smaller_then_minimum_delivery_time'.tr);
                }
              },
            ),

          ]);
        }),
      ),
    );
  }
}
