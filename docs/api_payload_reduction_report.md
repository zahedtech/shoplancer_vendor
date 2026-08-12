# API payload reduction report

## Startup request timing

Measured on the first app entry after removing the duplicate profile request and running home requests in parallel.

| Request | Start | Duration | Response size | Notes |
| --- | ---: | ---: | ---: | --- |
| `GET /api/v1/config` | `+1ms` | `4751ms` | `8593 bytes` | Blocks startup before routing. |
| `POST /api/v1/vendor/update-fcm-token` | `+5891ms` | `1061ms` | `35 bytes` | Small response, but still adds latency. |
| `GET /api/v1/vendor/profile` | `+6987ms` | `1049ms` | `11830 bytes` | Now called once on startup. |
| `GET /api/v1/vendor/wallet/info` | `+8970ms` | `4782ms` | `120 bytes` | Small payload, slow server/network latency. |
| `GET /api/v1/vendor/current-orders` | `+8983ms` | `5591ms` | `22115 bytes` | Largest startup response. |
| `GET /api/v1/vendor/notifications` | `+8994ms` | `4742ms` | `2 bytes` | Empty/small payload, slow server/network latency. |

## Main findings

1. `current-orders` is the largest response in the first screen. It should return a list/card summary only. Full order data should be loaded by `order-details`.
2. `profile` is the second largest response. The first screen uses a limited vendor/store summary, analytics counters, permissions, QR data, and wallet warning fields.
3. `config` is not huge, but it is the first blocking request and takes about 4.7 seconds. It should be cached and split into startup-critical config and deeper feature config.
4. `wallet/info` and `notifications` are tiny but slow. Reducing their payload will not solve most of their delay; they need backend latency checks or lazy loading after the first frame.

## Proposed API changes

### `GET /api/v1/vendor/current-orders`

Current first-screen usage:

- Group orders by `order_status`.
- Show order card with `id`, `created_at`, customer display name, `order_status`, `module_type`, `payment_method`, and `order_amount`.
- Routing to details uses `id`.
- Filtering/grouping uses `order_type`, `item_campaign`, `confirmed`, and sometimes `details_count`/`prescription_order`.

Recommended summary payload:

```json
[
  {
    "id": 123,
    "created_at": "2026-08-09T22:00:00Z",
    "order_status": "pending",
    "module_type": "food",
    "payment_method": "cash_on_delivery",
    "order_amount": 25.5,
    "order_type": "delivery",
    "item_campaign": 0,
    "confirmed": null,
    "details_count": 2,
    "prescription_order": false,
    "customer": {
      "f_name": "Customer",
      "l_name": "Name"
    },
    "delivery_address": {
      "contact_person_name": "Customer Name"
    }
  }
]
```

Move these fields to `GET /api/v1/vendor/order/details/{id}` only:

- Full delivery address details, location coordinates, order notes, unavailable item note, delivery instruction.
- Attachments, proof images, receipt images.
- Coupon/tax/discount breakdowns unless displayed on list.
- Delivery man object.
- Payment breakdown list.
- Store address/phone/logo if already known from profile/config.

Expected impact:

- This is the biggest byte reduction opportunity. The measured response was `22115 bytes`.
- The list screen should become lighter, and details remain complete when the user taps an order.

### `GET /api/v1/vendor/profile`

Current first-screen usage:

- App bar/store area: `stores[0].name`, module id/type, active status.
- Permissions: `roles`.
- QR/store card: `store_url`, `store_qr_code`, store name.
- Analytics: `total_earning`, `order_count`, `todays_earning`, `todays_order_count`, `this_week_earning`, `this_week_order_count`, `this_month_earning`, `this_month_order_count`.
- Warnings: `out_of_stock_count`, `prepaid_balance`, `min_prepaid_balance_limit`, `allowed_credit_remaining`, `is_suspended`, `over_flow_block_warning`.
- Wallet/menu guards: `cash_in_hands`, `show_pay_now_button`, `subscription` basics if needed for modal.

Recommended startup profile payload:

