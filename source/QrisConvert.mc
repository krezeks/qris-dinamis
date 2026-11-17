import Toybox.Lang;

// Static -> dynamic QRIS conversion (EMVCo TLV), a line-by-line port of the
// Python reference in ../qris.py, which is unit-tested against this payload.
// Changes vs the static original: tag 01 "11" -> "12", tag 54 (amount)
// inserted right after tag 53 (currency), tag 63 CRC16-CCITT recomputed.
module QrisConvert {

    // STORE BUILD: no bundled payload. Users paste their own static
    // QRIS text in the app settings (see QrisProfiles); an empty base
    // simply means "no fallback profile".
    const BASE_PAYLOAD = "";

    // amount > 0: dynamic payload carrying that amount (integer rupiah).
    // amount == 0: the untouched static payload.
    function makePayload(base as String, amount as Number) as String {
        if (amount <= 0) {
            return base;
        }
        var tags = parse(base);
        var out = "";
        var inserted = false;
        for (var i = 0; i < tags.size(); i++) {
            var pair = tags[i] as Array<String>;
            var tag = pair[0];
            var val = pair[1];
            if (tag.equals("63")) {
                continue;                       // CRC rebuilt at the end
            }
            if (tag.equals("54")) {
                continue;                       // amount re-inserted after tag 53
            }
            if (tag.equals("01")) {
                val = "12";                     // static -> dynamic
            }
            out += tag + fmtLen(val.length()) + val;
            if (tag.equals("53") && !inserted) {
                var amt = amount.toString();
                out += "54" + fmtLen(amt.length()) + amt;
                inserted = true;
            }
        }
        out += "6304";
        out += crc16Hex(out);
        return out;
    }

    // TLV walk: returns an array of [tag, value] string pairs.
    function parse(s as String) as Array {
        var res = [] as Array;
        var i = 0;
        var n = s.length();
        while (i + 4 <= n) {
            var tag = s.substring(i, i + 2) as String;
            var len = (s.substring(i + 2, i + 4) as String).toNumber();
            if (len == null) {
                break;
            }
            var val = s.substring(i + 4, i + 4 + (len as Number)) as String;
            res.add([tag, val] as Array<String>);
            i += 4 + (len as Number);
        }
        return res;
    }

    // A pasted payload is accepted only if it looks like a complete,
    // untampered QRIS string: EMV header, CRC marker, and a CRC16 that
    // matches the content. Anything else is rejected by the caller.
    function isValidPayload(s as String) as Boolean {
        var n = s.length();
        if (n < 24 || n > 512) {
            return false;
        }
        if (!(s.substring(0, 6) as String).equals("000201")) {
            return false;
        }
        if (!(s.substring(n - 8, n - 4) as String).equals("6304")) {
            return false;
        }
        var expect = crc16Hex(s.substring(0, n - 4) as String);
        return expect.equals((s.substring(n - 4, n) as String).toUpper());
    }

    // Merchant display name (tag 59), "" when absent.
    function merchantName(s as String) as String {
        var tags = parse(s);
        for (var i = 0; i < tags.size(); i++) {
            var pair = tags[i] as Array<String>;
            if (pair[0].equals("59")) {
                return pair[1];
            }
        }
        return "";
    }

    function fmtLen(len as Number) as String {
        return len < 10 ? "0" + len.toString() : len.toString();
    }

    // CRC16-CCITT, polynomial 0x1021, initial value 0xFFFF, uppercase hex.
    function crc16Hex(s as String) as String {
        var bytes = s.toUtf8Array();
        var crc = 0xFFFF;
        for (var i = 0; i < bytes.size(); i++) {
            crc = crc ^ ((bytes[i] & 0xFF) << 8);
            for (var b = 0; b < 8; b++) {
                if ((crc & 0x8000) != 0) {
                    crc = ((crc << 1) ^ 0x1021) & 0xFFFF;
                } else {
                    crc = (crc << 1) & 0xFFFF;
                }
            }
        }
        var hex = "0123456789ABCDEF";
        var out = "";
        for (var sft = 12; sft >= 0; sft -= 4) {
            var nib = (crc >> sft) & 0xF;
            out += hex.substring(nib, nib + 1);
        }
        return out;
    }

    // "25000" -> "25.000" (Indonesian thousand separator).
    function formatRupiah(amount as Number) as String {
        var digits = amount.toString();
        var out = "";
        var n = digits.length();
        for (var i = 0; i < n; i++) {
            if (i > 0 && (n - i) % 3 == 0) {
                out += ".";
            }
            out += digits.substring(i, i + 1);
        }
        return out;
    }
}
