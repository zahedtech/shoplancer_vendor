# Contract: Quick Add Products UI/API

## UI Contract

### Barcode Input

- The quick add form displays a barcode field with:
  - manual text entry
  - scan action button using `BarcodeScannerScreen`
- Scan success sets the field text to the returned code.
- Scan cancel or permission failure leaves the current field value unchanged.
- Empty barcode is allowed.

### Numeric Keypad

- Price and stock appear in the same row when width allows.
- Both controls are tap targets styled like non-keyboard fields.
- Tapping either control sets the active numeric target and shows the shared keypad.
- The shared keypad updates only the active target.
- The stock target accepts digits and backspace only.
- The price target accepts digits, a single decimal separator, and backspace.
- No `TextField` focus should be requested for stock or price numeric entry on mobile.

### Category and Subcategory

- Main category dropdown remains required.
- Selecting a main category loads its subcategories.
- Subcategory dropdown is displayed only when subcategories are available or while loading if a loading state is implemented.
- Subcategory is optional.
- Changing the main category clears selected subcategory.

## API/Payload Contract

### Existing Payload

`StoreRepository.addItem` currently sends:

- `category_id` from `item.categoryIds[0].id`
- `sub_category_id` when `item.categoryIds.length > 1`
- `current_stock` and `manage_stock` when module stock is enabled
- `price`, `name`, `description`, discount fields, translations, and module-specific fields

### Required Payload Extension

When a barcode is provided, add exactly one barcode field to the add-item multipart payload.

Candidate field:

```text
barcode=<trimmed barcode>
```

This field name must be verified against the backend contract before implementation is considered complete. If backend uses a different field such as `sku`, `item_code`, or `bar_code`, update this contract and implementation together.

### Compatibility

- If barcode is absent, payload should remain equivalent to current quick-add payload.
- If subcategory is absent, payload should not include `sub_category_id`.
- If subcategory is present, it should reuse the existing `item.categoryIds` mapping so no duplicate repository path is created.
