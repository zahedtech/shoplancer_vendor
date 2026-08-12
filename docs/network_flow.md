# شرح عملية Network في المشروع

هذا الملف يشرح كيف تتحرك طلبات الشبكة داخل التطبيق من الشاشة إلى السيرفر ثم الرجوع للواجهة.

## الصورة العامة

تدفق الشبكة في أغلب features يأخذ هذا الشكل:

```text
Screen/Widget
  -> Controller (GetX)
  -> Service
  -> Repository
  -> ApiClient
  -> HTTP API
  -> ApiClient.handleResponse
  -> Repository parses model
  -> Service returns result
  -> Controller updates state
  -> UI rebuilds via GetBuilder/GetX
```

## ApiClient

المسار: `lib/api/api_client.dart`

`ApiClient` هو نقطة الاتصال المركزية مع السيرفر. يعتمد على package `http` ويرجع `Get.Response` حتى تبقى بقية طبقات GetX متناسقة.

### التهيئة

عند إنشاء `ApiClient` يتم قراءة:

- `token` من `SharedPreferences`.
- `type` من `SharedPreferences`.
- `languageCode`.

ثم يتم بناء headers عبر `updateHeader`.

### Headers الأساسية

```text
Content-Type: application/json; charset=UTF-8
localizationKey: <language code>
moduleId: <module id or empty>
Authorization: Bearer <token>
vendorType: <type>
```

هذه headers مهمة لأن السيرفر يعتمد عليها لمعرفة:

- اللغة الحالية.
- الموديول الحالي.
- هوية المستخدم.
- نوع البائع أو الحساب.

## أنواع الطلبات المدعومة

### GET

الدالة: `getData`

تستخدم لجلب القوائم والتفاصيل، مثل المنتجات، الطلبات، الإشعارات، والتقارير.

### POST JSON

الدالة: `postData`

تستخدم للإضافة أو تنفيذ action، مثل تسجيل الدخول، إنشاء طلب POS، تطبيق كوبون، أو تغيير حالة.

### POST Multipart

الدالة: `postMultipartData`

تستخدم عند رفع صور أو ملفات، مثل:

- تسجيل المتجر.
- تحديث بيانات المتجر.
- إضافة/تعديل منتج مع صور.
- إنشاء إعلان مع صورة أو فيديو.
- AI image analyze.

تدعم نوعين:

- `MultipartBody` للصور من `XFile`.
- `MultipartDocument` للملفات من `FilePickerResult`.

### PUT JSON

الدالة: `putData`

تستخدم للتحديثات التي يطلبها API كـ PUT.

### PUT Form

الدالة: `putFormData`

تستخدم عندما يحتاج API إلى:

```text
Content-Type: application/x-www-form-urlencoded
```

### DELETE

الدالة: `deleteData`

تستخدم للحذف، وتدعم body اختياري.

## Timeout

كل طلب JSON عادي يستخدم:

```text
timeoutInSeconds = 30
```

إذا حصل timeout أو exception، يرجع:

```text
Response(statusCode: 1, statusText: noInternetMessage)
```

رسالة الشبكة الافتراضية:

```text
Connection to API server failed due to internet connection
```

## Logging

`ApiClient` يستخدم:

- `ApiLogger.logRequest`
- `ApiLogger.logResponse`

ويضيف timing في debug mode:

```text
[API-TIME] #id START ...
[API-TIME] #id DONE ...
```

هذا يساعد في معرفة:

- عدد الطلبات المتزامنة.
- مدة كل طلب.
- status code.
- حجم response.
- endpoint المختصر.

## معالجة Response

الدالة: `handleResponse`

### parsing

تحاول قراءة `response.body` كـ JSON:

```dart
body = jsonDecode(response.body)
```

إذا فشل التحويل، يبقى body كنص.

### النجاح

أي status code بين `200` و`299` يعتبر نجاحاً.

### الأخطاء

إذا كان response ليس نجاحاً:

- لو body يحتوي `errors`، يتم استخراج أول رسالة.
- لو body يحتوي `message`، يتم وضعها في `statusText`.
- لو body فارغ، يتم اعتباره مشكلة اتصال.

## handleError

كل دوال `ApiClient` فيها parameter:

```dart
bool handleError = true
```

### عندما يكون true

إذا الطلب فشل:

- يستدعي `ApiChecker.checkApi(response)`.
- يرجع `Response()` فارغ.

هذا مناسب للشاشات التي تريد إظهار snackbar تلقائياً وعدم التعامل اليدوي مع الخطأ.

### عندما يكون false

