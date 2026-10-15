# taskflow_mobile

Aplikasi mobile Flutter (Riverpod + go_router) untuk backend TaskFlow
(NestJS microservices).

## Development

```sh
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:3000/api
```

Tanpa `--dart-define`, mode debug otomatis memakai `10.0.2.2` (emulator
Android) atau `localhost` (lainnya). Lihat `lib/core/config/app_config.dart`.

## Build produksi (release)

Build release wajib menyertakan base URL API. Kalau tidak, app langsung gagal
start dengan pesan error yang jelas, bukan diam-diam menembak `localhost` di
device pengguna.

```powershell
./scripts/build_release.ps1 -ApiBaseUrl https://api.taskflow-kamu.com/api
# atau untuk Play Store (.aab):
./scripts/build_release.ps1 -ApiBaseUrl https://api.taskflow-kamu.com/api -Target appbundle
```

### Signing Android (sekali setup)

Release build butuh `android/key.properties` (gitignored) menunjuk ke
keystore upload. Skrip di atas menolak jalan kalau file ini belum ada, karena
tanpa file itu build jatuh ke debug-signing yang tidak valid untuk Play Store.

Kalau `android/key.properties` + `android/upload-keystore.jks` belum ada
(mis. clone ulang repo di mesin baru), buat baru dengan:

```sh
keytool -genkeypair -v -keystore android/upload-keystore.jks \
  -alias taskflow-upload -keyalg RSA -keysize 2048 -validity 10000
```

lalu isi `android/key.properties`:

```properties
storePassword=<password saat generate>
keyPassword=<password saat generate>
keyAlias=taskflow-upload
storeFile=upload-keystore.jks
```

Penting: backup `upload-keystore.jks` + `key.properties` di tempat aman
(password manager / secure drive) di luar repo. Kalau hilang, kamu tidak
bisa lagi mem-publish update untuk aplikasi yang sama di Play Store.
