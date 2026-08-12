# Research: Quick Add Products Enhancements

## Decision: Reuse the shared barcode scanner screen

**Rationale**: يوجد `lib/common/widgets/barcode_scanner_screen.dart` مبني على `mobile_scanner` ويرجع `String` عبر `Get.back(result: code)`. إعادة استخدامه تقلل التغيير وتوحد تجربة المسح.

**Alternatives considered**:
- بناء scanner inline داخل `QuickAddItemScreen`: مرفوض لأنه يكرر منطق موجود ويزيد تعقيد الشاشة.
- استخدام شاشة POS barcode scanner: مرفوض لأنها مربوطة بإضافة منتج للسلة وليس مجرد إرجاع كود.

## Decision: Barcode field is optional and staged with each quick item

**Rationale**: الطلب يطلب إمكانية المسح أو الإدخال اليدوي، ولم يذكر أن الباركود مطلوب. الإضافة السريعة الحالية تسمح بإضافة منتج بسيط بأقل حقول، لذلك الباركود يجب ألا يكسر التدفق.

**Alternatives considered**:
- جعل الباركود إلزاميا: مرفوض لأنه يغير سلوك إضافة المنتج السريع.
- حفظ باركود واحد خارج staged list: مرفوض لأن المستخدم قد يضيف عدة منتجات قبل "حفظ الكل".

## Decision: Confirm API field before implementation; default candidate is `barcode`

**Rationale**: البحث في الكود يوضح أن قوائم المنتجات تستخدم query باسم `barcode` في `StoreRepository.getItemList`، لكن `Item` و`StoreRepository.addItem` لا يحتويان حقل حفظ باركود حاليا. لذلك الخطة تعتبر `barcode` هو المرشح الطبيعي، مع gate تنفيذ للتحقق من الباك إند.

**Alternatives considered**:
- إرسال الحقل مباشرة بدون تحقق: مخاطرة بأن يتجاهله الباك إند أو يرفض الطلب.
- استخدام `code` أو `sku`: لا توجد قرينة محلية كافية في add item payload.

## Decision: Use one internal numeric keypad with an active target

**Rationale**: الشاشة تحتوي كيباد سعر داخلي بالفعل. توسيعه ليعمل على السعر والمخزون يحافظ على نفس تجربة المستخدم ويمنع كيبورد النظام للمخزون.

**Alternatives considered**:
- ترك المخزون كـ `CustomTextFieldWidget(inputType: TextInputType.number)`: مرفوض لأنه يفتح كيبورد الموبايل.
- إنشاء كيبادين منفصلين: مرفوض لأنه يزحم الشاشة ويكرر منطق الإدخال.

## Decision: Add optional subcategory selection after main category selection

**Rationale**: `CategoryController` يوفر `getSubCategoryList(categoryID)`، و`StoreRepository.addItem` يرسل `sub_category_id` إذا كانت `item.categoryIds.length > 1`. إذن التنفيذ يحتاج فقط حفظ الاختيار في شاشة quick add وتمريره في staged item.

**Alternatives considered**:
- إرسال الفئة الرئيسية فقط: لا يلبي الطلب.
- تحميل كل الفئات الفرعية لكل الفئات مسبقا: مرفوض لأنه يزيد الشبكة والذاكرة بدون حاجة.
