import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart_store/features/store/controllers/store_controller.dart';
import 'package:sixam_mart_store/features/store/domain/models/item_model.dart';
import 'package:sixam_mart_store/features/store/widgets/minimal_product_card.dart';
import 'package:sixam_mart_store/util/styles.dart';

class MobileProductGrid extends StatelessWidget {
  const MobileProductGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<StoreController>(
      builder: (storeController) {
        final List<Item>? items = storeController.itemList;

        if (items == null || items.isEmpty) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 60.0, horizontal: 30),
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF1F5F1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.search_off_rounded,
                    size: 64,
                    color: const Color(0xFF2C7A46).withOpacity(0.5),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'no_item_available'.tr,
                  textAlign: TextAlign.center,
                  style: robotoBold.copyWith(
                    fontSize: 18,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'try_another_search_or_category'.tr,
                  textAlign: TextAlign.center,
                  style: robotoRegular.copyWith(
                    fontSize: 14,
                    color: const Color(0xFF7D7D7D),
                  ),
                ),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: ListView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: (items.length / 2).ceil(),
            itemBuilder: (context, index) {
              int firstIndex = index * 2;
              int secondIndex = firstIndex + 1;

              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: MinimalProductCard(item: items[firstIndex]),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: secondIndex < items.length
                          ? MinimalProductCard(item: items[secondIndex])
                          : const SizedBox(),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
