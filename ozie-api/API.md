# ozie-api v1 — Auth & Onboarding

Base URL: `https://demo.orderezee.com/ozie-api/`
All requests/responses JSON. Auth header: `Authorization: Bearer <token>`

Response shape (always):
```json
{ "success": true, "message": "...", "data": {}, "errors": null }
```
HTTP: 200/201 ok · 401 login needed/expired · 404 not found · 409 duplicate · 422 validation · 502 send failed · 500 server

## Setup (once)
1. Upload folder `ozie-api/` to web root (next to `login.php`).
2. Copy `config.sample.php` → `config.php`, fill DB, firebase_api_key, whatsapp.
3. Run `sql/api_tokens.sql` in phpMyAdmin.
4. Test: `POST /ozie-api/v1/auth/login`.

## next_screen (Flutter routing)
| value | open |
|---|---|
| `dashboard` | dashboard by `user.user_type` |
| `wait_for_approval` | pending-approval screen (poll `GET auth/me` every 5s) |
| `role_selection` | "Are you a retailer?" screen. If `inquiry_submitted=true` show "contact distributor / already submitted" view |

`user_type`: retailer, distributor, manufacturer, brand, salesman, sales_team_leader, bank (null if none yet)

---
## POST v1/auth/login
```json
{ "login_id": "email or mobile", "password": "xxx", "device_name": "Pixel 7" }
```
200 →
```json
{ "data": {
  "token": "…", "token_type": "Bearer", "expires_at": "2027-01-12 14:00:00",
  "user": { "id": 12, "name": "A", "email": "a@x.com", "mobile": "98…", "user_type": "retailer" },
  "next_screen": "dashboard", "inquiry_submitted": false, "retailer_form_filled": 1
}}
```
401 → `Invalid email/mobile or password.`

## POST v1/auth/google
Flutter: `google_sign_in` → `FirebaseAuth.signInWithCredential` → `await user.getIdToken()`
```json
{ "id_token": "<firebase id token>", "device_name": "Pixel 7" }
```
200 → same as login. 401 → token not verified.
(Android app must be added in Firebase project `orderezee-e2fd2` with SHA-1/SHA-256.)

## GET v1/auth/me  (auth)
Same `data` as login minus token. Use at app start + for approval polling. 401 → go to login.

## POST v1/auth/logout  (auth)
`{}` or `{ "all_devices": true }`

## POST v1/auth/forgot-password
```json
{ "identifier": "email or mobile" }
```
Email → link by email. Mobile → link by WhatsApp. Link opens web reset page (same as website).

## POST v1/auth/reset-password
```json
{ "token": "from link", "password": "newpass" }
```
Min 4 chars. All logged-in devices of that user are logged out.

## POST v1/onboarding/verify-code  (auth)
```json
{ "code": "introduction code" }
```
200 `{verified:true, code}` → open retailer form (send same code with form). 422 invalid.

## POST v1/onboarding/inquiry  (auth)  — "No, I'm not a retailer"
```json
{ "company_name":"", "name":"", "contact_number":"", "industry":"", "location":"State", "user_type":"" }
```
Required: company_name, name, contact_number, location, user_type. 201 ok. 409 if already submitted.

---
## Not in this version (files not shared yet)
signup, OTP send/verify, retailer-form submit.

## Flutter quick setup
```dart
final dio = Dio(BaseOptions(baseUrl: 'https://demo.orderezee.com/ozie-api/'));
dio.interceptors.add(InterceptorsWrapper(
  onRequest: (o, h) async {
    final t = await storage.read(key: 'token');   // flutter_secure_storage
    if (t != null) o.headers['Authorization'] = 'Bearer $t';
    h.next(o);
  },
  onError: (e, h) {
    if (e.response?.statusCode == 401) { /* clear token, go to login */ }
    h.next(e);
  },
));
```
