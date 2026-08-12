# Quickstart: Validate Quick Add Products Enhancements

## Prerequisites

- Flutter dependencies installed for this repository.
- A vendor account with access to the store product management area.
- At least one main category, and preferably one main category with subcategories.
- Camera permission available on a mobile device or simulator that supports camera input.

## Static Checks

```bash
flutter analyze
```

Expected outcome: no new analyzer errors from the touched files.

## Manual Scenario 1: Manual Barcode

1. Open the vendor app.
2. Navigate to `إضافة منتجات سريعة`.
3. Enter product name.
4. Type a barcode manually in the barcode field.
5. Select a main category.
6. Enter price using the internal keypad.
7. Enter stock using the same internal keypad.
8. Add to list, then save all.

Expected outcome: product is submitted successfully; barcode is included in the add-item payload if backend field is enabled.

## Manual Scenario 2: Barcode Scan

1. Open `إضافة منتجات سريعة`.
2. Tap the barcode scan action.
3. Scan a QR/barcode.
4. Confirm returned code appears in the barcode field.
5. Complete required fields and save.

Expected outcome: scan returns to quick add without losing form state, and the scanned value is staged with the product.

## Manual Scenario 3: Stock Keypad Does Not Open Mobile Keyboard

1. On a mobile device, tap the price control.
2. Enter a price using the internal keypad.
3. Tap the stock control.
4. Enter stock using the same keypad.

Expected outcome: system keyboard does not appear for either price or stock; only the active field changes.

## Manual Scenario 4: Subcategory

1. Choose a main category that has subcategories.
2. Wait for the subcategory list.
3. Select a subcategory.
4. Add product to staged list and save all.

Expected outcome: the submitted `Item` contains two `categoryIds`, causing repository payload to include `sub_category_id`.

## Regression Scenario

1. Add a product with only name, category, and price.
2. Leave barcode, subcategory, and stock empty.
3. Add to list and save.

Expected outcome: behavior matches current quick add flow, with stock defaulting to `100`.
