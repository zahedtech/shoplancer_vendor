# دليل صفحات الدعم والإعدادات

هذا الملف يغطي صفحات P3 والصفحات المساندة التي لا تقع مباشرة ضمن رحلة البيع أو إدارة المنتج، لكنها ضرورية لتشغيل التطبيق يومياً.

## Chat / Conversation

### ConversationScreen

المسار: `lib/features/chat/screens/conversation_screen.dart`

#### ماذا تفعل الصفحة؟

تعرض قائمة المحادثات بين المتجر والعملاء أو الأطراف المدعومة من النظام. عادة تتضمن بحثاً، آخر رسالة، اسم الطرف، الصورة، وحالة القراءة.

#### الاعتماديات

- `ChatController`
- `ChatService`
- `ChatRepository`
- `ChatListModel`

#### السلوك المتوقع

- تحميل قائمة المحادثات عند الدخول.
- دعم البحث عبر `SearchFieldWidget`.
- فتح `ChatScreen` عند اختيار محادثة.
- عرض shimmer أثناء التحميل.

#### فحص مهم

- قائمة محادثات فارغة.
- بحث يرجع نتائج.
- بحث لا يرجع نتائج.
- فتح محادثة والرجوع للقائمة.

### ChatScreen

المسار: `lib/features/chat/screens/chat_screen.dart`

#### ماذا تفعل الصفحة؟

تعرض الرسائل داخل محادثة واحدة وتسمح بإرسال رسائل وربما مرفقات حسب دعم التطبيق.

#### الاعتماديات

- `MessageModel`
- `MessageBubbleWidget`
- `ImageDialogWidget`

#### السلوك المتوقع

- تحميل الرسائل بترتيب صحيح.
- التفريق بين رسائل المستخدم الحالي ورسائل الطرف الآخر.
- عرض الصور والملفات داخل bubble مناسب.
- فتح الصورة في dialog عند الضغط.

#### فحص مهم

- إرسال رسالة نصية.
- استقبال رسالة جديدة بعد الرجوع أو refresh.
- رسالة تحتوي صورة.
- رسالة تحتوي ملف غير صورة.
- محادثة طويلة مع pagination أو scroll.

## Notifications

### NotificationScreen

المسار: `lib/features/notification/screens/notification_screen.dart`

#### ماذا تفعل الصفحة؟

تعرض إشعارات المتجر مثل الطلبات، التنبيهات، السحوبات، أو تحديثات النظام.

#### الاعتماديات

- `NotificationController`
- `NotificationModel`
- `NotificationDialogWidget`

#### السلوك المتوقع

- تحميل قائمة الإشعارات.
- تمييز وجود إشعار جديد عبر `hasNotification`.
- فتح dialog للتفاصيل عند الضغط على إشعار.
- حفظ عدد الإشعارات المقروءة محلياً أو مقارنة بالعداد السابق.

#### فحص مهم

- إشعار جديد ثم دخول الصفحة.
- إشعار بدون صورة.
- إشعار يحتوي body طويل.
- الضغط على إشعار يؤدي للتفاصيل الصحيحة أو dialog واضح.

## Profile / Settings

### ProfileScreen

المسار: `lib/features/profile/screens/profile_screen.dart`

#### ماذا تفعل الصفحة؟

تعرض بيانات صاحب المتجر والمتجر والصلاحيات والخيارات الأساسية المرتبطة بالحساب.

#### الاعتماديات

- `ProfileController.getProfile()`
- `ProfileModel`
- `ProfileCardWidget`
- `ProfileBgWidget`

#### السلوك المتوقع

- تحميل profile من API.
- عرض بيانات المالك والمتجر.
- عرض صورة profile.
- إتاحة الدخول إلى تعديل الملف والإعدادات.
- تحديد صلاحيات الموديول للموظفين عبر `modulePermission`.

#### فحص مهم

- حساب مالك متجر كامل الصلاحيات.
- حساب موظف بصلاحيات محدودة.
- متجر غير active.
- بيانات ناقصة مثل صورة أو هاتف.

### UpdateProfileScreen

المسار: `lib/features/profile/screens/update_profile_screen.dart`

#### ماذا تفعل الصفحة؟

تعديل بيانات المستخدم الشخصية وصورة الحساب.