```json
{
  "id": 123,
  "f_name": "Vendor",
  "l_name": "Name",
  "image_full_url": "https://...",
  "roles": ["dashboard", "order", "wallet"],
  "stores": [
    {
      "id": 10,
      "name": "Store Name",
      "active": true,
      "self_delivery_system": 1,
      "module": {
        "id": 3,
        "module_type": "food"
      }
    }
  ],
  "store_url": "https://...",
  "store_qr_code": "https://...",
  "order_count": 100,
  "todays_order_count": 4,
  "this_week_order_count": 20,
  "this_month_order_count": 80,
  "total_earning": 1000,
  "todays_earning": 50,
  "this_week_earning": 300,
  "this_month_earning": 900,
  "out_of_stock_count": 2,
  "prepaid_balance": 100,
  "min_prepaid_balance_limit": 50,
  "allowed_credit_remaining": 40,
  "is_suspended": false,
  "cash_in_hands": 0,
  "show_pay_now_button": false
}
```

Move these fields to profile/settings/wallet-specific endpoints:

- Bank info: `bank_name`, `branch`, `holder_name`, `account_no`.
- Full subscription transaction details unless the startup modal needs them.
- Translations.
- Payment method config details unless the first screen uses them.
- Deep employee/store metadata not shown on home.

Expected impact:

- Measured response was `11830 bytes`.
- Splitting profile into `profile/startup-summary` and `profile/details` should reduce startup payload and parsing time.

### `GET /api/v1/config`

Current startup usage:

- Minimum app versions and maintenance mode.
- Basic currency and decimal settings.
- Feature toggles used immediately by order/home flow.
- `module_config` for current module behavior.
- Payment/config values used by wallet warning and payment screens.

Recommended startup config payload:

```json
{
  "app_minimum_version_android_store": 1.0,
  "app_minimum_version_ios_store": 1.0,
  "maintenance_mode": false,
  "currency_symbol": "د.أ",
  "currency_symbol_direction": "right",
  "digit_after_decimal_point": 2,
  "timeformat": "24",
  "order_confirmation_model": "store",
  "module_config": {
    "module": {
      "show_restaurant_text": true
    }
  },
  "min_amount_to_pay_store": 0,
  "admin_commission": 0,
  "subscription_business_model": 0,
  "commission_business_model": 1
}
```

Move or lazy-load:

- Footer/contact/about values.
- Full language list if not needed on every launch.
- Full active payment method list unless the payment screen is opened.
- Registration toggles unless on auth/registration screens.
- OpenAI and unrelated feature flags unless used on startup.

Expected impact:

- Measured response was `8593 bytes`, but the bigger issue is blocking latency: `4751ms`.
- Add caching with a version/hash. The app can reuse cached config and refresh in the background when unchanged.

### `GET /api/v1/vendor/wallet/info`

Current usage:

- Updates `prepaid_balance`.
- Updates `min_prepaid_balance_limit`.
- Updates `allowed_credit_remaining`.
- Updates `is_suspended`.

Recommended payload:

```json
{
  "prepaid_balance": 100,
  "min_prepaid_balance_limit": 50,
  "allowed_credit_remaining": 40,
  "is_suspended": false
}
```

Expected impact:

- Payload is already small: `120 bytes`.
- Main issue is duration: `4782ms`.
- Check backend query time, network/server queueing, and whether this can be merged into profile startup summary.

### `GET /api/v1/vendor/notifications`

Current first-screen usage:

- Home only needs `hasNotification`.
- Notification page needs list fields: `id`, `title`, `description`, `image_full_url`, `created_at`.

Recommended split:

```json
{
  "unseen_count": 0,
  "has_notification": false
}
```

Use the full list only on notification page:

```json
[
  {
    "id": 1,
    "title": "Title",
    "description": "Description",
    "image_full_url": "https://...",
    "created_at": "2026-08-09T22:00:00Z"
  }
]
```

Expected impact:

- Startup payload was only `2 bytes`, but duration was `4742ms`.
- For startup, replace full list request with unseen-count request or defer it until after the home screen is visible.

## Priority order

1. Add lightweight `current-orders/summary` or add `?fields=summary` to `current-orders`.
2. Split `profile` into startup summary and details.
3. Cache `config` locally and refresh in the background with a version/hash.
4. Replace startup notifications list with unseen count, or defer it.
5. Investigate backend latency for `wallet/info` and `notifications`, because their payload is small but response time is high.

## App-side changes already done

- Duplicate startup `profile` request was removed.
- Home startup requests now run in parallel.
- API logs now show request timing and response size.
- Request/response bodies are hidden by default.
- Sensitive headers such as `Authorization` are redacted.
