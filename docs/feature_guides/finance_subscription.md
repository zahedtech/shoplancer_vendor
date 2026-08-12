# شرح Features: Payment, Wallet, Disbursement, Subscription

هذا الملف يغطي صفحات المال والاشتراك: المحفظة، الدفع، السحب، طرق السحب، وخطة الاشتراك.

## Payment - WalletScreen

**Path**: `lib/features/payment/screens/wallet_screen.dart`
**Entry Point**: تبويب Wallet داخل `DashboardScreen` أو route `/wallet`
**Controllers**: `PaymentController`, `ProfileController`, `SplashController`
**Purpose**: عرض أرصدة المتجر، معاملات المحفظة، طلبات السحب، وخيارات إدارة المال.

### ماذا يظهر للمستخدم

- AppBar بعنوان `wallet`.
- بطاقات رصيد:
  - رصيد الدفع الإلكتروني القابل للسحب.
  - رصيد الدفع عند الاستلام/الكاش في اليد.
- معاملات المحفظة.
- طلبات السحب وحالاتها.
- تنبيهات مرتبطة بالمحفظة عبر `WalletAttentionAlertWidget`.
- أزرار أو روابط لطلب سحب أو إدارة بيانات السحب حسب الصلاحيات.

### ماذا يستطيع المستخدم أن يفعل

- مراجعة الرصيد.
- تحديث بيانات المحفظة بالسحب للتحديث.
- مراجعة سجل السحوبات.
- مراجعة معاملات المحفظة.
- الانتقال لإعداد طريقة السحب أو طلب سحب حسب الصلاحية.

### البيانات والمنطق

- عند فتح الشاشة يستدعي:
  - `getWithdrawList`
  - `getWithdrawMethodList`
  - `getWalletPaymentList`
  - `getWalletInfo`
  - `ProfileController.getProfile` إذا profile غير موجود.
- العرض يعتمد على `profileController.modulePermission.wallet`.
- تنسيق تواريخ المعاملات يتم محليًا داخل الشاشة.

### الحالات

- **No permission**: إذا صلاحية wallet غير مفعلة لا يجب إظهار محتوى المحفظة.
- **Loading**: ينتظر profile وwithdrawList.
- **Refresh**: Pull to refresh يعيد تحميل profile وwallet info وwithdraw list.

### الانتقال

- من Dashboard tab الرابع.
- إلى payment history أو withdraw history أو إعدادات السحب حسب أزرار الصفحة.

## Payment - PaymentScreen

**Path**: `lib/features/payment/screens/payment_screen.dart`
**Route / Entry Point**: `RouteHelper.payment` / `/payment`
**Controller**: `ProfileController`
**Purpose**: فتح رابط بوابة الدفع داخل InAppBrowser ومراقبة redirect النجاح أو الفشل.

### ماذا يظهر للمستخدم

- AppBar بعنوان `payment`.
- خلفية بلون primary.
- مؤشر تحميل.
- InAppBrowser خارجي/داخلي يفتح `redirectUrl`.
- Dialog تأكيد الخروج من الدفع عند محاولة الرجوع.

### ماذا يستطيع المستخدم أن يفعل

- إكمال الدفع داخل صفحة بوابة الدفع.
- الرجوع مع ظهور dialog تأكيد.

### البيانات والمنطق

- `selectedUrl` يأتي من `redirectUrl`.
- يفتح `MyInAppBrowser`.
- يراقب الروابط:
  - `/payment-success`
  - `/payment-fail`
  - `/payment-cancel`
  - `/success?flag=success|fail|cancel`
- إذا الدفع خاص بالاشتراك، يذهب إلى route نتيجة الاشتراك.
- إذا الدفع لمحفظة/عملية عامة، يذهب إلى success route.

### الحالات

- **Success**: redirect إلى success route.
- **Fail**: redirect إلى fail route.
- **Cancel**: redirect إلى cancel route.
- **Back attempt**: يظهر `FundPaymentDialogWidget`.

