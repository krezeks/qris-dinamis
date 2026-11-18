# QRIS Dinamis for Garmin

A Connect IQ watch app that rewrites a static QRIS payload on the watch into the **dynamic format** — with the amount embedded — right on your wrist.

Paste your static QRIS text once (in this app's settings in Garmin Connect), then set any amount on the watch and show a QR code with that amount already filled in. The payer just scans, no typing.

**On the Connect IQ Store:** [QRIS Dinamis Watch](https://apps.garmin.com/apps/9b152157-4ccb-4d9d-be47-b92038c8329b) (free)

## Supported devices

19 Garmin models — the QR layout adapts automatically to each watch's screen size and shape:

- **Forerunner** 165, 255, 255 Music, 255S, 255S Music, 265, 265S, 955, 965
- **Fenix 7** series (7, 7S, 7X) including the **Pro** series
- **Epix** (Gen 2)
- **Venu** 3, 3S
- **Vivoactive** 5

## Features

- Up to **3 QRIS profiles** (shop, stall, personal, ...) — touch-and-hold the screen to switch
- Amount steps of 100 / 500 / 1,000 / 10,000 / 100,000 / 1,000,000 (hold UP to change step, default 500)
- START shows the dynamic QR with amount; hold START for the original static QR
- Merchant name from the active profile is shown above the amount editor
- Pasted payloads are strictly validated on the watch: full TLV structure walked end to end, mandatory QRIS fields (merchant account, MCC, currency IDR, country ID, name, city), no duplicate tags, nested template TLV (tags 26–51, 62, 64, 80–99) parsed with the same rules, and CRC16 checked last — incomplete or corrupted pastes are rejected automatically. Profiles must be static (no embedded amount). Static payloads up to 259 characters are supported (the on-watch QR encoder's ceiling, with room reserved for the amount tag)
- **Fully offline**: no permissions, no network, no data collection. Your QRIS text never leaves your watch and phone settings

## Setup

1. Get your static QRIS as text with the companion **QRIS to Text** tool below (or any QR scanner app that can show the raw text) and copy it (it starts with `000201...`).
2. In Garmin Connect: My Apps → QRIS Dinamis → Settings — paste the text into Profile 1 (Profiles 2 and 3 are optional).
3. Open the app on your watch, set the amount with UP/DOWN, press START, and let the payer scan.

## QRIS to Text (companion tool)

Need your QRIS as text for step 1? Use **[QRIS to Text](https://krezeks.github.io/qris-dinamis-for-garmin/qris-to-text.html)**: open the page, pick a screenshot or photo of your QRIS, and copy the payload text it reads.

- Runs **100% in your browser** (jsQR) — your QRIS image is never uploaded anywhere
- Parses the EMVCo fields and verifies the payload CRC, so a mis-read code is flagged before you paste it
- Single self-contained file: [`qris-to-text.html`](qris-to-text.html) — you can also download it and use it offline

## Building

Requires the Connect IQ SDK (developed against 8.4.1) and the device packages for the supported models (via the Connect IQ SDK Manager).

```sh
# Sideload build (.prg, per device)
monkeyc -d fr165 -o bin/QrisDinamis.prg -f monkey.jungle -y <developer_key.der> -w

# Store package (.iq, all supported devices)
monkeyc -e -o bin/QrisDinamis.iq -f monkey.jungle -y <developer_key.der> -w
```

The app generates QR codes on-device with a chunked encoder (`QrEncoder.mc`) that works within the Connect IQ watchdog limits, and converts static → dynamic payloads by rewriting the EMVCo TLV fields (point-of-initiation `01` → `12`, inserting amount tag `54`, recomputing CRC16) in `QrisConvert.mc`. The QR safe area is computed per device from its screen shape and size in `QrView.mc`.

## Notes

- This app only *displays* a receiving code. It does not process payments and is not affiliated with Bank Indonesia, ASPI, or any e-wallet or bank.
- The dynamic-format payload is built locally on the watch from your static code (point-of-initiation set to `12`, amount tag `54` inserted, CRC16 recomputed, output verified before display). Acceptance of the resulting code is up to the payer's bank/e-wallet app — if a scan is ever refused, your original static code works as before.
- This repository is the store variant: it ships with **no QRIS payload** — every user supplies their own.

## Support

QRIS Dinamis is free. If it helps your business, you can support development here: https://trakteer.id/tasri_taz
