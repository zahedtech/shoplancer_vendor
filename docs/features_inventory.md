# Inventory صفحات وميزات المشروع

هذا الملف يسجل features والصفحات المعروفة داخل `lib/features`. الهدف منه أن يكون checklist للتوثيق الكامل.

## P1 - رحلات العمل اليومية

### auth

- `sign_in_screen.dart`: تسجيل دخول صاحب المتجر أو الموظف.
- `store_registration_screen.dart`: تسجيل متجر جديد.

### dashboard

- `dashboard_screen.dart`: حاوية التبويبات الرئيسية والتنقل السفلي.

### home

- `home_screen.dart`: الصفحة الرئيسية، QR، التحليلات، والطلبات الجارية.

### menu

- `menu_screen.dart`: قائمة الاختصارات والإعدادات العامة.

### store

- `store_screen.dart`: صفحة المتجر.
- `store_edit_screen.dart`: تعديل بيانات المتجر.
- `store_settings_screen.dart`: إعدادات المتجر.
- `store_sections_screen.dart`: أقسام المتجر.
- `store_link_screen.dart`: رابط المتجر.
- `social_media_screen.dart`: روابط التواصل الاجتماعي.
- `announcement_screen.dart`: إعلانات وتنبيهات المتجر.
- `payment_methods_screen.dart`: طرق الدفع.
- `add_item_screen.dart`: إضافة أو تعديل منتج كامل.
- `quick_add_item_screen.dart`: إضافة منتجات بسرعة.
- `all_items_screen.dart`: كل المنتجات.
- `item_details_screen.dart`: تفاصيل المنتج.
- `item_search_screen.dart`: بحث المنتجات.
- `pending_item_screen.dart`: المنتجات المعلقة.
- `pending_item_details_screen.dart`: تفاصيل منتج معلق.
- `inactive_products_screen.dart`: المنتجات غير النشطة.
- `low_stock_screen.dart`: المنتجات قليلة المخزون.
- `product_management_screen.dart`: إدارة المنتجات، الأسعار، البحث والباركود.
- `product_price_management_screen.dart`: إدارة أسعار المنتجات.
- `product_price_category_selection_screen.dart`: اختيار فئة لإدارة الأسعار.
- `product_status_screen.dart`: إدارة حالة المنتجات.
- `brand_screen.dart`: البراندات.
- `brand_product_screen.dart`: منتجات البراند.
- `image_viewer_screen.dart`: عرض الصور.

### pos

- `pos_screen.dart`: إنشاء طلب POS على الموبايل.
- `desktop_pos_screen.dart`: إنشاء طلب POS على الديسكتوب.
- `pos_barcode_scanner_screen.dart`: ماسح باركود POS.
- `desktop_settings_screen.dart`: إعدادات POS للديسكتوب.

### order

- `order_history_screen.dart`: سجل الطلبات.
- `order_details_screen.dart`: تفاصيل الطلب وإجراءاته.
- `invoice_print_screen.dart`: طباعة الفاتورة.
- `alternative_item_selection_screen.dart`: اختيار بديل للمنتج.

### payment

- `payment_screen.dart`: مدخل الدفع.
- `wallet_screen.dart`: المحفظة.
- `prepaid_wallet_screen.dart`: المحفظة المسبقة.
- `payment_history_screen.dart`: سجل المدفوعات.
- `withdraw_history_screen.dart`: سجل السحوبات.
- `bank_info_screen.dart`: بيانات البنك.
- `payment_successful_screen.dart`: نجاح الدفع.

## P2 - إدارة وتشغيل

### addon

- `addon_screen.dart`: قائمة وإدارة الإضافات.
- `add_addon_screen.dart`: إضافة أو تعديل إضافة.

### category

- `category_screen.dart`: إدارة الفئات الرئيسية.
- `sub_category_screen.dart`: إدارة الفئات الفرعية.
- `category_product_screen.dart`: منتجات الفئة.

### banner

- `banner_list_screen.dart`: قائمة البنرات.
- `add_banner_screen.dart`: إضافة أو تعديل بنر.

### coupon

- `coupon_screen.dart`: قائمة الكوبونات.
- `add_coupon_screen.dart`: إضافة أو تعديل كوبون.

### campaign

- `campaign_screen.dart`: قائمة الحملات.
- `campaign_details_screen.dart`: تفاصيل الحملة.

### employee

- `employee_screen.dart`: قائمة الموظفين وإدارة حالتهم.
- `add_employee_screen.dart`: إضافة أو تعديل موظف.