#### السلوك المتوقع

- تحميل القيم الحالية.
- اختيار صورة عبر `ImagePicker`.
- إرسال البيانات عبر `ProfileController.updateUserInfo`.
- تحديث profile بعد النجاح.

#### فحص مهم

- حفظ بدون تغيير صورة.
- حفظ مع صورة جديدة.
- رقم هاتف أو بريد غير صالح.
- فشل API لا يمسح القيم من الحقول.

### SettingScreen

المسار: `lib/features/profile/screens/setting_screen.dart`

#### ماذا تفعل الصفحة؟

إعدادات عامة للحساب والتطبيق مثل الإشعارات في الخلفية، تحذير المخزون المنخفض، وربما حذف الحساب أو تسجيل الخروج حسب الواجهة.

#### السلوك المتوقع

- عرض switches للحالات الحالية.
- تغيير notification status عبر bottom sheet تأكيدي عند الحاجة.
- حفظ تفضيلات محلية أو تحديث controller.

#### فحص مهم

- إيقاف إشعارات الخلفية.
- إخفاء تحذير low stock.
- حذف الحساب إن كان الخيار موجوداً يجب أن يطلب تأكيداً واضحاً.

## Reports

### ReportsScreen

المسار: `lib/features/reports/screens/reports_screen.dart`

#### ماذا تفعل الصفحة؟

مدخل التقارير. تعرض بطاقات تقود إلى تقارير مثل المصاريف والضرائب.

#### الاعتماديات

- `ReportCardWidget`
- `ReportController`

#### فحص مهم

- فتح كل بطاقة تقرير.
- ظهور البطاقات المناسبة لصلاحية المستخدم.

### ExpenseScreen

المسار: `lib/features/reports/expense/screens/expense_screen.dart`

#### ماذا تفعل الصفحة؟

تعرض مصاريف المتجر مع بحث وفترة زمنية وpagination.

#### الاعتماديات

- `ReportController.getExpenseList`
- `ExpenseBodyModel`
- `ExpenseCardWidget`

#### السلوك المتوقع

- تحميل المصاريف من `expenseListUri`.
- دعم `from` و`to`.
- دعم البحث النصي.
- تحميل المزيد بحد `limit=10`.

#### فحص مهم

- فترة زمنية فيها بيانات.
- فترة زمنية بدون بيانات.
- بحث داخل الفترة.
- scroll لتحميل صفحة ثانية.

### TaxReportScreen

المسار: `lib/features/reports/tax/screens/tax_report_screen.dart`

#### ماذا تفعل الصفحة؟

تعرض تقرير الضرائب والطلبات المرتبطة بفترة زمنية.

#### الاعتماديات

- `ReportController.getTaxReport`
- `TaxReportModel`

#### فحص مهم

- اختيار فترة زمنية.
- تحميل orders داخل التقرير.
- pagination.
- أرقام الضرائب تظهر بتنسيق عملة صحيح.

## Reviews

### CustomerReviewScreen

المسار: `lib/features/review/screens/customer_review_screen.dart`

#### ماذا تفعل الصفحة؟

تعرض تقييمات العملاء وملخص التقييمات.

#### الاعتماديات

- `StoreController.getStoreReviewList`
- `ReviewSummaryWidget`
- `ReviewCardWidget`

#### السلوك المتوقع

- عرض متوسط التقييم وعدد التقييمات.
- عرض قائمة reviews.
- إتاحة الرد أو تعديل الرد.

#### فحص مهم

- تقييم بدون رد.
- تقييم مع رد موجود.
- قائمة تقييمات فارغة.
- pagination إن وجدت.

### ReviewReplyScreen

المسار: `lib/features/review/screens/review_reply_screen.dart`

#### ماذا تفعل الصفحة؟

كتابة أو تعديل رد المتجر على تقييم العميل.

#### السلوك المتوقع

- تحميل نص الرد الحالي إن وجد.
- منع إرسال رد فارغ.
- تحديث الرد عبر `StoreController.updateReply`.
- الرجوع لقائمة التقييمات بعد النجاح.

#### فحص مهم

- إضافة رد جديد.
- تعديل رد سابق.
- فشل API يبقي النص في الحقل.

## Language

### LanguageScreen