### الانتقال

- من اشتراك أو top up أو أي عملية تحتاج بوابة دفع.
- إلى `PaymentSuccessfulScreen` أو `SubscriptionSuccessOrFailedScreen` حسب نوع العملية.

## Payment - Other Screens

### BankInfoScreen

**Path**: `lib/features/payment/screens/bank_info_screen.dart`
**Purpose**: عرض أو تعديل بيانات البنك الخاصة بالبائع.

يرتبط بـ `PaymentController.updateBankInfo` ويحدث profile بعد نجاح الحفظ.

### PaymentHistoryScreen

**Path**: `lib/features/payment/screens/payment_history_screen.dart`
**Purpose**: عرض سجل معاملات الدفع.

### WithdrawHistoryScreen

**Path**: `lib/features/payment/screens/withdraw_history_screen.dart`
**Purpose**: عرض سجل طلبات السحب وحالاتها.

### PrepaidWalletScreen

**Path**: `lib/features/payment/screens/prepaid_wallet_screen.dart`
**Purpose**: إدارة/عرض المحفظة المسبقة إذا كانت مفعلة في النظام.

### PaymentSuccessfulScreen

**Path**: `lib/features/payment/screens/payment_successful_screen.dart`
**Purpose**: عرض نتيجة عملية الدفع للمستخدم بعد redirect.

## PaymentController - دور عام

**Path**: `lib/features/payment/controllers/payment_controller.dart`

يدير:

- قائمة السحوبات `withdrawList`.
- إجمالي المبالغ pending/withdrawn.
- طرق السحب `widthDrawMethods`.
- حقول طريقة السحب الديناميكية.
- معاملات المحفظة `transactions`.
- طرق الدفع offline.
- طلبات topup.
- صورة إيصال الدفع.
- طلب سحب.
- تحديث بيانات البنك.
- عمل adjustment للمحفظة.

## Disbursement - DisbursementMenuScreen

**Path**: `lib/features/disbursement/screens/disbursement_menu_screen.dart`
**Route / Entry Point**: `RouteHelper.disbursementMenu` / `/disbursement-menu`
**Controller**: `ProfileController`
**Purpose**: صفحة قائمة فرعية لعمليات disbursement.

### ماذا يظهر للمستخدم

- AppBar بعنوان `disbursement`.
- بطاقة `view_disbursement_history` إذا صلاحية `disbursementReport` مفعلة.
- بطاقة `disbursement_method_setup` إذا صلاحية `walletMethod` مفعلة.

### ماذا يستطيع المستخدم أن يفعل

- فتح سجل السحوبات.
- فتح إعداد طرق السحب.

### البيانات والمنطق

- يعتمد على `profileController.modulePermission`.
- كل بطاقة تنتقل إلى route محدد.

### الحالات

- إذا لا توجد صلاحيات، قد تظهر الصفحة فارغة.

### الانتقال

- إلى `DisbursementScreen`.
- إلى `WithdrawMethodScreen`.

## Disbursement - Screens

### DisbursementScreen

**Path**: `lib/features/disbursement/screens/disbursement_screen.dart`
**Purpose**: عرض تقرير/سجل disbursement مع pagination.

### WithdrawMethodScreen

**Path**: `lib/features/disbursement/screens/withdraw_method_screen.dart`
**Purpose**: عرض طرق السحب الخاصة بالبائع، تعيين الافتراضي، أو حذف طريقة.

### AddWithdrawMethodScreen

**Path**: `lib/features/disbursement/screens/add_withdraw_method_screen.dart`
**Purpose**: إضافة طريقة سحب جديدة حسب الحقول الديناميكية للطريقة.

## DisbursementController - دور عام

**Path**: `lib/features/disbursement/controllers/disbursement_controller.dart`

يدير:

