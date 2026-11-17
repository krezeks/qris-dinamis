import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

// Amount editor. UP/DOWN changes the amount by the current step, MENU cycles
// the step (100 / 500 / 1rb / 10rb / 100rb / 1jt; default 500), START or a
// middle tap opens the dynamic QR. HOLDING START opens the active profile's
// static QRIS (amount 0) without disturbing the amount being edited.
// HOLDING a touch on the screen switches to the next QRIS profile (only
// when more than one profile is configured in the app settings).
class AmountView extends WatchUi.View {

    var amount as Number;
    var step as Number;
    var screenH as Number = 280;

    private const STEPS = [100, 500, 1000, 10000, 100000, 1000000] as Array<Number>;
    private const MAX_AMOUNT = 99999999;

    function initialize(startAmount as Number, startStep as Number) {
        View.initialize();
        amount = startAmount;
        step = startStep;
    }

    function onLayout(dc as Graphics.Dc) as Void {
        screenH = dc.getHeight();
    }

    function adjust(dir as Number) as Void {
        amount += dir * step;
        if (amount < 0) {
            amount = 0;
        }
        if (amount > MAX_AMOUNT) {
            amount = MAX_AMOUNT;
        }
        save();
        WatchUi.requestUpdate();
    }

    function cycleStep() as Void {
        var idx = 0;
        for (var i = 0; i < STEPS.size(); i++) {
            if (STEPS[i] == step) {
                idx = i;
            }
        }
        step = STEPS[(idx + 1) % STEPS.size()];
        save();
        WatchUi.requestUpdate();
    }

    function openQr() as Void {
        if (QrisProfiles.count() == 0) {
            return;
        }
        save();
        WatchUi.pushView(new QrView(amount, QrisProfiles.payload()),
            new QrDelegate(), WatchUi.SLIDE_UP);
    }

    // The active profile's static QRIS (no amount). Does not touch the
    // edited amount or storage: BACK returns to the editor as it was.
    function openStaticQr() as Void {
        if (QrisProfiles.count() == 0) {
            return;
        }
        WatchUi.pushView(new QrView(0, QrisProfiles.payload()),
            new QrDelegate(), WatchUi.SLIDE_UP);
    }

    function cycleProfile() as Void {
        if (QrisProfiles.cycle()) {
            WatchUi.requestUpdate();
        }
    }

    private function save() as Void {
        try {
            Application.Storage.setValue("amount", amount);
            Application.Storage.setValue("step3", step);
        } catch (e) {
        }
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        if (QrisProfiles.count() == 0) {
            // No QRIS configured yet (store build before setup).
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(w / 2, h * 22 / 100, Graphics.FONT_SMALL,
                "Belum ada QRIS", Graphics.TEXT_JUSTIFY_CENTER);
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(w / 2, h * 42 / 100, Graphics.FONT_XTINY,
                "1. Buka Garmin Connect", Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(w / 2, h * 52 / 100, Graphics.FONT_XTINY,
                "2. Aplikasi saya > QRIS Dinamis", Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(w / 2, h * 62 / 100, Graphics.FONT_XTINY,
                "3. Pengaturan: tempel teks", Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(w / 2, h * 72 / 100, Graphics.FONT_XTINY,
                "QRIS statis kamu di Profil 1", Graphics.TEXT_JUSTIFY_CENTER);
            return;
        }

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        var pname = QrisProfiles.name();
        if (pname.length() > 26) {
            pname = pname.substring(0, 26) as String;
        }
        dc.drawText(w / 2, h * 9 / 100, Graphics.FONT_XTINY,
            pname, Graphics.TEXT_JUSTIFY_CENTER);

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h * 19 / 100, Graphics.FONT_XTINY,
            "NOMINAL TERIMA (Rp)", Graphics.TEXT_JUSTIFY_CENTER);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        var main = amount == 0 ? "0" : QrisConvert.formatRupiah(amount);
        dc.drawText(w / 2, h * 36 / 100, Graphics.FONT_NUMBER_MEDIUM,
            main, Graphics.TEXT_JUSTIFY_CENTER);

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        var sub = amount == 0 ? "= QRIS statis (tanpa nominal)"
            : "Step: Rp " + QrisConvert.formatRupiah(step);
        dc.drawText(w / 2, h * 58 / 100, Graphics.FONT_XTINY,
            sub, Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(w / 2, h * 67 / 100, Graphics.FONT_XTINY,
            "START: QR dinamis", Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(w / 2, h * 76 / 100, Graphics.FONT_XTINY,
            "TAHAN START: QR statis", Graphics.TEXT_JUSTIFY_CENTER);
        if (QrisProfiles.count() > 1) {
            dc.drawText(w / 2, h * 85 / 100, Graphics.FONT_XTINY,
                "TAHAN LAYAR: ganti profil", Graphics.TEXT_JUSTIFY_CENTER);
        }
    }
}

class AmountDelegate extends WatchUi.BehaviorDelegate {

    private var _view as AmountView;
    private var _enterAt as Number = 0;

    function initialize(view as AmountView) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    function onKeyPressed(evt as WatchUi.KeyEvent) as Boolean {
        var key = evt.getKey();
        if (key == WatchUi.KEY_UP) {
            _view.adjust(1);
            return true;
        }
        if (key == WatchUi.KEY_DOWN) {
            _view.adjust(-1);
            return true;
        }
        if (key == WatchUi.KEY_ENTER) {
            // Tap vs hold is decided on release: a short press opens the
            // dynamic QR, holding (>= 600 ms) opens the static QRIS.
            _enterAt = System.getTimer();
            return true;
        }
        return false;
    }

    function onKeyReleased(evt as WatchUi.KeyEvent) as Boolean {
        if (evt.getKey() == WatchUi.KEY_ENTER && _enterAt != 0) {
            var held = System.getTimer() - _enterAt;
            _enterAt = 0;
            if (held >= 600) {
                _view.openStaticQr();
            } else {
                _view.openQr();
            }
            return true;
        }
        return false;
    }

    function onMenu() as Boolean {
        _view.cycleStep();
        return true;
    }

    function onHold(evt as WatchUi.ClickEvent) as Boolean {
        _view.cycleProfile();
        return true;
    }

    function onTap(evt as WatchUi.ClickEvent) as Boolean {
        var y = evt.getCoordinates()[1] as Number;
        var h = _view.screenH;
        if (y < h * 35 / 100) {
            _view.adjust(1);
        } else if (y > h * 65 / 100) {
            _view.adjust(-1);
        } else {
            _view.openQr();
        }
        return true;
    }
}