المسار: `lib/features/language/screens/language_screen.dart`

#### ماذا تفعل الصفحة؟

تغيير لغة التطبيق. تعتمد على `LanguageController` و`AppConstants.languages`.

#### السلوك المتوقع

- عرض قائمة اللغات.
- اختيار لغة.
- حفظ اللغة في التخزين المحلي.
- تحديث GetX locale.

#### فحص مهم

- التبديل من العربي للإنجليزي.
- التبديل من الإنجليزي للعربي.
- اتجاه RTL/LTR بعد التبديل.
- بقاء اللغة بعد إغلاق التطبيق.

### LanguageBottomSheetWidget

المسار: `lib/features/language/widgets/language_bottom_sheet_widget.dart`

#### ماذا يفعل؟

نفس منطق اختيار اللغة لكن داخل bottom sheet، مناسب للاستخدام من صفحات أخرى.

## HTML Viewer

### HtmlViewerScreen

المسار: `lib/features/html/screens/html_viewer_screen.dart`

#### ماذا تفعل الصفحة؟

تعرض محتوى HTML مثل سياسة الخصوصية أو الشروط.

#### الاعتماديات

- `HtmlController`
- `HtmlService.getHtmlText(isPrivacyPolicy)`

#### فحص مهم

- سياسة الخصوصية.
- الشروط والأحكام.
- HTML طويل.
- روابط داخل المحتوى إن كانت قابلة للضغط.

## Splash / Update

### SplashScreen

المسار: `lib/features/splash/screens/splash_screen.dart`

#### ماذا تفعل الصفحة؟

نقطة بدء التطبيق. تحمل config من السيرفر، تحدد الموديول، تتحقق من الاتصال، وتقرر route التالي.

#### الاعتماديات

- `SplashController.getConfigData`
- `ConfigModel`
- `ProfileController`
- `AuthController`

#### السلوك المتوقع

- تحميل config قبل فتح التطبيق.
- التعامل مع أول تشغيل.
- التوجيه إلى login أو dashboard أو update حسب الحالة.
- حفظ إعدادات الموديول واللغة والعملة.

#### فحص مهم

- مستخدم غير مسجل.
- مستخدم مسجل.
- فشل config API.
- إصدار تطبيق قديم يتطلب update.

### UpdateScreen

المسار: `lib/features/update/screens/update_screen.dart`

#### ماذا تفعل الصفحة؟

تعرض شاشة تحديث التطبيق عند وجود نسخة مطلوبة من السيرفر.

#### السلوك المتوقع

- عرض زر تحديث عند وجود رابط.
- السماح بالتحديث الإجباري أو الاختياري حسب config.
- منع الدخول للتطبيق عند التحديث الإجباري.

#### فحص مهم

- تحديث إجباري.
- تحديث اختياري.
- رابط متجر غير متوفر.

## Forgot Password

### ForgetPassScreen

المسار: `lib/features/forgot_password/screens/forget_pass_screen.dart`

#### ماذا تفعل الصفحة؟

إدخال البريد أو الهاتف لطلب استعادة كلمة المرور.

#### فحص مهم

- إدخال بريد صحيح.
- إدخال قيمة فارغة.
- مستخدم غير موجود.

### VerificationScreen

المسار: `lib/features/forgot_password/screens/verification_screen.dart`

#### ماذا تفعل الصفحة؟

إدخال كود التحقق المرسل للمستخدم.

#### الاعتماديات

- `ForgotPasswordController.verifyToken`
- `ForgotPasswordController.updateVerificationCode`

#### فحص مهم

- كود صحيح.
- كود خاطئ.
- إعادة إرسال الكود إن كانت مدعومة.

### NewPassScreen

المسار: `lib/features/forgot_password/screens/new_pass_screen.dart`

#### ماذا تفعل الصفحة؟

تعيين كلمة مرور جديدة بعد التحقق.

#### فحص مهم

- كلمة مرور وتأكيد متطابقان.
- كلمة مرور قصيرة.
- token منتهي.

## Business Subscription Payment

### SubscriptionPaymentScreen

المسار: `lib/features/business/screens/subscription_payment_screen.dart`

#### ماذا تفعل الصفحة؟

تدفع خطة الاشتراك أو تختار خطة commission حسب إعدادات النظام.

