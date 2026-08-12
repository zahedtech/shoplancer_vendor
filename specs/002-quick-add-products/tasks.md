# Tasks: Quick Add Products Enhancements

**Input**: Design documents from `/specs/002-quick-add-products/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/

**Tests**: No automated test-first approach was explicitly requested. Include analyzer/manual validation tasks and add widget tests only if the local test harness already supports this screen cleanly.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel because it touches different files or only reads context.
- **[Story]**: User story label from spec.md.
- Every task includes an exact file path.

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Confirm existing code paths and avoid changing generated/unrelated files.

- [ ] T001 Review current quick add staged item, form layout, and submission mapping in `lib/features/store/screens/quick_add_item_screen.dart`
- [ ] T002 [P] Review existing scanner result contract in `lib/common/widgets/barcode_scanner_screen.dart`
- [ ] T003 [P] Review add-item payload fields and subcategory mapping in `lib/features/store/domain/repositories/store_repository.dart`
- [ ] T004 [P] Review `Item` model fields and serialization in `lib/features/store/domain/models/item_model.dart`
- [ ] T005 [P] Review existing localization key placement in `assets/language/en.json` and `assets/language/ar.json`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Add shared data/state shape required by the three user stories.

**Critical**: No user story work should begin until the staged data shape and localization keys are ready.

- [ ] T006 Add barcode, subcategory, and active numeric target state fields/enums in `lib/features/store/screens/quick_add_item_screen.dart`
- [ ] T007 Extend `_StagedQuickItem` with `barcode`, `subCategoryId`, and `subCategoryName` in `lib/features/store/screens/quick_add_item_screen.dart`
- [ ] T008 Add quick-add localization keys for barcode, manual barcode entry, scan action, stock keypad labels, and subcategory states in `assets/language/en.json`
- [ ] T009 Add matching Arabic quick-add localization keys in `assets/language/ar.json`
- [ ] T010 Replace hard-coded new quick-add UI strings introduced by this feature with `.tr` lookups in `lib/features/store/screens/quick_add_item_screen.dart`

**Checkpoint**: Shared state and translations are ready for story implementation.

---

## Phase 3: User Story 1 - Barcode capture in quick add (Priority: P1) MVP

**Goal**: Let users scan or manually enter an optional barcode while adding products quickly.

**Independent Test**: Enter a barcode manually or scan one, add the product to the staged list, save it, and verify the barcode is retained and submitted when backend field support is enabled.

### Implementation for User Story 1

- [ ] T011 [US1] Add a `TextEditingController` for barcode lifecycle management in `lib/features/store/screens/quick_add_item_screen.dart`
- [ ] T012 [US1] Add manual barcode input and scan button UI to the quick entry form in `lib/features/store/screens/quick_add_item_screen.dart`
- [ ] T013 [US1] Implement scan action using `Get.to<String>(() => const BarcodeScannerScreen())` and write returned code into the barcode controller in `lib/features/store/screens/quick_add_item_screen.dart`
- [ ] T014 [US1] Persist trimmed barcode into `_StagedQuickItem` when adding to the staged list in `lib/features/store/screens/quick_add_item_screen.dart`
- [ ] T015 [US1] Display staged barcode context without overflowing the product row in `lib/features/store/screens/quick_add_item_screen.dart`
- [ ] T016 [US1] Add optional `barcode` field to `Item` constructor/model state in `lib/features/store/domain/models/item_model.dart`
- [ ] T017 [US1] Map staged barcode into the submission `Item` in `_buildSubmissionItem` in `lib/features/store/screens/quick_add_item_screen.dart`
- [ ] T018 [US1] Add barcode to add-item multipart fields only when non-empty in `lib/features/store/domain/repositories/store_repository.dart`

**Checkpoint**: Barcode entry works independently and remains optional.

---

## Phase 4: User Story 2 - Price and stock fast numeric entry (Priority: P1)

**Goal**: Put stock beside price and make both use one internal numeric keypad without opening the mobile keyboard.

**Independent Test**: Tap price then stock on mobile; the internal keypad updates only the active field and the system keyboard does not appear.

### Implementation for User Story 2

- [ ] T019 [US2] Replace direct stock `CustomTextFieldWidget` entry with a tappable stock display control in `lib/features/store/screens/quick_add_item_screen.dart`
- [ ] T020 [US2] Refactor `_onNumpadPress` to route digits to the active numeric target in `lib/features/store/screens/quick_add_item_screen.dart`
- [ ] T021 [US2] Refactor `_onNumpadBackspace` to edit the active numeric target in `lib/features/store/screens/quick_add_item_screen.dart`
- [ ] T022 [US2] Update `_buildPriceField` and add a matching stock field builder using shared visual treatment in `lib/features/store/screens/quick_add_item_screen.dart`
- [ ] T023 [US2] Disable or hide decimal input when the active target is stock in `_buildNumpad` in `lib/features/store/screens/quick_add_item_screen.dart`
- [ ] T024 [US2] Validate stock parsing so empty stock defaults to `100` and non-empty invalid stock shows an error in `lib/features/store/screens/quick_add_item_screen.dart`
- [ ] T025 [US2] Ensure adding a staged item clears both numeric controllers and resets the active target sensibly in `lib/features/store/screens/quick_add_item_screen.dart`

**Checkpoint**: Price and stock can be entered quickly without system keyboard dependency.

---

## Phase 5: User Story 3 - Subcategory selection in quick add (Priority: P1)

**Goal**: Load and optionally select subcategories after choosing a main category, then submit `sub_category_id`.

**Independent Test**: Pick a main category with subcategories, select one, add and save the product, and verify `sub_category_id` is included via `item.categoryIds[1]`.

### Implementation for User Story 3

- [ ] T026 [US3] Add selected subcategory id/name state fields in `lib/features/store/screens/quick_add_item_screen.dart`
- [ ] T027 [US3] Clear selected subcategory state when main category changes in `lib/features/store/screens/quick_add_item_screen.dart`
- [ ] T028 [US3] Call `CategoryController.getSubCategoryList(categoryId)` after selecting the main category in `lib/features/store/screens/quick_add_item_screen.dart`
- [ ] T029 [US3] Add optional subcategory dropdown using `categoryController.subCategoryList` in `lib/features/store/screens/quick_add_item_screen.dart`
- [ ] T030 [US3] Persist subcategory id/name into `_StagedQuickItem` in `lib/features/store/screens/quick_add_item_screen.dart`
- [ ] T031 [US3] Add selected subcategory to `item.categoryIds` as the second `CategoryIds` entry in `_buildSubmissionItem` in `lib/features/store/screens/quick_add_item_screen.dart`
- [ ] T032 [US3] Include subcategory in staged row summary when present in `lib/features/store/screens/quick_add_item_screen.dart`

**Checkpoint**: Subcategory selection works independently and remains optional.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Validate the full feature and keep the diff safe.

- [ ] T033 Run `flutter analyze` from repository root and fix new issues in touched files
- [ ] T034 Manually validate barcode scan cancel/success behavior on a mobile device or emulator using `lib/common/widgets/barcode_scanner_screen.dart`
- [ ] T035 Manually validate price and stock keypad behavior on mobile using `lib/features/store/screens/quick_add_item_screen.dart`
- [ ] T036 Manually validate category changes clear stale subcategory state in `lib/features/store/screens/quick_add_item_screen.dart`
- [ ] T037 Verify add-item payload contains `barcode` only when provided and `sub_category_id` only when selected in `lib/features/store/domain/repositories/store_repository.dart`
- [ ] T038 Review touched files for constitution compliance, especially localization and minimal diff requirements in `.specify/memory/constitution.md`
- [ ] T039 Update `specs/002-quick-add-products/quickstart.md` if implementation changes the manual validation steps

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies.
- **Foundational (Phase 2)**: Depends on setup review; blocks all user stories.
- **US1 Barcode (Phase 3)**: Depends on foundational data state and translations.
- **US2 Numeric keypad (Phase 4)**: Depends on foundational active numeric target state.
- **US3 Subcategory (Phase 5)**: Depends on foundational staged item fields.
- **Polish (Phase 6)**: Depends on implemented stories selected for delivery.

### User Story Dependencies

- **US1 Barcode**: Can start after Phase 2 and is the MVP slice.
- **US2 Numeric keypad**: Can start after Phase 2; touches the same quick add file, so coordinate with US1 if parallel.
- **US3 Subcategory**: Can start after Phase 2; touches the same quick add file, so coordinate with US1/US2 if parallel.

### Parallel Opportunities

- T002, T003, T004, and T005 can be done in parallel.
- T008 and T009 can be done in parallel with screen implementation once exact keys are known.
- T016 and T018 can be done alongside T011-T015 if the API field name is confirmed.
- Manual validation tasks T034, T035, and T036 can be split after implementation.

---

## Parallel Example: Setup Review

```text
Task: "Review existing scanner result contract in lib/common/widgets/barcode_scanner_screen.dart"
Task: "Review add-item payload fields and subcategory mapping in lib/features/store/domain/repositories/store_repository.dart"
Task: "Review Item model fields and serialization in lib/features/store/domain/models/item_model.dart"
Task: "Review existing localization key placement in assets/language/en.json and assets/language/ar.json"
```

## Parallel Example: User Story 1

```text
Task: "Add manual barcode input and scan button UI to lib/features/store/screens/quick_add_item_screen.dart"
Task: "Add optional barcode field to Item constructor/model state in lib/features/store/domain/models/item_model.dart"
Task: "Add barcode to add-item multipart fields only when non-empty in lib/features/store/domain/repositories/store_repository.dart"
```

---

## Implementation Strategy

### MVP First

1. Complete Phase 1 and Phase 2.
2. Implement US1 barcode capture and payload support.
3. Validate manual barcode entry and scan return behavior.
4. Stop for backend field confirmation if `barcode` is not accepted by the API.

### Incremental Delivery

1. Deliver US1 barcode capture.
2. Deliver US2 shared internal keypad for price and stock.
3. Deliver US3 subcategory selection and submission.
4. Run Phase 6 validation and analyzer checks.

### Notes

- Avoid editing `.dart_tool/`, generated plugin files, platform project metadata, or unrelated screens.
- Keep the barcode payload field synchronized with backend expectations.
- All production UI strings introduced by implementation should use localization keys.
