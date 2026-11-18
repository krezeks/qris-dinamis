import Toybox.Attention;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.Timer;
import Toybox.WatchUi;

// Fullscreen QR screen. Encoding a version-9 symbol in a single call
// overruns the Connect IQ watchdog on the real watch (CIQ_LOG 2026-11-16:
// watchdog trip inside the Reed-Solomon remainder), so the payload is
// encoded incrementally: a QrJob advanced by a 50 ms timer, one bounded
// chunk per tick, with a "Membuat QR..." placeholder meanwhile.
// Layout: the whole symbol + quiet zone must fit inside the round
// screen's inscribed square (~196 px), otherwise the corner finder
// patterns sit under the bezel curve and scanners reject the code
// (first on-watch scan test, 2026-11-16). 3 px modules, centered,
// amount text below.
class QrView extends WatchUi.View {

    private var _amount as Number;
    private var _base as String;
    private var _qr as QrCode or Null = null;
    private var _job as QrEncoder.QrJob or Null = null;
    private var _timer as Timer.Timer or Null = null;
    private var _failed as Boolean = false;

    function initialize(amount as Number, base as String) {
        View.initialize();
        _amount = amount;
        _base = base;
    }

    function onShow() as Void {
        _qr = null;
        _failed = false;
        var payload = QrisConvert.makePayload(_base, _amount);
        if (payload.length() == 0) {
            // The converter refused (malformed base or the amount could
            // not be embedded): show the error instead of a wrong QR.
            _failed = true;
            _job = null;
            WatchUi.requestUpdate();
            return;
        }
        _job = new QrEncoder.QrJob(
            payload.toUtf8Array(),
            QrEncoder.ECC_L, 0);
        _timer = new Timer.Timer();
        (_timer as Timer.Timer).start(method(:onTick), 50, true);
        WatchUi.requestUpdate();
    }

    function onHide() as Void {
        if (_timer != null) {
            (_timer as Timer.Timer).stop();
            _timer = null;
        }
        _job = null;
    }

    function onTick() as Void {
        var job = _job;
        if (job == null) {
            return;
        }
        if (job.advance()) {
            if (_timer != null) {
                (_timer as Timer.Timer).stop();
                _timer = null;
            }
            _qr = job.result;
            _failed = job.failed;
            _job = null;
            if (_qr != null && Attention has :backlight) {
                try {
                    Attention.backlight(true);
                } catch (e) {
                }
            }
            WatchUi.requestUpdate();
        }
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_WHITE);
        dc.clear();
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);

        if (_qr == null) {
            dc.drawText(w / 2, h / 2 - 10, Graphics.FONT_SMALL,
                _failed ? "Gagal buat QR" : "Membuat QR...",
                Graphics.TEXT_JUSTIFY_CENTER);
            return;
        }

        var qr = _qr as QrCode;
        var n = qr.size;
        var quiet = 2;
        var total = n + 2 * quiet;
        // Fit the symbol + quiet zone inside the screen's safe area,
        // computed from the actual device: on round dials that is the
        // inscribed square (~70% of the dial) so the corner finders
        // stay clear of the bezel curve — on the 280 px FR165 this
        // yields exactly the 196 px this layout was tuned on.
        // Rectangular screens can use nearly their full width.
        var minDim = w < h ? w : h;
        var avail = (System.getDeviceSettings().screenShape
                == System.SCREEN_SHAPE_RECTANGLE)
            ? (minDim * 94) / 100
            : (minDim * 70) / 100;
        var m = avail / total;
        if (m < 1) {
            m = 1;
        }
        var side = total * m;
        var labelH = (h * 11) / 100;   // label reserve (30 px at 280 px)
        var ox = (w - side) / 2 + quiet * m;
        var oy = (h - side - labelH) / 2 + quiet * m;

        // The clear above already painted the white quiet zone; the screen
        // background is white everywhere, so the effective quiet zone
        // extends past the drawn block wherever the round glass allows.
        for (var y = 0; y < n; y++) {
            for (var x = 0; x < n; x++) {
                if (qr.isDark(x, y)) {
                    dc.fillRectangle(ox + x * m, oy + y * m, m, m);
                }
            }
        }

        var label = _amount == 0 ? "QRIS STATIS"
            : "Rp " + QrisConvert.formatRupiah(_amount);
        dc.drawText(w / 2, oy + side - quiet * m + 8, Graphics.FONT_SMALL,
            label, Graphics.TEXT_JUSTIFY_CENTER);
    }
}

class QrDelegate extends WatchUi.BehaviorDelegate {

    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onKeyPressed(evt as WatchUi.KeyEvent) as Boolean {
        var key = evt.getKey();
        if (key == WatchUi.KEY_ENTER || key == WatchUi.KEY_ESC) {
            WatchUi.popView(WatchUi.SLIDE_DOWN);
            return true;
        }
        return false;
    }

    function onBack() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
    }
}
