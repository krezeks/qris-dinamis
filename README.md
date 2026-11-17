# QRIS Dinamis

A Connect IQ watch app for Garmin Forerunner 165 that turns a static QRIS code into a **dynamic** one — right on your wrist.

Paste your static QRIS text once (in this app's settings in Garmin Connect), then set any amount on the watch and show a QR code with that amount already filled in. The payer just scans and pays, no typing.

**On the Connect IQ Store:** [QRIS Dinamis Watch](https://apps.garmin.com/apps/9b152157-4ccb-4d9d-be47-b92038c8329b) (free)

## Features

- Up to **3 QRIS profiles** (shop, stall, personal, ...) — touch-and-hold the screen to switch
- Amount steps of 100 / 500 / 1,000 / 10,000 / 100,000 / 1,000,000 (hold UP to change step, default 500)
- START shows the dynamic QR with amount; hold START for the original static QR
- Merchant name from the active profile is shown above the amount editor
- Pasted payloads are validated on the watch (EMVCo structure + CRC16) — incomplete or corrupted pastes are rejected automatically
- **Fully offline**: no permissions, no network, no data collection. Your QRIS text never leaves your watch and phone settings

## Setup

1. Get your static QRIS as text: scan your printed QRIS sticker with any QR scanner app that can show the raw text, and copy it (it starts with `000201...`).
2. In Garmin Connect: My Apps → QRIS Dinamis → Settings — paste the text into Profile 1 (Profiles 2 and 3 are optional).
3. Open the app on your watch, set the amount with UP/DOWN, press START, and let the payer scan.

## Building

Requires the Connect IQ SDK (developed against 8.4.1) and the fr165 device package.

```sh
# Sideload build (.prg)
monkeyc -d fr165 -o bin/QrisDinamis.prg -f monkey.jungle -y <developer_key.der> -w

# Store package (.iq)
monkeyc -e -o bin/QrisDinamis.iq -f monkey.jungle -y <developer_key.der> -w
```

The app generates QR codes on-device with a chunked encoder (`QrEncoder.mc`) that works within the Connect IQ watchdog limits, and converts static → dynamic payloads by rewriting the EMVCo TLV fields (point-of-initiation `01` → `12`, inserting amount tag `54`, recomputing CRC16) in `QrisConvert.mc`.

## Notes

- This app only *displays* a receiving code. It does not process payments and is not affiliated with Bank Indonesia, ASPI, or any e-wallet or bank.
- This repository is the store variant: it ships with **no QRIS payload** — every user supplies their own.

## Support

QRIS Dinamis is free. If it helps your business, you can support development here: https://trakteer.id/tasri_taz
