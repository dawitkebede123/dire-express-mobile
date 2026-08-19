# Dire Express (Flutter)

Native Android/iOS app with full parity of the Dire Express web product: broker, driver, and customer roles.

## Prerequisites

- Flutter 3.38+
- The Next.js API running from `web/dire-express` (`npm run dev`)
- Same Postgres database as the web app

## Configure

Pass the API base URL at run time. Mapbox and Pusher keys are loaded from `GET /api/config` after login (Bearer token required) and cached on the device.

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000
```

- Android emulator: `http://10.0.2.2:3000`
- iOS simulator: `http://localhost:3000`
- Physical device (phone and PC on same Wi‑Fi): `http://YOUR_LAN_IP:3000`  
  Example: `flutter run --dart-define=API_BASE_URL=http://192.168.100.163:3000`  
  The login screen shows the active API URL in debug builds. Ensure the Next.js API listens on all interfaces (`npx next dev -H 0.0.0.0 -p 3000`).

## Demo accounts

Password for all: `password123`

- `broker@direexpress.com`
- `driver@direexpress.com`
- `customer@direexpress.com`

## Backend

The Flutter client uses Bearer JWTs. The Next.js app exposes:

- `POST /api/auth/mobile/login`
- `GET /api/auth/mobile/me`
- `GET /api/config` (Mapbox token, Pusher key + cluster)
- `POST /api/uploads`
- Existing load/driver/customer/notification routes, now accepting `Authorization: Bearer`

## Features

- Login / register by role (EN + አማርኛ)
- Broker dashboard, loads wizard, assign driver, directories
- Driver board, GPS streaming, POD photo + signature
- Customer live Mapbox tracking and history
- Pusher realtime updates and notifications inbox
