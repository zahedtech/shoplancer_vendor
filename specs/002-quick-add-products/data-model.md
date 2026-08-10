# Data Model: Quick Add Products Enhancements

## QuickAddDraftItem

يمثل المنتج المرحلي داخل شاشة الإضافة السريعة قبل الضغط على "حفظ الكل".

**Fields**:
- `localId: String` - معرف محلي مؤقت.
- `name: String` - اسم المنتج، مطلوب.
- `price: double` - السعر، مطلوب وأكبر من صفر.
- `stock: int` - المخزون، اختياري في الإدخال ويصبح `100` عند تركه فارغا.
- `categoryId: int` - الفئة الرئيسية، مطلوبة.
- `categoryName: String` - اسم الفئة للعرض.
- `subCategoryId: int?` - الفئة الفرعية، اختيارية.
- `subCategoryName: String?` - اسم الفئة الفرعية للعرض.
- `barcode: String?` - الباركود، اختياري ويخزن بعد `trim`.
- `imageFile: XFile?` - صورة اختيارية.
- `status: _StagedStatus` - pending/submitting/success/failed.

**Validation Rules**:
- `name.trim()` لا يكون فارغا.
- `price` يجب أن يكون رقما أكبر من صفر.
- `categoryId` يجب أن يكون محددا.
- `stock` إذا كتب يدويا يجب أن يكون رقما صحيحا غير سالب. إذا ترك فارغا يستخدم `100`.
- `subCategoryId` لا يحفظ إلا إذا كان تابعا للفئة الرئيسية المختارة.
- `barcode` اختياري؛ إذا كان فارغا بعد `trim` يعامل كـ `null`.

## NumericEntryTarget

حالة UI تحدد أي حقل يعدله الكيباد الداخلي.

**Values**:
- `price`
- `stock`

**State Rules**:
- القيمة الافتراضية عند فتح الشاشة هي `price`.
- الضغط على صندوق السعر يجعل الهدف `price` ويفتح/يعرض الكيباد.
- الضغط على صندوق المخزون يجعل الهدف `stock` ويفتح/يعرض الكيباد.
- زر النقطة `.` مسموح للسعر فقط، ومخفي أو معطل للمخزون.

## CategorySelection

يمثل اختيار التصنيف في شاشة الإضافة السريعة.

**Fields**:
- `selectedCategoryId: int?`
- `selectedCategoryName: String?`
- `selectedSubCategoryId: int?`
- `selectedSubCategoryName: String?`
- `subCategoryList: List<CategoryModel>?`

**State Transitions**:
- عند اختيار فئة رئيسية: امسح الفئة الفرعية، ثم اطلب `getSubCategoryList(categoryId)`.
- عند وصول فئات فرعية: اعرض dropdown إذا القائمة غير فارغة.
- عند تغيير الفئة الرئيسية مرة أخرى: لا تستخدم الفئة الفرعية السابقة في staged item.

## Item Submission Mapping

عند بناء `Item` للإرسال:
- `item.name = staged.name`
- `item.price = staged.price`
- `item.stock = staged.stock`
- `item.categoryIds = [CategoryIds(id: categoryId)]`
- إذا `subCategoryId != null`: أضف `CategoryIds(id: subCategoryId)` كعنصر ثاني.
- إذا `barcode != null`: مرره لحقل `Item` أو `fields` حسب عقد API المؤكد.
