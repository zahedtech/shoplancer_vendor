## الهدف

كل روابط المشاركة في التطبيق (نسخ الرابط، مشاركة واتساب، Web Share) لازم تظهر وتُنسخ بالشكل الثابت:

```
https://market.shoplanser.com/store/{slug}
```

بدون المرور على edge function `store-meta` ولا أي رابط معاينة Lovable. الرابط "fake" دلوقتي بمعنى إنه مش بيحط نطاق الـ frontend الحقيقي — وده المطلوب فعلاً.

## التغييرات

### 1. `src/lib/share.ts` — تبسيط `buildShareUrl`

- تعديل `buildShareUrl(slug, path?)` بحيث يرجّع دايماً:
  ```
  https://market.shoplanser.com/store/{slug}
  ```
  بدل ما يبني URL على edge function.
- إزالة استخدام `SUPABASE_URL` و query params (`slug`, `path`, `base`) من بناء الرابط.
- الإبقاء على `buildPublicStoreUrl` كما هو (هو أصلاً بيرجع نفس الشكل).
- الإبقاء على `shareStoreLink` كما هو — هيستخدم الرابط الجديد تلقائياً.

### 2. `src/pages/Account.tsx` — لا تغيير في الكود

كل الاستخدامات (السطور 390، 397، 413، 424) بتستدعي `buildShareUrl(slug)` فهتاخد الشكل الجديد تلقائياً:
- النص الظاهر: `market.shoplanser.com/store/hashem`
- زر النسخ: ينسخ `https://market.shoplanser.com/store/hashem`
- زر واتساب: يبعت الاسم + نفس الرابط
- زر Web Share: يشارك نفس الرابط

### 3. `supabase/functions/store-meta/index.ts` — يتساب كما هو

لإن روابط المشاركة مش هتمر عليه تاني، الـ function هتفضل موجودة كـ fallback مش مستخدم. مش هنحذفها عشان ما نكسرش أي رابط قديم اتشارك قبل كده.

## بعد التنفيذ

- نسخ رابط متجر `hashem` هينتج: `https://market.shoplanser.com/store/hashem`
- مشاركة واتساب هتبعت نفس الرابط مع اسم المتجر.
- ملاحظة: شكل معاينة OG (الصورة + الاسم) على واتساب/فيسبوك هيعتمد كلياً على ما يقدمه `market.shoplanser.com` نفسه، مش على الـ edge function بتاعتنا.
