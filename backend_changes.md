# التعديلات المطلوبة من فريق الباك إند (Backend API Requirements)

تتناول هذه الوثيقة التعديلات المطلوبة في الـ API الخاصة بالسيرفر (Backend) لتمكين التجار (Vendors) من **إلغاء الطلبات** و**حذف أو استبدال المنتجات** في جميع مراحل الطلب بما في ذلك المراحل الأخيرة (`handover` و `picked_up`).

---

## 1. السماح بإلغاء الطلب في جميع المراحل النشطة (Order Cancellation API)

### 📌 المشكلة الحالية:
الـ Backend يقوم برفض طلب الإلغاء إذا كانت حالة الطلب قد تجاوزت مرحلة `pending` أو `confirmed` (مثلاً: `processing`, `cooking`, `handover`, `picked_up`).

### 🛠️ التعديل المطلوب في السيرفر:
* **تعديل شروط الفحص (Validation Check):**
  السماح للتاجر بإلغاء الطلب عبر الـ Endpoint الخاصة بالإلغاء:
  `POST /api/v1/vendor/order/cancel` أو `POST /api/v1/vendor/order/update-order-status`
  في جميع الحالات التالية:
  - `pending`
  - `confirmed`
  - `processing` / `cooking`
  - `handover` / `ready_for_handover`
  - `picked_up` / `food_on_the_way`

* **إدارة المستحقات والمدفوعات (Payment & Refund):**
  في حال كان الطلب مدفوعاً إلكترونياً (Online Payment) وتم إلغاؤه في مرحلة متأخرة، يجب معالجة عملية إرجاع المبلغ لـ Wallet/Account الزبون تلقائياً.

* **إشعار مندوب التوصيل (Deliveryman Notification):**
  في حال كان هناك مندوب توصيل معيّن للطلب (`handover` أو `picked_up`):
  1. إرسال إشعار FCM للمندوب بأن الطلب قد أُلغي.
  2. تحرير المندوب (Free up deliveryman status) ليتمكن من استلام طلبات أخرى.

---

## 2. السماح بحذف واستبدال المنتجات في المراحل الأخيرة (Update Order Items API)

### 📌 المشكلة الحالية:
الـ Endpoint الخاصة بالتعديل على عناصر الطلب:
`POST /api/v1/vendor/order/update-order-items`
تمنع التعديل (إزالة عنصر `action: remove` أو إضافة عنصر `action: add`) إذا كانت حالة الطلب `handover` أو `picked_up`.

### 🛠️ التعديل المطلوب في السيرفر:
* **تحديث صلاحيات التعديل (API Validation):**
  السماح باستدعاء `update-order-items` حتى لو كانت حالة الطلب في مرحلة التسليم (`handover` / `picked_up`).

* **إعادة حساب الفاتورة تلقائياً (Invoice & Total Recalculation):**
  عند حذف منتج أو استبداله:
  1. إعادة حساب إجمالي سعر المنتجات (`order_amount`).
  2. إعادة حساب الضريبة والخصم (`total_tax_amount`, `store_discount_amount`).
  3. تحديث الفاتورة والتوتال النهائي للطلب.

* **تحديث البيانات لدى تطبيق مندوب التوصيل وتطبيق العميل:**
  إعادة إرسال البيانات المحدثة للطلب للعميل وللمندوب حتى تظهر الفاتورة بالمنتجات المعدلة بدقة.

---

## 📋 ملخص الأندبوينتس المستهدفة للتعديل:

| الـ Endpoint | الأكشن | التعديل المطلوب |
|---|---|---|
| `POST /api/v1/vendor/order/update-order-status` | `status: canceled` | قبول الإلغاء في حالات `processing`, `handover`, `picked_up`. |
| `POST /api/v1/vendor/order/cancel` | cancel order | قبول الإلغاء في كافة المراحل النشطة قبل `delivered`. |
| `POST /api/v1/vendor/order/update-order-items` | `action: remove` / `action: add` | السماح بحذف/إضافة المنتجات في مراحل التسليم الأخيرة. |

