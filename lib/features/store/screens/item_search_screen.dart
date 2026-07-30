import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shoplancer_vendor/features/store/controllers/store_controller.dart';
import 'package:shoplancer_vendor/features/store/widgets/mobile_product_grid.dart';
import 'package:shoplancer_vendor/util/dimensions.dart';
import 'package:shoplancer_vendor/util/styles.dart';

class ItemSearchScreen extends StatefulWidget {
  const ItemSearchScreen({super.key});

  @override
  State<ItemSearchScreen> createState() => _ItemSearchScreenState();
}

class _ItemSearchScreenState extends State<ItemSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    final storeController = Get.find<StoreController>();
    storeController.getItemList(
      offset: '1',
      type: 'all',
      search: '',
      categoryId: 0,
      willUpdate: true,
    );

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent &&
          storeController.itemList != null &&
          !storeController.isLoading) {
        int pageSize = ((storeController.itemSize ?? 0) / 10).ceil();
        if (storeController.offset < pageSize) {
          storeController.setOffset(storeController.offset + 1);
          storeController.showBottomLoader();
          storeController.getItemList(
            offset: storeController.offset.toString(),
            type: 'all',
            search: _searchController.text.trim(),
            categoryId: 0,
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    Get.find<StoreController>().getItemList(
      offset: '1',
      type: 'all',
      search: query.trim(),
      categoryId: 0,
      willUpdate: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).cardColor,
        elevation: 1,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
          onPressed: () {
            Get.find<StoreController>().getItemList(
              offset: '1',
              type: 'all',
              search: '',
              categoryId: 0,
              willUpdate: true,
            );
            Get.back();
          },
        ),
        title: Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).disabledColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          ),
          child: Row(
            children: [
              Icon(
                Icons.search,
                color: Theme.of(context).disabledColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'search_products'.tr,
                    hintStyle: robotoRegular.copyWith(
                      color: Theme.of(context).disabledColor,
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  style: robotoRegular.copyWith(
                    fontSize: 14,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                  textInputAction: TextInputAction.search,
                  onChanged: (val) {
                    setState(() {});
                    if (val.isEmpty) {
                      _onSearch('');
                    }
                  },
                  onSubmitted: _onSearch,
                ),
              ),
              if (_searchController.text.isNotEmpty)
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(
                    Icons.close,
                    color: Theme.of(context).disabledColor,
                    size: 18,
                  ),
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                    });
                    _onSearch('');
                  },
                ),
            ],
          ),
        ),
        titleSpacing: 0,
      ),
      body: GetBuilder<StoreController>(
        builder: (storeController) {
          return CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              const SliverToBoxAdapter(
                child: SizedBox(height: Dimensions.paddingSizeDefault),
              ),
              const SliverToBoxAdapter(
                child: MobileProductGrid(),
              ),
              if (storeController.isLoading && storeController.itemList != null)
                SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(
                        Dimensions.paddingSizeSmall,
                      ),
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          );
        },
      ),
    );
  }
}
