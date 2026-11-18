# QRIS Dinamis — Connect IQ Store listing draft
Prepared 2026-11-16. Package: QrisDinamis.iq (app ID dcf0281c-73c8-455e-a72c-3d1e7dcce990, FR165 only for v1).
Trakteer link (received from taz 2026-11-17): https://trakteer.id/tasri_taz — already inserted in both descriptions below. Store icon: store-icon-500.png in this folder.

## App name
QRIS Dinamis

## Short description (EN)
Show your QRIS payment code on your Garmin — with the amount already filled in.

## Full description (EN)
QRIS Dinamis rewrites your static QRIS payload on the watch into the dynamic format — with the amount embedded — right on your wrist.

Paste your static QRIS text once (in this app's settings in Garmin Connect), then set any amount on the watch and show a QR code with that amount already filled in — the payer just scans, no typing.

Features:
- Up to 3 QRIS profiles (shop, stall, personal...) — hold the screen to switch
- Amount steps of 100 / 500 / 1,000 / 10,000 / 100,000 / 1,000,000 (hold UP to change step)
- START shows the dynamic QR with amount; hold START for your original static QR
- Merchant name shown on screen, so you always know which code is active
- Works fully offline; your QRIS text never leaves your watch and phone settings

Setup:
1. Get your static QRIS as text: scan your printed QRIS sticker with any QR scanner app that can show the raw text, and copy it (it starts with "000201...").
2. In Garmin Connect: My Apps > QRIS Dinamis > Settings — paste the text into Profile 1 (Profiles 2 and 3 are optional).
3. Open the app on your watch, set the amount with UP/DOWN, press START, and let the payer scan.

Notes:
- This app only *displays* a receiving code. It does not process payments and is not affiliated with Bank Indonesia, ASPI, or any e-wallet/bank.
- A pasted code is verified on the watch (full payload structure + checksum); an incomplete or corrupted paste is rejected automatically.
- The dynamic-format payload is built locally on the watch from your static code (point-of-initiation set to dynamic, amount tag added, checksum recomputed). Acceptance of the resulting code is up to the payer's bank/e-wallet app — if a scan is ever refused, your original static code works as before.

QRIS Dinamis is free. If it helps your business, you can support development here: https://trakteer.id/tasri_taz

## Deskripsi (ID)
QRIS Dinamis menulis ulang payload QRIS statis kamu di jam menjadi format dinamis — dengan nominal tertanam — langsung di pergelangan tangan.

Tempel teks QRIS statis kamu sekali (di pengaturan aplikasi ini di Garmin Connect), lalu atur nominal berapa pun di jam dan tampilkan kode QR dengan nominal yang sudah terisi — pembayar tinggal scan, tanpa mengetik nominal.

Fitur:
- Sampai 3 profil QRIS (toko, lapak, pribadi...) — tahan layar untuk berganti
- Kelipatan nominal 100 / 500 / 1.000 / 10.000 / 100.000 / 1.000.000 (tahan UP untuk mengganti kelipatan)
- START menampilkan QR dinamis bernominal; tahan START untuk QRIS statis asli kamu
- Nama merchant tampil di layar, jadi kamu selalu tahu kode siapa yang aktif
- Berfungsi penuh offline; teks QRIS kamu tidak pernah keluar dari jam dan pengaturan HP kamu

Cara pasang:
1. Ambil teks QRIS statis kamu: scan stiker QRIS cetakmu dengan aplikasi pemindai QR apa pun yang bisa menampilkan teks mentahnya, lalu salin (teks diawali "000201...").
2. Di Garmin Connect: Aplikasi Saya > QRIS Dinamis > Pengaturan — tempel teksnya di Profil 1 (Profil 2 dan 3 opsional).
3. Buka aplikasi di jam, atur nominal dengan UP/DOWN, tekan START, dan minta pembayar memindai.

Catatan:
- Aplikasi ini hanya *menampilkan* kode penerimaan. Aplikasi ini tidak memproses pembayaran dan tidak berafiliasi dengan Bank Indonesia, ASPI, atau e-wallet/bank mana pun.
- Teks yang ditempel diverifikasi di jam (struktur payload lengkap + checksum); tempelan yang tidak lengkap atau rusak otomatis ditolak.
- Payload format dinamis dibuat lokal di jam dari kode statis kamu (penanda transaksi diset dinamis, tag nominal ditambahkan, checksum dihitung ulang). Diterima atau tidaknya kode hasil olahan ini bergantung pada aplikasi bank/e-wallet pembayar — kalau suatu saat scan ditolak, kode statis asli kamu tetap berfungsi seperti biasa.

QRIS Dinamis gratis. Kalau aplikasi ini membantu usahamu, kamu bisa mendukung pengembangannya di sini: https://trakteer.id/tasri_taz

## Upload checklist (portal: apps.garmin.com developer upload)
- [ ] Garmin developer account (taz's Garmin account)
- [ ] Upload QrisDinamis.iq
- [ ] Name + descriptions above (EN primary; ID welcome)
- [ ] Store icon 500x500 (to prepare)
- [ ] Screenshots from FR165 (optional but recommended: editor, QR screen, settings)
- [ ] Category: Finance / Utilities (pick what the form offers)
- [ ] Submit → Garmin review (~72 h)