يرجع response الأصلي حتى controller أو service يتعامل معه يدوياً.

هذا مستخدم في حالات مثل:

- login.
- POS order.
- coupon apply.
- حذف أو تغيير status يحتاج رسالة خاصة.

## ApiChecker

المسار: `lib/api/api_checker.dart`

`ApiChecker` يتعامل مع الأخطاء العامة.

### 401 Unauthorized

عند status `401`:

- يمنع تكرار redirect عبر `_isRedirectingToSignIn`.
- يمسح بيانات تسجيل الدخول من `AuthController.clearSharedData`.
- يوجه المستخدم إلى صفحة تسجيل الدخول.
- يعرض snackbar بأن الجلسة انتهت أو تم تسجيل الدخول من جهاز آخر.

### أخطاء أخرى

يحاول استخراج رسالة من:

- `response.body['message']`
- أول عنصر في `response.body['errors']`
- أو `response.statusText`

ثم يعرضها عبر `showCustomSnackBar`.

## أين يتم بناء URL؟

غالباً داخل repository باستخدام `AppConstants`.

مثال من المنتجات:

```text
StoreRepository.getItemList
  -> AppConstants.itemListUri
  -> query: offset, limit, type, search, barcode, min_price, max_price, sort, category_id
```

مثال من التقارير:

```text
ReportRepository.getExpenseList
  -> expenseListUri
  -> query: limit, offset, restaurant_id, from, to, search
```

مثال من HTML:

```text
HtmlRepository.getHtmlText
  -> privacyPolicyUri أو termsAndConditionsUri
  -> headers مخصصة بدون moduleId
```

## لماذا توجد Repository و Service معاً؟

### Repository

مسؤول عن:

- endpoint.
- query parameters.
- body.
- multipart fields.
- تحويل response إلى model.

### Service

مسؤول عن:

- تغليف repository.
- أي منطق business خفيف قبل أو بعد الطلب.
- إبقاء controller بعيداً عن تفاصيل التخزين أو API.

### Controller

مسؤول عن:

- loading state.
- pagination state.
- حفظ القيم المختارة.
- استدعاء service.
- تحديث الواجهة بـ `update()`.
- عرض snackbar أو navigation بعد النجاح.

## Pagination

النمط الشائع:

- `offset`
- `limit=10` أو `limit=20`
- `pageSize`
- قائمة offsets لمنع تكرار نفس الصفحة.
- `showBottomLoader` عند تحميل المزيد.

أمثلة:

- المنتجات: `limit=10`.
- pending products: `limit=20`.
- التقارير: `limit=10`.
- الإعلانات: `limit=10`.

## Multipart والملفات

عند رفع صور:

- على الويب يستخدم `readAsBytes`.
- على الموبايل يستخدم `File(path)` و`file.lengthSync`.
- يتم حفظ اسم الملف من path.

ملاحظات فحص:

- صورة كبيرة.
- صورة بصيغة غير متوقعة.
- أكثر من صورة.
- ملف فيديو للإعلانات.
- أذونات Android للصور والكاميرا.

## تحديث Headers بعد تغيّر اللغة أو الموديول

بعض repositories مثل `LanguageRepository` و`ProfileRepository` تستدعي:

```dart
apiClient.updateHeader(token, languageCode, moduleID, type)
```

هذا ضروري بعد:

- تسجيل الدخول.
- تغيير اللغة.
- تحميل profile ومعرفة module id.
- تغيير نوع vendor.

## Offline POS

يوجد مسار خاص في:

- `lib/features/pos/data/local/pos_offline_repository.dart`
- `lib/features/pos/data/local/pos_sync_service.dart`

الفكرة:

- حفظ عمليات POS محلياً عند الحاجة.
- لاحقاً `PosSyncService` يرسل الطلبات عبر `ApiClient.postData` أو `ApiClient.putData`.

هذا مختلف عن بقية features لأنه يضيف طبقة queue/sync محلية قبل الشبكة.

## Network Checklist

- كل repository يبني URL مشفر عند وجود input من المستخدم، مثل البحث والباركود.
- استخدام `handleError: false` عندما تحتاج الشاشة تعرض رسالة مخصصة.
- عدم الاعتماد على `Response()` الفارغ بعد فشل `handleError: true`.
- تحديث headers بعد login/profile/language/module.
- فحص 401 من أي endpoint والتأكد أن redirect لا يتكرر.
- فحص timeout وضعف الإنترنت.
- فحص multipart على Android حقيقي.
- فحص pagination حتى آخر صفحة.
- فحص أن controllers لا تبقي `isLoading = true` بعد failure.