- تحميل طرق السحب المحفوظة.
- إضافة طريقة سحب.
- جعل طريقة هي الافتراضية.
- حذف طريقة.
- تحميل تقرير disbursement.
- تجهيز حقول ديناميكية لطريقة السحب بالاعتماد على `PaymentController.widthDrawMethods`.

## Subscription - MySubscriptionScreen

**Path**: `lib/features/subscription/screens/my_subscription_screen.dart`
**Route / Entry Point**: `RouteHelper.mySubscription` / `/my-subscription`
**Controller**: `SubscriptionController`, `ProfileController`, `AuthController`
**Purpose**: عرض خطة العمل/الاشتراك الحالية، تفاصيل الاشتراك، ومعاملات الاشتراك.

### ماذا يظهر للمستخدم

- AppBar بعنوان `my_business_plan`.
- محتوى مختلف حسب business model:
  - commission.
  - subscription.
  - none.
  - unsubscribed.
- تفاصيل الاشتراك عبر `SubscriptionDetailsWidget`.
- تبويبات أو أقسام للمعاملات.
- زر تغيير أو تجديد الخطة عبر bottom sheets.
- سجل معاملات الاشتراك عبر `TransactionWidget`.

### ماذا يستطيع المستخدم أن يفعل

- مراجعة الخطة الحالية.
- رؤية عمولة الطلب إذا الخطة commission.
- مراجعة معاملات الاشتراك.
- تغيير الخطة.
- تجديد الاشتراك.
- الدفع عبر wallet أو pay now حسب الخيارات.

### البيانات والمنطق

- عند الفتح:
  - يحدد profile من `ProfileController` إذا المستخدم logged in، أو من `AuthController` في حالات expired/غير logged.
  - يستدعي `SubscriptionController.initSetDate`.
  - يضبط offset.
  - يحمل `getSubscriptionTransactionList`.
  - يستدعي `ProfileController.trialWidgetShow`.
- عند الرجوع من notification يرجع إلى initial route.

### الحالات

- **Commission model**: يعرض نسبة العمولة بدل باقة اشتراك.
- **Subscription model**: يعرض تفاصيل الاشتراك والتجديد.
- **Unsubscribed/none**: يعرض خيارات اختيار أو تفعيل خطة.
- **Trial widget**: يظهر/يخفى حسب route.

### الانتقال

- من القائمة أو إشعار.
- إلى bottom sheets تغيير أو تجديد الخطة.
- إلى `PaymentScreen` عند اختيار دفع خارجي.
- إلى شاشة نتيجة الاشتراك بعد redirect.

## SubscriptionController - دور عام

**Path**: `lib/features/subscription/controllers/subscription_controller.dart`

يدير:

- قائمة الباقات.
- الباقة المختارة.
- نوع الاشتراك.
- طريقة الدفع.
- بيانات profile الخاصة بالاشتراك.
- معاملات الاشتراك مع pagination/filter/search.
- تنبيه نهاية التجربة.
- تجديد أو تغيير خطة العمل.

## رحلة مالية مختصرة

1. يدخل المستخدم إلى Wallet.
2. يرى الرصيد وسجل المعاملات والسحوبات.
3. إذا احتاج سحب، يضبط طريقة السحب من Disbursement Method.
4. يطلب السحب أو يراجع سجله.
5. إذا احتاج اشتراك، يفتح My Subscription.
6. يختار خطة أو يجدد.
7. إذا الدفع خارجي، ينتقل إلى PaymentScreen.
8. PaymentScreen يراقب redirect ويرجع بنتيجة success/fail/cancel.

## ملاحظات متابعة

- يجب توثيق تفاصيل widgets الخاصة بالسحب والدفع عند الحاجة، مثل `WithdrawRequestBottomSheetWidget`.
- يجب تفصيل `PaymentHistoryScreen` و`WithdrawHistoryScreen` بعد قراءة واجهاتهما كاملة.
- يجب اختبار مسار redirect للبوابة على جهاز حقيقي لأنه يعتمد على URLs الباك إند.
