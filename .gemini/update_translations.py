import json
import os

def update_json(file_path, new_keys):
    with open(file_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    data.update(new_keys)
    with open(file_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

en_keys = {
    "selected": "Selected",
    "select_all": "Select All",
    "delete_selected_items": "Delete Selected Items",
    "are_you_sure_to_delete_selected_items": "Are you sure you want to delete the selected items?",
    "update_status": "Update Status",
    "choose_status_for_selected_items": "Choose status for selected items",
    "active": "Active",
    "inactive": "Inactive",
    "update_price": "Update Price",
    "update_stock": "Update Stock",
    "bulk_update": "Bulk Update",
    "enter_new_price": "Enter new price",
    "enter_new_stock": "Enter new stock",
    "selected_items_updated_successfully": "Selected items updated successfully",
    "cancel": "Cancel",
    "update": "Update"
}

ar_keys = {
    "update_price": "تحديث السعر",
    "update_stock": "تحديث المخزون",
    "bulk_update": "تحديث جماعي",
    "enter_new_price": "أدخل السعر الجديد",
    "enter_new_stock": "أدخل المخزون الجديد",
    "selected_items_updated_successfully": "تم تحديث العناصر المختارة بنجاح",
    "cancel": "إلغاء",
    "update": "تحديث"
}

update_json('assets/language/en.json', en_keys)
update_json('assets/language/ar.json', ar_keys)
print("Updated successfully")
