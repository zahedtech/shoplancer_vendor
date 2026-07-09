# ShopLancer / ShopLanser API Reference

> Reverse-engineered from the official ShopLancer Flutter web build (`main.dart.js`).
> 139 distinct endpoints covering auth, catalog, cart, orders, wallet, address,
> messaging, content pages and configuration.

---

## 1. Base URL & Environment

| Item | Value |
|---|---|
| **Base URL** | `https://shoplanser.com` |
| **API prefix** | `/api/v1` |
| **Storage / images** | `https://shoplanser.com/storage/app/public/...` |
| **Image proxy** | `https://shoplanser.com/image-proxy` |
| **Mobile payment** | `https://shoplanser.com/payment-mobile` |
| **Notifications storage** | `https://shoplanser.com/storage/app/public/notification/` |

Public store details endpoint used by the web client:
```js
fetch(`https://shoplanser.com/api/v1/stores/details/${slug}`)
```

---

## 2. Default request headers

The Dart code builds headers via four patterns:

### 2.1 Minimal (anonymous, language-only)
```http
Content-Type: application/json; charset=UTF-8
X-localization: <ar|en|...>
```

### 2.2 Geo + zone aware (most public endpoints)
```http
Content-Type: application/json; charset=UTF-8
zoneId: "[<zoneId>]"          // JSON-array string e.g. "[1]"
moduleId: <moduleId>          // numeric — current module (grocery / pharmacy / parcel…)
X-localization: <lang>
latitude: <number>
longitude: <number>
```

### 2.3 Authenticated (logged-in user)
```http
Content-Type: application/json; charset=UTF-8
zoneId: "[<zoneId>]"
moduleId: <moduleId>
X-localization: <lang>
latitude: <number>
longitude: <number>
Authorization: Bearer <token>
```

### 2.4 Guest (no token)
A guest token is obtained via `POST /auth/guest/request` and sent as
`guest_id` header (or `Authorization: Bearer <guest_token>` depending on the
call site).

> Method override: some PUT calls are sent as POST with body
> `_method: "PUT"` (e.g. `/customer/cm-firebase-token`,
> `/auth/firebase-reset-password`). This is a Laravel convention.

---

## 3. Endpoint catalogue

Method legend: `GET` = read, `POST` = create / action, `PUT` = update,
`DELETE` = remove. Endpoints marked `Auth` require the `Authorization` header.

### 3.1 Authentication (`/auth/*`)

| Method | Endpoint | Notes |
|---|---|---|
| POST | `/auth/login` | Body: `{ email_or_phone, password }`. Returns token. |
| POST | `/auth/sign-up` | Customer registration (multipart with name, phone, email, password, refer_code). |
| POST | `/auth/forgot-password` | Body: `{ phone }` — sends OTP. |
| POST | `/auth/verify-phone` | Body: `{ phone, otp }`. |
| POST | `/auth/reset-password` | Body: `{ phone, otp, password, confirm_password }`. |
| PUT  | `/auth/update-info` | (sent as POST with `_method=PUT`). |
| POST | `/auth/firebase-verify-token` | Firebase phone-auth bridge. |
| POST | `/auth/firebase-reset-password` | Firebase reset flow. |
| PUT  | `/auth/verify-token` | Re-verify session token. |
| POST | `/auth/guest/request` | Anonymous guest registration → `guest_id`. |
| POST | `/auth/vendor/register` | Vendor onboarding (multipart with shop logo/cover, owner info, store data). |
| POST | `/auth/delivery-man/store` | Delivery-man self-registration (multipart). |

### 3.2 Customer profile & account (`/customer/*`)

| Method | Endpoint | Notes |
|---|---|---|
| GET    | `/customer/info` | Logged-in user profile. |
| POST   | `/customer/update-profile` | Multipart with `f_name, l_name, phone, image`. |
| PUT    | `/customer/update-zone` | Body: `{ zone_id, latitude, longitude }`. |
| POST   | `/customer/update-interest` | Body: `{ interest: [ids] }`. |
| POST   | `/customer/cm-firebase-token` | Body: `{ _method:"put", cm_firebase_token }`. |
| GET    | `/customer/notifications` | List push/system notifications. |
| GET    | `/customer/automated-message` | Quick-reply templates. |
| GET    | `/customer/suggested-items` | Personalised recommendations. |
| GET    | `/customer/visit-again` | "Order again" list. |
| DELETE | `/customer/remove-account` | Account self-deletion. |

### 3.3 Addresses (`/customer/address/*`)

| Method | Endpoint |
|---|---|
| GET    | `/customer/address/list` |
| POST   | `/customer/address/add` |
| PUT    | `/customer/address/update/{address_id}` |
| DELETE | `/customer/address/delete?address_id={id}` |

Address body (add/update):
```json
{
  "contact_person_name": "...",
  "contact_person_number": "...",
  "address_type": "home|work|other",
  "address": "free text",
  "latitude": 31.95, "longitude": 35.9,
  "zone_id": 1,
  "house": "...", "floor": "...", "road": "..."
}
```

### 3.4 Catalog — categories, brands, items

| Method | Endpoint | Notes |
|---|---|---|
| GET | `/categories` | Top-level. |
| GET | `/categories/childes/{id}` | Sub-categories. |
| GET | `/categories/items/{id}?limit=&offset=&type=` | Items by category. |
| GET | `/categories/stores/{id}?limit=&offset=&type=` | Stores by category. |
| GET | `/categories/featured/items?limit=30&offset=1` | Featured items. |
| GET | `/brand` | All brands. |
| GET | `/brand/items/{brandId}?offset={n}&limit=12` | Items in brand. |
| GET | `/items/basic?offset=1&limit=50` | Lightweight feed. |
| GET | `/items/details/{id}` | Single item full details. |
| GET | `/items/popular?type={all\|veg\|non_veg}` | Popular items. |
| GET | `/items/latest?store_id={id}` | Latest items (optionally per store). |
| GET | `/items/discounted?type=` | Discounted feed. |
| GET | `/items/most-reviewed?type=` | Top reviewed. |
| GET | `/items/recommended?store_id=&offset=&limit=` | Recommendations. |
| GET | `/items/recommended?filter=` | Recommendations by filter. |
| GET | `/items/suggested?recommended=1&store_id=` | Suggested for store. |
| GET | `/items/search?name=&store_id=&category_id=&offset=&limit=` | Item search. |
| GET | `/items/item-or-store-search?name=&category_id=&type=&offset=&limit=` | Combined search. |
| POST | `/items/reviews/submit` | Multipart `{ item_id, order_id, comment, rating, attachment[] }`. |

### 3.5 Stores

| Method | Endpoint |
|---|---|
| GET | `/stores/details/{slug-or-id}` |
| GET | `/stores/get-stores/all?featured=1&offset=1&limit=50` |
| GET | `/stores/latest?type=` |
| GET | `/stores/popular?type=` |
| GET | `/stores/recommended` |
| GET | `/stores/top-offer-near-me?sort_by=` |
| GET | `/stores/reviews?store_id=&offset=&limit=` |

### 3.6 Cart (`/customer/cart/*`)

| Method | Endpoint | Notes |
|---|---|---|
| GET    | `/customer/cart/list?guest_id={id}` | Returns cart with items. |
| POST   | `/customer/cart/add?guest_id={id}` | Body: cart item payload. |
| PUT    | `/customer/cart/update?guest_id={id}` | Body: `{ cart_id, quantity, price, ...add-ons }`. |
| DELETE | `/customer/cart/remove?guest_id={id}` | Empty entire cart. |
| DELETE | `/customer/cart/remove-item?cart_id={id}&guest_id={gid}` | Single line item. |

### 3.7 Wish list

| Method | Endpoint |
|---|---|
| GET    | `/customer/wish-list?offset=&limit=` |
| POST   | `/customer/wish-list/add?item_id=` (or `?store_id=`) |
| DELETE | `/customer/wish-list/remove?item_id=` (or `?store_id=`) |

### 3.8 Orders (`/customer/order/*`)

| Method | Endpoint | Notes |
|---|---|---|
| GET    | `/customer/order/list?offset=&limit=` | Order history. |
| GET    | `/customer/order/running-orders?offset=` | Active orders. |
| GET    | `/customer/order/details?order_id={id}` | Order detail. |
| GET    | `/customer/order/track?order_id={id}` | Realtime tracking. |
| POST   | `/customer/order/place` | Place new order (large payload — see §4). |
| POST   | `/customer/order/prescription/place` | Pharmacy / prescription order. |
| PUT    | `/customer/order/cancel` | Body: `{ order_id, _method:"PUT", reason }`. |
| GET    | `/customer/order/cancellation-reasons?offset=1&limit=30&type=customer` | |
| GET    | `/customer/order/refund-reasons` | |
| POST   | `/customer/order/refund-request` | Multipart with images. |
| POST   | `/customer/order/parcel-return` | Body: `{ order_id, ... }`. |
| GET    | `/customer/order/parcel-instructions?limit=10&offset=` | |
| PUT    | `/customer/order/get-Tax` | Body: `{ order_amount, store_id }`. |
| PUT    | `/customer/order/get-surge-price` | Body: `{ order_amount, lat, lng }`. |
| GET    | `/customer/order/payment-method` | List enabled methods. |
| POST   | `/customer/order/wallet-payment` | Body: `{ order_id }`. |
| POST   | `/customer/order/offline-payment` | Body: offline-payment fields. |
| POST   | `/customer/order/offline-payment-update` | Update receipt. |
| POST   | `/customer/order/payment-failed` | Body: `{ order_id }`. |

### 3.9 Wallet & loyalty

| Method | Endpoint |
|---|---|
| POST | `/customer/wallet/add-fund` |
| GET  | `/customer/wallet/transactions?offset=&limit=` |
| GET  | `/customer/wallet/bonuses` |
| GET  | `/customer/loyalty-point/transactions?offset=&limit=` |
| PUT  | `/customer/loyalty-point/point-transfer` (body: `{ point }`) |
| GET  | `/cashback/list` |
| GET  | `/cashback/getCashback?amount={n}` |
| GET  | `/coupon/list` |

### 3.10 Messaging / chat

| Method | Endpoint |
|---|---|
| GET  | `/customer/message/list?limit=10&offset=` |
| GET  | `/customer/message/details?conversation_id=&offset=&limit=` |
| GET  | `/customer/message/search-list?name=` |
| POST | `/customer/message/send` (multipart: `{ message, conversation_id, image[] }`) |

### 3.11 Banners, campaigns, flash sales, advertisements

| Method | Endpoint |
|---|---|
| GET | `/banners` |
| GET | `/banners?featured=1` |
| GET | `/other-banners` |
| GET | `/other-banners/video-content` |
| GET | `/other-banners/why-choose` |
| GET | `/advertisement/list` |
| GET | `/campaigns/basic` |
| GET | `/campaigns/item` |
| GET | `/campaigns/basic-campaign-details?basic_campaign_id={id}` |
| GET | `/flash-sales` |
| GET | `/flash-sales/items?flash_sale_id={id}` |
| GET | `/most-tips` |
| GET | `/flutter-landing-page` |
| GET | `/common-condition` |
| GET | `/common-condition/items/{id}` |

### 3.12 Configuration & geocoding

| Method | Endpoint | Notes |
|---|---|---|
| GET | `/config` | App-wide config (currency, payment methods, modules…). |
| GET | `/config/get-zone-id?lat=&lng=` | Resolve zone for coords. |
| GET | `/config/distance-api?origin_lat=&origin_lng=&destination_lat=&destination_lng=` | Google distance proxy. |
| GET | `/config/geocode-api?lat=&lng=` | Reverse geocode proxy. |
| GET | `/config/place-api-autocomplete?search_text=` | Places autocomplete proxy. |
| GET | `/config/place-api-details?placeid=` | Place details proxy. |
| GET | `/zone/list` | All zones. |
| GET | `/zone/check?lat=&lng=&zone_id=` | Validate coverage. |
| GET | `/module` | List modules. |
| GET | `/module?zone_id=` | Modules in zone. |

### 3.13 Vendor / delivery-man

| Method | Endpoint |
|---|---|
| PUT  | `/vendor/business_plan` |
| GET  | `/vendor/package-view?module_id={id}` |
| POST | `/delivery-man/reviews/submit` (multipart: rating, comment, images, dm_id, order_id) |

### 3.14 Parcel module

| Method | Endpoint |
|---|---|
| GET | `/parcel-category` |
| GET | `/get-vehicles` |
| GET | `/vehicle/extra_charge?distance=` |
| GET | `/get-parcel-cancellation-reasons?limit=25&offset=1&user_type=customer&cancellation_type=` |
| GET | `/cancelation` |

### 3.15 Static content pages

| Method | Endpoint |
|---|---|
| GET | `/about-us` |
| GET | `/privacy-policy` |
| GET | `/terms-and-conditions` |
| GET | `/refund-policy` |
| GET | `/shipping-policy` |
| GET | `/offline_payment_method_list` |

---

## 4. Common payloads

### 4.1 Login (`POST /auth/login`)
```json
{
  "email_or_phone": "+9627XXXXXXXX",
  "password": "secret",
  "type": "phone"
}
```
**Response (typical):**
```json
{
  "token": "1|abc...",
  "is_phone_verified": 1,
  "is_email_verified": 1,
  "temporary_token": null
}
```

### 4.2 Place order (`POST /customer/order/place`)
Common fields observed:
```
order_amount, payment_method, order_type (delivery|take_away),
store_id, distance, address, latitude, longitude,
address_type, road, house, floor, contact_person_name,
contact_person_number, schedule_at, coupon_code,
order_note, partial_payment, guest_id, dm_tips,
cutlery, is_buy_now, delivery_instruction
cart[]: [{ item_id, price, quantity, variation, add_ons }]
```

### 4.3 Add to cart (`POST /customer/cart/add`)
```json
{
  "item_id": 123,
  "model": "Item",
  "price": 5.5,
  "quantity": 2,
  "variation": [],
  "add_ons": [],
  "add_on_qtys": [],
  "store_id": 8,
  "module_id": 1
}
```

### 4.4 Standard list response shape
Most paginated endpoints return:
```json
{
  "total_size": 137,
  "limit": "50",
  "offset": "1",
  "products": [ /* or items / stores / data */ ]
}
```

### 4.5 Error shape
```json
{
  "errors": [
    { "code": "auth-001", "message": "Invalid credentials" }
  ]
}
```

---

## 5. Front-end constants worth reusing

```ts
export const SHOPLANSER = {
  baseUrl: "https://shoplanser.com",
  apiPrefix: "/api/v1",
  storage: "https://shoplanser.com/storage/app/public",
  imageProxy: "https://shoplanser.com/image-proxy",
  defaultHeaders: {
    "Content-Type": "application/json; charset=UTF-8",
    Accept: "application/json",
  },
} as const;
```

The Flutter client also embeds these third-party keys in the page (public,
client-side):
- Google Maps JS API key — used for map widgets
- Firebase web `apiKey` — used for Firebase Auth phone OTP

Both are public/restricted by referer; do not treat as secrets.

---

## 6. Notes on method discovery

The Dart-compiled bundle minifies HTTP verbs to short method names. Verified
mapping inside `main.dart.js`:

| Minified | HTTP verb | Sample call |
|---|---|---|
| `bC` | GET | `/banners`, `/zone/list` |
| `wF` | GET (with body/headers) | `/categories`, `/module?zone_id=` |
| `nD` | POST | `/auth/login`, `/customer/address/add` |
| `aEN`, `aeF`, `bLq` | POST (multipart) | `/customer/cart/add`, `/auth/vendor/register` |
| `jY` | PUT | `/customer/order/cancel`, `/customer/cart/update` |
| `a_z` | PUT | `/customer/address/update/{id}` |
| `azQ` | DELETE | `/customer/cart/remove`, `/customer/cart/remove-item` |

When uncertain, the request body usually contains a `_method` override which
states the true verb (Laravel convention).