### deliveryman

- `delivery_man_screen.dart`: قائمة مندوبي التوصيل.
- `add_delivery_man_screen.dart`: إضافة مندوب.
- `delivery_man_details_screen.dart`: تفاصيل المندوب.

### disbursement

- `disbursement_menu_screen.dart`: قائمة السحوبات.
- `disbursement_screen.dart`: السحوبات.
- `withdraw_method_screen.dart`: طرق السحب.
- `add_withdraw_method_screen.dart`: إضافة طريقة سحب.

### subscription

- `my_subscription_screen.dart`: الاشتراك الحالي والمعاملات.

## P3 - دعم وإعدادات

### advertisement

- `advertisement_list_screen.dart`: قائمة الإعلانات.
- `advertisement_details_screen.dart`: تفاصيل الإعلان.
- `create_advertisement_screen.dart`: إنشاء إعلان.

### chat

- `conversation_screen.dart`: قائمة المحادثات.
- `chat_screen.dart`: الرسائل.

### notification

- `notification_screen.dart`: الإشعارات.

### profile

- `profile_screen.dart`: الملف الشخصي.
- `update_profile_screen.dart`: تعديل الملف.
- `setting_screen.dart`: الإعدادات.

### reports

- `reports_screen.dart`: التقارير.

### review

- `customer_review_screen.dart`: تقييمات العملاء.
- `review_reply_screen.dart`: الرد على تقييم.

### language

- `language_screen.dart`: اختيار اللغة.

### html

- `html_viewer_screen.dart`: عرض محتوى HTML مثل الشروط والخصوصية.

### splash

- `splash_screen.dart`: الإقلاع وتحميل الإعدادات.

### update

- `update_screen.dart`: شاشة تحديث التطبيق.

### forgot_password

- `forget_pass_screen.dart`: طلب استعادة كلمة المرور.
- `verification_screen.dart`: التحقق.
- `new_pass_screen.dart`: كلمة مرور جديدة.

### address

لا توجد screen مستقلة في inventory الحالي، لكن توجد widgets مهمة لتحديد الموقع والمنطقة:

- `location_search_dialog_widget.dart`
- `select_location_module_view_widget.dart`
- `zone_selection_widget.dart`

### ai

لا توجد screen مستقلة في inventory الحالي، لكن توجد bottom sheets:

- `ai_generator_bottom_sheet.dart`
- `generate_title_bottom_sheet.dart`
- `image_analyze_bottom_sheet.dart`

### business

- `subscription_payment_screen.dart`: دفع الاشتراك.
- `subscription_success_or_failed_screen.dart`: نتيجة الدفع.

### rental_module

- `taxi_home_screen.dart`: الصفحة الرئيسية لموديول التأجير.
- `taxi_menu_screen.dart`: قائمة موديول التأجير.
- `taxi_chat_screen.dart`: محادثات موديول التأجير.
- `provider_screen.dart`: بيانات مزود خدمة التأجير.
- `trip_history_screen.dart`: سجل رحلات التأجير.
- `trip_details_screen.dart`: تفاصيل رحلة تأجير.

## حالة التوثيق

- [x] إنشاء inventory أولي.
- [x] بدء شرح P1: auth/dashboard/home.
- [x] شرح P1: store. موجود في `docs/feature_guides/store_management.md` و`docs/feature_guides/store_deep_dive.md`.
- [x] شرح P1: pos. موجود في `docs/feature_guides/pos_order.md`.
- [x] شرح P1: order. موجود في `docs/feature_guides/pos_order.md`.
- [x] شرح P1: payment. موجود في `docs/feature_guides/finance_subscription.md`.
- [x] شرح P2: disbursement/subscription. موجود في `docs/feature_guides/finance_subscription.md`.
- [x] شرح P2: addon/category/banner/coupon/campaign. موجود في `docs/feature_guides/catalog_operations.md`.
- [x] شرح P2: employee/deliveryman/advertisement. موجود في `docs/feature_guides/people_ads.md`.
- [x] شرح P3. موجود في `docs/feature_guides/support_settings.md`.
- [x] شرح menu/rental_module. موجود في `docs/feature_guides/menu_rental_module.md`.
- [x] شرح عناصر القائمة بالتفصيل: الفئات، البراند، المخزون، الإضافات، البنرات، الموظفين، الإعدادات، الدفع، المحفظة، الاشتراك، الدعم.
- [x] شرح عملية network. موجود في `docs/network_flow.md`.
