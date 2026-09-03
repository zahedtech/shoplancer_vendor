# توثيق واجهات برمجة التطبيقات للماركات (Brands APIs Documentation)

دليل شامل لجميع الـ Endpoints الخاصة بإدارة وعرض الماركات / العلامات التجارية (**Brands**) في نظام المتجر وتطبيق التاجر (`shoplancer_vendor`).

---

## 📌 الفهرس
1. [نظرة عامة والـ Headers المشتركة](#1-نظرة-عامة-والـ-headers-المشتركة)
2. [جلب قائمة الماركات (Get Brand List)](#2-جلب-قائمة-الماركات-get-brand-list)
3. [تغيير حالة الماركة للتاجر (Toggle Brand Status)](#3-تغيير-حالة-الماركة-لتاجر-toggle-brand-status)
4. [جلب منتجات ماركة محددة (Get Brand Products)](#4-جلب-منتجات-ماركة-محددة-get-brand-products)
5. [ربط المنتج بالماركة عند الإضافة/التعديل (Assign Brand to Item)](#5-ربط-المنتج-بالماركة-عند-الإضافةالتعديل-assign-brand-to-item)
6. [ماركات خدمات النقل/التأجير (Rental/Taxi Brands)](#6-ماركات-خدمات-النقلالتأجير-rentaltaxi-brands)
7. [نماذج البيانات (Data Models & Schemas)](#7-نماذج-البيانات-data-models--schemas)

---

## 1. نظرة عامة والـ Headers المشتركة

تتطلب معظم طلبات الـ API تمرير الترويسات (Headers) التالية لضمان التحقق من صلاحيات التاجر وتحديد الوحدة واللغة:

```http
Content-Type: application/json; charset=UTF-8
Authorization: Bearer {vendor_token}
moduleId: {moduleId}
X-localization: {ar | en}
vendorType: {store | restaurant | rental}
```

---

## 2. جلب قائمة الماركات (Get Brand List)

تُستخدم لجلب جميع الماركات المتاحة مع دعم التصفح المقسم إلى صفحات (Pagination) لعرضها في شاشة إدارة الماركات أو في القوائم المنسدلة عند إضافة وتعديل المنتجات.

* **الرابط (Endpoint):** `/api/v1/brand`
* **طريقة الطلب (Method):** `GET`
* **الصلاحية (Auth):** مطلوبة (Bearer Token)

### 🔹 معاملـات البحث والصفحات (Query Parameters):

| المعامل | النوع | إلزامي؟ | الوصف | القيمة الافتراضية |
| :--- | :--- | :---: | :--- | :--- |
| `offset` | `integer` | ❌ اختياري | رقم الصفحة الحالية | `1` |
| `limit` | `integer` | ❌ اختياري | عدد الماركات في كل صفحة | `10` |
| `search` | `string` | ❌ اختياري | كلمة البحث لتصفية الماركات بالاسم | - |

### 🔹 مثال على الطلب (Request):
```http
GET /api/v1/brand?offset=1&limit=10 HTTP/1.1
Host: your-domain.com
Authorization: Bearer 12|xxxxxxxxxxxxxxxxxxxxxxx
moduleId: 1
X-localization: ar
```

### 🔹 استجابة الخادم الناجحة (Response 200 OK):
```json
{
  "total_size": 25,
  "limit": "10",
  "offset": "1",
  "brands": [
    {
      "id": 1,
      "name": "Nike",
      "slug": "nike",
      "image_full_url": "https://your-domain.com/storage/app/public/brand/2026-01-01-xxxx.png",
      "status": 1,
      "items_count": 14,
      "created_at": "2026-01-01T12:00:00.000000Z",
      "updated_at": "2026-01-05T15:30:00.000000Z",
      "translations": [
        {
          "id": 1,
          "translationable_type": "App\\Models\\Brand",
          "translationable_id": 1,
          "locale": "ar",
          "key": "name",
          "value": "نايكي"
        }
      ]
    },
    {
      "id": 2,
      "name": "Adidas",
      "slug": "adidas",
      "image_full_url": "https://your-domain.com/storage/app/public/brand/2026-01-02-xxxx.png",
      "status": 1,
      "items_count": 8,
      "created_at": "2026-01-02T10:00:00.000000Z",
      "updated_at": "2026-01-02T10:00:00.000000Z",
      "translations": []
    }
  ]
}
```

---

## 3. تغيير حالة الماركة لتاجر (Toggle Brand Status)

تُستخدم لتفعيل أو إيقاف ظهور الماركة ومنتجاتها في متجر التاجر.

* **الرابط (Endpoint):** `/api/v1/vendor/brand/toggle-status`
* **طريقة الطلب (Method):** `POST`
* **الصلاحية (Auth):** مطلوبة (Bearer Token)

### 🔹 جسم الطلب (Request Body):
```json
{
  "brand_id": 1,
  "status": 0
}
```

| الحقل | النوع | إلزامي؟ | الوصف |
| :--- | :--- | :---: | :--- |
| `brand_id` | `integer` | ✅ نعم | معرّف الماركة المراد تعديل حالتها |
| `status` | `integer` | ✅ نعم | الحالة الجديدة (`1` = مفعل، `0` = معطل) |

### 🔹 استجابة الخادم الناجحة (Response 200 OK):
```json
{
  "status": true,
  "message": "Brand status updated successfully"
}
```

---

## 4. جلب منتجات ماركة محددة (Get Brand Products)

تُستخدم لعرض كافة المنتجات التابعة لعلامة تجارية معينة داخل متجر التاجر، مع إمكانية حذف أو تعديل أي منتج منها.

* **الرابط (Endpoint):** `/api/v1/vendor/get-items-list` (أو `/api/v1/vendor/brand/products`)
* **طريقة الطلب (Method):** `GET`
* **الصلاحية (Auth):** مطلوبة (Bearer Token)

### 🔹 معاملـات الرابط (Query Parameters):

| المعامل | النوع | إلزامي؟ | الوصف |
| :--- | :--- | :---: | :--- |
| `brand_id` | `integer` | ✅ نعم | معرّف الماركة المطلوبة |
| `offset` | `integer` | ❌ اختياري | رقم الصفحة الحالية (افتراضي `1`) |
| `limit` | `integer` | ❌ اختياري | عدد المنتجات في الصفحة (افتراضي `10`) |

### 🔹 مثال على الطلب (Request):
```http
GET /api/v1/vendor/get-items-list?offset=1&limit=10&brand_id=1 HTTP/1.1
Host: your-domain.com
Authorization: Bearer 12|xxxxxxxxxxxxxxxxxxxxxxx
moduleId: 1
```

### 🔹 استجابة الخادم الناجحة (Response 200 OK):
```json
{
  "total_size": 2,
  "limit": "10",
  "offset": "1",
  "items": [
    {
      "id": 101,
      "name": "Nike Air Max 270",
      "description": "حذاء رياضي مريح للجري والمشي",
      "image_full_url": "https://your-domain.com/storage/app/public/product/xxxx.png",
      "price": 150.0,
      "brand_id": 1,
      "category_id": 5,
      "status": 1,
      "available_time_starts": "00:00:00",
      "available_time_ends": "23:59:59"
    }
  ]
}
```

---

## 5. ربط المنتج بالماركة عند الإضافة/التعديل (Assign Brand to Item)

عند قيام التاجر بإنشاء منتج جديد أو تعديل منتج قائم عبر شاشة `AddItemScreen` أو `QuickAddItemScreen`، يتم إرسال معرّف الماركة المحددة.

* **إضافة منتج جديد:** `POST /api/v1/vendor/item/store`
* **تعديل منتج قائم:** `POST /api/v1/vendor/item/update`

### 🔹 الحقول المتعلقة بالماركة في الـ Payload (Form-Data / JSON):
```json
{
  "name": "حذاء رياضي",
  "price": 200,
  "brand_id": 1,
  "category_id": 5,
  "store_id": 12
}
```

---

## 6. ماركات خدمات النقل/التأجير (Rental/Taxi Brands)

في حال كانت المنشأة تعمل في قطاع تأجير المركبات أو سيارات الأجرة (Taxi / Vehicle Rental):

* **الرابط (Endpoint):** `/api/v1/rental/vendor/brand/list`
* **طريقة الطلب (Method):** `GET`
* **الوصف:** جلب ماركات السيارات والمركبات المعتمدة للنظام (مثل: Toyota, Hyundai, Mercedes).

---

## 7. نماذج البيانات (Data Models & Schemas)

### 🏷️ نموذج الماركة (`BrandModel`)
```typescript
interface BrandModel {
  id: number;                   // معرّف الماركة
  name: string;                 // اسم الماركة
  slug?: string;                // الرابط التعريفي للماركة
  image_full_url?: string;      // الرابط المباشر لشعار/صورة الماركة
  status?: number;              // الحالة: 1 نشط / 0 متوقف
  items_count?: number;         // عدد المنتجات التابعة للماركة
  created_at?: string;          // تاريخ الإنشاء
  updated_at?: string;          // تاريخ آخر تحديث
  translations?: Translation[]; // الترجمات المتاحة للغات المختلفة
}
```

### 🌐 نموذج الترجمة (`Translation`)
```typescript
interface Translation {
  id: number;
  translationable_type: string; // 'App\\Models\\Brand'
  translationable_id: number;
  locale: string;               // كود اللغة: 'ar', 'en', ...
  key: string;                  // 'name'
  value: string;                // القيمة المترجمة
}
```

### 📦 نموذج استجابة القائمة (`BrandListModel`)
```typescript
interface BrandListModel {
  total_size: number;           // إجمالي عدد الماركات
  limit: string;                // الحد لكل صفحة
  offset: string;               // رقم الصفحة
  brands: BrandModel[];         // مصفوفة الماركات
}
```

---

## ⚠️ رموز الاستجابة وأكواد الأخطاء (HTTP Status Codes)

| الكود | الحالة | الوصف |
| :---: | :--- | :--- |
| `200` | OK | تمت العملية بنجاح وتم إرجاع البيانات. |
| `401` | Unauthorized | الـ Token غير صالح أو انتهت صلاحيته. |
| `403` | Forbidden | الحساب غير مصرح له أو التاجر محظور. |
| `404` | Not Found | الماركة أو الصفحة المطلوبة غير موجودة. |
| `422` | Unprocessable Entity | خطأ في التحقق من صحة المدخلات (Validation Error). |
| `500` | Internal Server Error | خطأ داخلي في الخادم. |
