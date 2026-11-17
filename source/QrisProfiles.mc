import Toybox.Application;
import Toybox.Lang;

// The QRIS profiles the watch can show. Payloads come from the app
// settings in Garmin Connect (properties qris1..qris3: one pasted
// static QRIS string per slot). Slot 1 falls back to the built-in
// payload when its setting is empty or fails validation; slots 2 and
// 3 simply stay inactive. A pasted payload that fails the CRC check
// never reaches the QR screen.
module QrisProfiles {

    var list as Array = [] as Array;   // entries: [name, payload]
    var current as Number = 0;

    function reload() as Void {
        list = [] as Array;
        for (var slot = 1; slot <= 3; slot++) {
            var payload = null;
            try {
                var raw = Application.Properties.getValue("qris" + slot.toString());
                if (raw != null && raw instanceof Lang.String) {
                    var trimmed = trim(raw as String);
                    if (QrisConvert.isValidPayload(trimmed)) {
                        payload = trimmed;
                    }
                }
            } catch (e) {
            }
            if (payload == null && slot == 1
                    && QrisConvert.isValidPayload(QrisConvert.BASE_PAYLOAD)) {
                // Built-in fallback (personal build). The store build
                // ships an empty BASE_PAYLOAD, so it gets no fallback
                // and can end up with zero profiles (handled in the UI).
                payload = QrisConvert.BASE_PAYLOAD;
            }
            if (payload != null) {
                var name = QrisConvert.merchantName(payload as String);
                if (name.length() == 0) {
                    name = "Profil " + slot.toString();
                }
                (list as Array).add([name, payload] as Array<String>);
            }
        }
        // Zero profiles is a real state in the store build (nothing
        // pasted yet): the editor then shows setup instructions
        // instead of the amount UI. name()/payload() stay null-safe.
        try {
            var saved = Application.Storage.getValue("profile");
            if (saved != null) {
                current = saved as Number;
            }
        } catch (e) {
        }
        if (current < 0 || current >= (list as Array).size()) {
            current = 0;
        }
    }

    function name() as String {
        if ((list as Array).size() == 0) {
            return "";
        }
        return ((list as Array)[current] as Array<String>)[0];
    }

    function payload() as String {
        if ((list as Array).size() == 0) {
            return "";
        }
        return ((list as Array)[current] as Array<String>)[1];
    }

    function count() as Number {
        return (list as Array).size();
    }

    // Switch to the next configured profile; true when it changed.
    function cycle() as Boolean {
        if ((list as Array).size() < 2) {
            return false;
        }
        current = (current + 1) % (list as Array).size();
        try {
            Application.Storage.setValue("profile", current);
        } catch (e) {
        }
        return true;
    }

    function trim(s as String) as String {
        var start = 0;
        var end = s.length();
        while (start < end && isSpace(s.substring(start, start + 1) as String)) {
            start++;
        }
        while (end > start && isSpace(s.substring(end - 1, end) as String)) {
            end--;
        }
        return s.substring(start, end) as String;
    }

    function isSpace(ch as String) as Boolean {
        return ch.equals(" ") || ch.equals("\n") || ch.equals("\r") || ch.equals("\t");
    }
}
