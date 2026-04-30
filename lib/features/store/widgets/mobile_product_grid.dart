import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:sixam_mart_store/features/store/controllers/store_controller.dart';
import 'package:sixam_mart_store/features/store/domain/models/item_model.dart';
import 'package:sixam_mart_store/features/store/widgets/minimal_product_card.dart';
import 'package:sixam_mart_store/util/dimensions.dart';
import 'package:sixam_mart_store/util/styles.dart';

class MobileProductGrid extends StatelessWidget {
  const MobileProductGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<StoreController>(
      builder: (storeController) {
        final List<Item>? items = storeController.itemList;

        if (items == null) {
          return const _ProductShimmer();
        }

        if (items.isEmpty) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 60.0, horizontal: 30),
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.search_off_rounded,
                    size: 64,
                    color: Theme.of(context).primaryColor.withOpacity(0.5),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'no_item_available'.tr,
                  textAlign: TextAlign.center,
                  style: robotoBold.copyWith(
                    fontSize: 18,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'try_another_search_or_category'.tr,
                  textAlign: TextAlign.center,
                  style: robotoRegular.copyWith(
                    fontSize: 14,
                    color: Theme.of(context).disabledColor,
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

class _ProductShimmer extends StatelessWidget {
  const _ProductShimmer();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: 4,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Row(
              children: [
                Expanded(child: _buildShimmerItem(context)),
                const SizedBox(width: 16),
                Expanded(child: _buildShimmerItem(context)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildShimmerItem(BuildContext context) {
    return Shimmer(
      child: Container(
        height: 220,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
          border: Border.all(color: Theme.of(context).disabledColor.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 100,
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).disabledColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 14, width: 100, color: Theme.of(context).disabledColor.withOpacity(0.1)),
                  const SizedBox(height: 8),
                  Container(height: 12, width: 60, color: Theme.of(context).disabledColor.withOpacity(0.1)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(height: 20, width: 50, color: Theme.of(context).disabledColor.withOpacity(0.1)),
                      Container(height: 36, width: 36, decoration: BoxDecoration(
                        color: Theme.of(context).disabledColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      )),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
