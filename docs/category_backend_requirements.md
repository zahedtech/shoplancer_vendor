# Backend Requirements for Category Management (متطلبات الباك إند لإدارة الفئات)

---

## 1. طلب إضافة فئة جديدة للأدمن (Request Category Addition)

### **الوصف الوظيفي:**
تمكين التاجر من إرسال طلب إلى الأدمن لإضافة فئة (Category) إلى متجره، سواء كانت الفئة موجودة في الفئات العامة للموديول (Global Module Categories) أو فئة جديدة مخصصة بالكامل.

### **API Specification:**

- **Endpoint:** `POST /api/v1/vendor/category-request`
- **Headers:**
  ```http
  Authorization: Bearer {vendor_token}
  X-localization: ar
  moduleId: {module_id}
  Content-Type: application/json
  ```
- **Request Body:**
  ```json
  {
    "category_id": 243,                // ID الفئة إذا كانت صنفاً عاماً موجوداً بالفعل (اختياري)
    "custom_category_name": "مشروبات طاقة", // اسم الفئة المطلوبة إذا كانت غير موجودة صراحةً (اختياري)
    "reason_or_note": "نحتاج إضافة هذه الفئة لعرض منتجات جديدة بالمتجر" // ملاحظات للتاجر (اختياري)
  }
  ```

- **Expected Response (Success 201 Created):**
  ```json
  {
    "status": true,
    "message": "تم إرسال طلب إضافة الفئة إلى الأدمن بنجاح وفي انتظار المراجعة",
    "data": {
      "id": 12,
      "vendor_id": 262,
      "store_id": 187,
      "category_id": 243,
      "status": "pending" // (pending / approved / rejected)
    }
  }
  ```

---

## 2. التحكم في تفعيل / إيقاف الفئة ومنتجاتها بالكامل (Category Active/Deactive Control)

### **الوصف الوظيفي:**
عند قيام التاجر بـ **إيقاف فئة (Deactivate Category)** من شاشة الفئات بالهاتف:
1. يتم تعيين حالة الفئة لهذا المتجر إلى غير نشطة `status = 0`.
2. **تلقائياً في الباك إند**: يتم إيقاف وتغطية/إخفاء **جميع المنتجات المرتبطة بهذه الفئة** لمتجر التاجر الحالي من العرض للعملاء عبر التطبيق أو المتجر الإلكتروني.

عند قيام التاجر بـ **تفعيل الفئة (Activate Category)**:
1. يتم تعيين حالة الفئة إلى نشطة `status = 1`.
2. يتم إعادة تفعيل المنتجات المرتبطة بالفئة لتظهر مجدداً للعملاء.

### **API Specification:**

- **Endpoint:** `POST /api/v1/vendor/category/toggle-status`  (أو `PUT /api/v1/vendor/category/status`)
- **Headers:**
  ```http
  Authorization: Bearer {vendor_token}
  X-localization: ar
  moduleId: {module_id}
  Content-Type: application/json
  ```
- **Request Body:**
  ```json
  {
    "category_id": 243,
    "status": 0 // 1 لـ Active (تفعيل)، 0 لـ Deactive (تعطيل/إيقاف)
  }
  ```

- **Expected Backend Logic (المطلوب تنفيذه في السيرفر):**
  ```sql
  -- 1. تحديث حالة الفئة للمتجر
  UPDATE store_category 
  SET status = :status 
  WHERE store_id = :store_id AND category_id = :category_id;

  -- 2. إيقاف / تفعيل كافة منتجات هذه الفئة للمتجر
  UPDATE item 
  SET status = :status 
  WHERE store_id = :store_id AND category_id = :category_id;
  ```

- **Expected Response (Success 200 OK):**
  ```json
  {
    "status": true,
    "message": "تم تحديث حالة الفئة والمنتجات التابعة لها بنجاح",
    "data": {
      "category_id": 243,
      "is_active": false,
      "affected_products_count": 15
    }
  }
  ```