#### الاعتماديات

- `BusinessController`
- `BusinessService.submitBusinessPlan`
- `SplashController.configModel.activePaymentMethodList`

#### السلوك المتوقع

- عرض trial إن كان مفعلاً.
- عرض طرق الدفع الرقمية.
- اختيار طريقة دفع.
- إرسال الخطة والتوجيه إلى شاشة الدفع أو النجاح.

#### فحص مهم

- free trial.
- payment method رقمية.
- commission plan.
- فشل الدفع.

### SubscriptionSuccessOrFailedScreen

المسار: `lib/features/business/screens/subscription_success_or_failed_screen.dart`

#### ماذا تفعل الصفحة؟

تعرض نتيجة عملية الاشتراك أو الدفع وتوجه المستخدم إلى تسجيل الدخول أو إعادة المحاولة.

#### فحص مهم

- نجاح اشتراك.
- فشل اشتراك.
- زر إعادة المحاولة.
- route بعد النجاح.

## Address / Location

لا توجد شاشة مستقلة في inventory الحالي، لكن هذه widgets تشغل جزءاً حساساً من تسجيل المتجر وتحديد المنطقة.

### SelectLocationAndModuleViewWidget

المسار: `lib/features/address/widgets/select_location_module_view_widget.dart`

#### ماذا يفعل؟

اختيار موقع المتجر والموديول/المنطقة أثناء التسجيل أو تعديل بيانات مرتبطة بالموقع.

#### الاعتماديات

- `AddressController`
- Google Maps
- `getCurrentLocation`
- `getZone`
- `getModules`

#### فحص مهم

- إذن الموقع مسموح.
- إذن الموقع مرفوض.
- موقع خارج نطاق الخدمة.
- اختيار منطقة ثم موديول.

### LocationSearchDialogWidget

المسار: `lib/features/address/widgets/location_search_dialog_widget.dart`

#### ماذا يفعل؟

بحث عن موقع باستخدام نص ثم اختيار نتيجة لتحديث الخريطة والعنوان.

#### فحص مهم

- بحث بنص عربي.
- بحث بنص إنجليزي.
- نتيجة بدون place details.

### ZoneSelectionWidget / PickupZoneWidget

المسارات:

- `lib/features/address/widgets/zone_selection_widget.dart`
- `lib/features/address/widgets/pickup_zone_widget.dart`

#### ماذا تفعل؟

اختيار zone أو pickup zone عند الحاجة، مع ربطها بالمنطقة والموديول.

## AI Helpers

لا توجد شاشة مستقلة، لكنها bottom sheets مهمة داخل إضافة أو تعديل المنتج.

### AiGeneratorBottomSheet

المسار: `lib/features/ai/widgets/ai_generator_bottom_sheet.dart`

#### ماذا يفعل؟

مدخل لاختيار نوع التوليد أو تشغيل أدوات AI المناسبة للمنتج.

### GenerateTitleBottomSheet

المسار: `lib/features/ai/widgets/generate_title_bottom_sheet.dart`

#### ماذا يفعل؟

اقتراح عناوين أو أوصاف بناءً على كلمات مفتاحية أو اسم أولي.

### ImageAnalyzeBottomSheet

المسار: `lib/features/ai/widgets/image_analyze_bottom_sheet.dart`

#### ماذا يفعل؟

تحليل صورة منتج واستخراج بيانات يمكن تعبئتها في شاشة المنتج.

#### الاعتماديات

- `AiController.generateTitleAndDes`
- `AiController.generateOtherData`
- `AiController.generateVariationData`
- `AiController.generateAttributeData`
- `AiController.generateTitleSuggestions`
- `AiController.generateFromImage`

#### فحص مهم

- صورة واضحة.
- صورة كبيرة تحتاج compression.
- فشل AI API.
- قبول البيانات المقترحة جزئياً وليس كلها.

## قائمة فحص دعم وإعدادات

- فحص كل صفحة في العربية والإنجليزية.
- فحص الصلاحيات للموظف مقابل مالك المتجر.
- فحص empty state لكل قائمة.
- فحص فشل API.
- فحص الرجوع navigation بعد كل عملية حفظ.
- فحص Android حقيقي للصور، الملفات، الإشعارات، الموقع، والروابط الخارجية.
