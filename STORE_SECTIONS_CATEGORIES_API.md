# تقرير ومشاكل الـ API لسكاشن المتجر والبيانات (Store Sections & Products API Issues)
## 📌 الجزء الثاني: مواصفات السكاشن وإدارة الأقسام (Reorder & Toggle Categories)

---

### 1. جلب السكاشن مع بيانات الترتيب والتفعيل (`GET /api/v1/vendor/store/sections`)

يجب إرجاع حقلي `is_active` و `sort_order` لكل قسم تفرعي داخل السكشن:

```json
{
  "status": true,
  "data": [
    {
      "id": 11,
      "section_key": "main_banner",
      "name": "البانر الرئيسي",
      "is_active": 1,
      "sort_order": 1
    },
    {
      "id": 59,
      "section_key": "category_products",
      "name": "تصفح الأقسام والمنتجات",
      "is_active": 1,
      "sort_order": 2,
      "categories": [
        {
          "id": 236,
          "name": "أعشاب و بهارات",
          "image_full_url": "https://pub-7182f5f1529e4672bcc91afeab456c6f.r2.dev/category/2026-09-03-6a991a3141c1c.webp",
          "is_active": 1,
          "sort_order": 1
        },
        {
          "id": 246,
          "name": "المشروبات",
          "image_full_url": "https://pub-7182f5f1529e4672bcc91afeab456c6f.r2.dev/category/2026-09-01-6a966ba3ee00b.webp",
          "is_active": 0,
          "sort_order": 2
        }
      ]
    }
  ]
}
```

---

### 2. حفظ ترتيب وتفعيل السكاشن والأقسام (`POST /api/v1/vendor/store/sections/update`)

* **Headers:**
  ```http
  Authorization: Bearer {vendor_token}
  Content-Type: application/json
  Accept: application/json
  ```

* **الـ Request Body المرسل من التطبيق:**

```json
{
  "sections": [
    {
      "id": 11,
      "section_id": 11,
      "section_key": "main_banner",
      "name": "البانر الرئيسي",
      "is_active": 1,
      "sort_order": 1
    },
    {
      "id": 59,
      "section_id": 59,
      "section_key": "category_products",
      "name": "تصفح الأقسام والمنتجات",
      "is_active": 1,
      "sort_order": 2,
      "categories": [
        {
          "id": 236,
          "name": "أعشاب و بهارات",
          "is_active": 1,
          "status": 1,
          "sort_order": 1
        },
        {
          "id": 246,
          "name": "المشروبات",
          "is_active": 0,
          "status": 0,
          "sort_order": 2
        }
      ],
      "category_ids": [236]
    }
  ]
}
```

---

### 3. المعالجة في السيرفر (Backend Pivot Sync Logic)

```php
foreach ($request->sections as $sectionData) {
    $section = StoreSection::find($sectionData['id']);
    if ($section) {
        $section->update([
            'is_active'  => $sectionData['is_active'] ?? 1,
            'sort_order' => $sectionData['sort_order'] ?? 0,
        ]);

        if (isset($sectionData['categories']) && is_array($sectionData['categories'])) {
            $syncData = [];
            foreach ($sectionData['categories'] as $cat) {
                $syncData[$cat['id']] = [
                    'is_active'  => $cat['is_active'] ?? 1,
                    'sort_order' => $cat['sort_order'] ?? 0,
                ];
            }
            $section->categories()->sync($syncData);
        }
    }
}
```
