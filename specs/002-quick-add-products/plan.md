# Implementation Plan: Quick Add Products Enhancements

**Branch**: `002-quick-add-products` | **Date**: 2026-08-10 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/002-quick-add-products/spec.md`

## Summary

تحسين شاشة `QuickAddItemScreen` لدعم إدخال/مسح الباركود، استخدام كيباد رقمي داخلي مشترك للسعر والمخزون بدون فتح كيبورد الموبايل، وإتاحة اختيار فئة فرعية مرتبطة بالفئة الرئيسية. التنفيذ سيعيد استخدام `BarcodeScannerScreen` و`CategoryController` و`StoreController.addItem` مع أقل تعديل ممكن على موديل/إرسال المنتج إذا تأكد حقل API للباركود.

## Technical Context

**Language/Version**: Dart / Flutter (حسب `pubspec.yaml` وبيئة المشروع الحالية)

**Primary Dependencies**: Flutter Material, GetX, `mobile_scanner`, `image_picker`, widgets الموجودة في `lib/common/widgets/`

**Storage**: لا يوجد تخزين محلي جديد؛ البيانات تظل staged في memory ثم ترسل عبر API الإضافة الحالي.

**Testing**: `flutter analyze`، اختبارات Widget/Manual QA للشاشة، وفحص payload الإضافة عند توفر بيئة API.

**Target Platform**: iOS وAndroid بالأساس؛ الشاشة Flutter مشتركة وقد تظهر على web/desktop إذا كان المسار مفعلا.

**Project Type**: Flutter mobile vendor app.

**Performance Goals**: فتح شاشة الإضافة السريعة بدون تأخير ملحوظ؛ تحميل الفئات الفرعية عند تغيير الفئة فقط؛ عدم إعادة بناء أو إرسال الشبكة لكل زر في الكيباد.

**Constraints**: الالتزام بـ GetX الحالي، عدم إضافة مكتبات جديدة، عدم تعديل ملفات generated/cache، واستخدام localization للنصوص الجديدة.

**Scale/Scope**: شاشة واحدة أساسية (`lib/features/store/screens/quick_add_item_screen.dart`) مع تعديل محدود محتمل في `Item` و`StoreRepository.addItem` وملفات اللغة.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **Feature-First Architecture**: PASS. التغييرات في `lib/features/store/` مع إعادة استخدام widgets مشتركة.
- **GetX State and Dependency Patterns**: PASS. سيتم استخدام `GetBuilder<CategoryController>` و`Get.to` الحاليين.
- **Localization Completeness**: PASS مع شرط إضافة مفاتيح `en` و`ar` وأي لغة يتم لمسها.
- **Minimal, Safe Diffs**: PASS. لا حاجة لتعديل generated artifacts أو dependency bumps.
- **Cross-Platform Verification**: PASS مع تحقق يدوي/تحليلي لسلوك الموبايل والكاميرا.

## Project Structure

### Documentation (this feature)

```text
specs/002-quick-add-products/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   └── quick-add-ui-contract.md
└── tasks.md
```

### Source Code (repository root)

```text
lib/
├── common/widgets/
│   └── barcode_scanner_screen.dart
├── features/
│   ├── category/controllers/category_controller.dart
│   └── store/
│       ├── screens/quick_add_item_screen.dart
│       └── domain/
│           ├── models/item_model.dart
│           └── repositories/store_repository.dart
└── helper/route_helper.dart

assets/language/
├── en.json
└── ar.json
```

**Structure Decision**: Flutter/GetX single app. التنفيذ يترك المسارات الحالية كما هي، ويعدل شاشة الإضافة السريعة وموديل/إرسال المنتج فقط إذا احتاج الباركود حقلا جديدا.

## Phase 0: Research

تم توثيق القرارات في [research.md](./research.md).

## Phase 1: Design & Contracts

- Data model: [data-model.md](./data-model.md)
- UI/API contract: [contracts/quick-add-ui-contract.md](./contracts/quick-add-ui-contract.md)
- Validation guide: [quickstart.md](./quickstart.md)

## Post-Design Constitution Check

- **Feature-First Architecture**: PASS. لا يوجد feature folder جديد غير ضروري.
- **GetX State and Dependency Patterns**: PASS. لا توجد dependency جديدة أو state manager جديد.
- **Localization Completeness**: PASS بشرط تنفيذ مفاتيح النصوص الجديدة قبل الدمج.
- **Minimal, Safe Diffs**: PASS. نطاق الملفات محدود.
- **Cross-Platform Verification**: PASS مع قائمة تحقق موبايل للكاميرا والكيباد الداخلي.

## Complexity Tracking

لا توجد مخالفات دستورية تحتاج تبريرا.
