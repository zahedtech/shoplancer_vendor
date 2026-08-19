import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shoplancer_vendor/common/widgets/custom_button_widget.dart';
import 'package:shoplancer_vendor/common/widgets/custom_text_field_widget.dart';
import 'package:shoplancer_vendor/features/pos/controllers/pos_controller.dart';
import 'package:shoplancer_vendor/features/pos/widgets/add_pos_customer_dialog.dart';
import 'package:shoplancer_vendor/util/dimensions.dart';
import 'package:shoplancer_vendor/util/styles.dart';

class PosCartBottomSheet extends StatefulWidget {
  const PosCartBottomSheet({super.key});

  @override
  State<PosCartBottomSheet> createState() => _PosCartBottomSheetState();
}

class _PosCartBottomSheetState extends State<PosCartBottomSheet> {
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _buildingController = TextEditingController();
  final TextEditingController _apartmentController = TextEditingController();
  final TextEditingController _deliveryChargeController =
      TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _customerSearchController =
      TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      child: GetBuilder<PosController>(
        builder: (posController) {
          return Column(
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'سلة الطلب اليدوي (${posController.cartList.length})',
                    style: robotoBold.copyWith(
                      fontSize: Dimensions.fontSizeLarge,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
              const Divider(),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Customer Selection
                      Text('تحديد العميل *'.tr, style: robotoBold),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: posController.selectedCustomer != null
                                ? Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Theme.of(
                                        context,
                                      ).primaryColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '${posController.selectedCustomer!.fullName}${posController.selectedCustomer!.phone != null ? ' (${posController.selectedCustomer!.phone})' : ''}',
                                          style: robotoMedium.copyWith(
                                            color: Theme.of(
                                              context,
                                            ).primaryColor,
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.clear,
                                            size: 18,
                                          ),
                                          onPressed: () => posController
                                              .selectCustomer(null),
                                        ),
                                      ],
                                    ),
                                  )
                                : CustomTextFieldWidget(
                                    controller: _customerSearchController,
                                    hintText: 'ابحث برقم الهاتف أو الاسم'.tr,
                                    prefixIcon: Icons.search,
                                    onChanged: (val) {
                                      posController.searchCustomers(val);
                                    },
                                  ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            style: IconButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              foregroundColor: Colors.white,
                            ),
                            icon: const Icon(Icons.person_add),
                            onPressed: () {
                              Get.dialog(const AddPosCustomerDialog());
                            },
                          ),
                        ],
                      ),
                      if (posController.selectedCustomer == null &&
                          (posController.customerList != null &&
                              posController.customerList!.isNotEmpty))
                        Container(
                          constraints: const BoxConstraints(maxHeight: 150),
                          margin: const EdgeInsets.only(top: 4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            border: Border.all(
                              color: Theme.of(
                                context,
                              ).disabledColor.withOpacity(0.3),
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: posController.customerList!.length,
                            itemBuilder: (context, idx) {
                              final c = posController.customerList![idx];
                              return ListTile(
                                dense: true,
                                title: Text(c.fullName),
                                subtitle: c.phone != null
                                    ? Text(c.phone!)
                                    : null,
                                onTap: () {
                                  posController.selectCustomer(c);
                                  _customerSearchController.clear();
                                },
                              );
                            },
                          ),
                        ),
                      const SizedBox(height: Dimensions.paddingSizeDefault),

                      // 2. Order Items List
                      Text('المنتجات المحددة'.tr, style: robotoBold),
                      const SizedBox(height: 6),
                      if (posController.cartList.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Center(
                            child: Text(
                              'لم يتم إضافة أي منتجات بعد',
                              style: robotoRegular.copyWith(
                                color: Theme.of(context).disabledColor,
                              ),
                            ),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: posController.cartList.length,
                          separatorBuilder: (context, i) => const Divider(),
                          itemBuilder: (context, index) {
                            final cart = posController.cartList[index];
                            return Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        cart.item.name ?? '',
                                        style: robotoMedium,
                                      ),
                                      if (cart.selectedVariant != null)
                                        Text(
                                          'النوع: ${cart.selectedVariant}',
                                          style: robotoRegular.copyWith(
                                            fontSize: 12,
                                            color: Theme.of(
                                              context,
                                            ).disabledColor,
                                          ),
                                        ),
                                      Text(
                                        '${cart.price} ج.م',
                                        style: robotoBold.copyWith(
                                          color: Theme.of(context).primaryColor,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.remove_circle_outline,
                                      ),
                                      onPressed: () => posController
                                          .updateQuantity(index, false),
                                    ),
                                    Text('${cart.quantity}', style: robotoBold),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.add_circle_outline,
                                      ),
                                      onPressed: () => posController
                                          .updateQuantity(index, true),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                        size: 20,
                                      ),
                                      onPressed: () =>
                                          posController.removeFromCart(index),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
                        ),
                      const SizedBox(height: Dimensions.paddingSizeDefault),

                      // 3. Order Type Selection
                      Text('نوع الطلب *'.tr, style: robotoBold),
                      const SizedBox(height: 6),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _orderTypeChip(
                              'استلام بنفسه (Takeaway)',
                              'take_away',
                              posController,
                            ),
                            const SizedBox(width: 8),
                            _orderTypeChip(
                              'توصيل (Delivery)',
                              'delivery',
                              posController,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: Dimensions.paddingSizeDefault),

                      // Delivery Address & Charge (if Delivery)
                      if (posController.orderType == 'delivery') ...[
                        Text('سعر/رسوم التوصيل'.tr, style: robotoBold),
                        const SizedBox(height: 6),
                        CustomTextFieldWidget(
                          controller: _deliveryChargeController,
                          inputType: TextInputType.number,
                          hintText: 'أدخل سعر التوصيل (مثال: 25)'.tr,
                          prefixIcon: Icons.directions_bike,
                          onChanged: (val) {
                            double charge = double.tryParse(val) ?? 0.0;
                            posController.setDeliveryCharge(charge);
                          },
                        ),
                        const SizedBox(height: Dimensions.paddingSizeDefault),

                        Text('عنوان التوصيل *'.tr, style: robotoBold),
                        const SizedBox(height: 6),
                        CustomTextFieldWidget(
                          controller: _addressController,
                          hintText: 'أدخل عنوان التوصيل بالتفصيل'.tr,
                          prefixIcon: Icons.location_on,
                        ),
                        const SizedBox(height: Dimensions.paddingSizeDefault),

                        // Building and Apartment fields side-by-side
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('رقم العمارة'.tr, style: robotoBold),
                                  const SizedBox(height: 6),
                                  CustomTextFieldWidget(
                                    controller: _buildingController,
                                    hintText: 'مثال: 5'.tr,
                                    inputType: TextInputType.text,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('رقم الشقة'.tr, style: robotoBold),
                                  const SizedBox(height: 6),
                                  CustomTextFieldWidget(
                                    controller: _apartmentController,
                                    hintText: 'مثال: 12'.tr,
                                    inputType: TextInputType.text,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: Dimensions.paddingSizeDefault),
                      ],

                      // 4. Payment Method & Status
                      Text('طريقة الدفع *'.tr, style: robotoBold),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        children: [
                          _paymentChip(
                            'كاش عند الاستلام',
                            'cash_on_delivery',
                            posController,
                          ),
                          _paymentChip(
                            'دفع إلكتروني',
                            'digital_payment',
                            posController,
                          ),
                        ],
                      ),
                      const SizedBox(height: Dimensions.paddingSizeDefault),

                      Text('حالة الدفع *'.tr, style: robotoBold),
                      const SizedBox(height: 6),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            ChoiceChip(
                              label: Text(
                                'لم يتم الدفع (Unpaid)'.tr,
                                style: robotoMedium.copyWith(
                                  fontSize: 12,
                                  color: posController.paymentStatus == 'unpaid'
                                      ? Colors.white
                                      : Theme.of(
                                          context,
                                        ).textTheme.bodyLarge?.color,
                                ),
                              ),
                              selected: posController.paymentStatus == 'unpaid',
                              selectedColor: Colors.amber.shade800,
                              onSelected: (val) =>
                                  posController.setPaymentStatus('unpaid'),
                            ),

                            const SizedBox(width: 12),
                            ChoiceChip(
                              label: Text(
                                'تم الدفع (Paid)'.tr,
                                style: robotoMedium.copyWith(
                                  fontSize: 12,
                                  color: posController.paymentStatus == 'paid'
                                      ? Colors.white
                                      : Theme.of(
                                          context,
                                        ).textTheme.bodyLarge?.color,
                                ),
                              ),
                              selected: posController.paymentStatus == 'paid',
                              selectedColor: Colors.green,
                              onSelected: (val) =>
                                  posController.setPaymentStatus('paid'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: Dimensions.paddingSizeDefault),

                      // Order Summary
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).disabledColor.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'المجموع الفرعي:'.tr,
                                  style: robotoRegular,
                                ),
                                Text(
                                  '${posController.subTotal.toStringAsFixed(2)} ج.م',
                                  style: robotoMedium,
                                ),
                              ],
                            ),
                            if (posController.orderType == 'delivery' &&
                                posController.deliveryCharge > 0) ...[
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'رسوم التوصيل:'.tr,
                                    style: robotoRegular,
                                  ),
                                  Text(
                                    '+ ${posController.deliveryCharge.toStringAsFixed(2)} ج.م',
                                    style: robotoMedium,
                                  ),
                                ],
                              ),
                            ],
                            const Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'الإجمالي الكلي:'.tr,
                                  style: robotoBold.copyWith(
                                    fontSize: Dimensions.fontSizeLarge,
                                  ),
                                ),
                                Text(
                                  '${posController.grandTotal.toStringAsFixed(2)} ج.م',
                                  style: robotoBold.copyWith(
                                    fontSize: Dimensions.fontSizeLarge,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Submit Button
              Padding(
                padding: const EdgeInsets.only(
                  top: Dimensions.paddingSizeSmall,
                ),
                child: CustomButtonWidget(
                  isLoading: posController.isLoading,
                  buttonText: 'تأكيد وإرسال الطلب'.tr,
                  onPressed: () async {
                    bool success = await posController.placeOrder(
                      address: _addressController.text.trim(),
                      note: _noteController.text.trim(),
                      house: _buildingController.text.trim(),
                      floor: _apartmentController.text.trim(),
                    );
                    if (success && context.mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _orderTypeChip(String label, String value, PosController controller) {
    bool isSelected = controller.orderType == value;
    return ChoiceChip(
      label: Text(
        label,
        style: robotoMedium.copyWith(
          fontSize: 12,
          color: isSelected
              ? Colors.white
              : Theme.of(context).textTheme.bodyLarge?.color,
        ),
      ),
      selected: isSelected,
      selectedColor: Theme.of(context).primaryColor,
      onSelected: (val) => controller.setOrderType(value),
    );
  }

  Widget _paymentChip(String label, String value, PosController controller) {
    bool isSelected = controller.paymentMethod == value;
    return ChoiceChip(
      label: Text(
        label,
        style: robotoMedium.copyWith(
          fontSize: 12,
          color: isSelected
              ? Colors.white
              : Theme.of(context).textTheme.bodyLarge?.color,
        ),
      ),
      selected: isSelected,
      selectedColor: Theme.of(context).primaryColor,
      onSelected: (val) => controller.setPaymentMethod(value),
    );
  }
}
