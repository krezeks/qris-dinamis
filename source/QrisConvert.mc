import Toybox.Lang;

// Static -> dynamic QRIS conversion (EMVCo TLV), mirroring the Python
// reference in ../qris.py. Changes vs the static original: tag 01 "11" ->
// "12", tag 54 (amount) inserted right after tag 53 (currency), tag 63
// CRC16-CCITT recomputed.
//
// Validation is deliberately strict (hardened 2026-11-18 after an external
// code review): a payload is accepted only if its TLV structure parses
// exactly end to end — numeric tags and lengths, no overruns, no trailing
// bytes, no duplicate top-level tags — AND the mandatory QRIS fields are
// present (merchant account 26-51, MCC 52, currency 53 = IDR "360",
// country 58 = "ID", name 59, city 60), tag 01 is "11" (static), no
// amount tag 54 is embedded, and the CRC16 matches. A CRC alone is only
// a checksum, never proof of structure, so it is checked last, on top of
// the structural parse. makePayload() additionally refuses to build a
// dynamic payload when tag 53 is missing (the amount could not be
// embedded while the screen shows one) and verifies its own output
// before returning it; on any failure it returns "" and the caller
// shows an error instead of a QR.
module QrisConvert {

    // STORE BUILD: no bundled payload. Users paste their own static
    // QRIS text in the app settings (see QrisProfiles); an empty base
    // simply means "no fallback profile".
    const BASE_PAYLOAD = "";

    // The on-watch encoder tops out at QR version 10, ECC level L, byte
    // mode: 271 bytes. A dynamic payload adds tag 54 — at most 12 chars
    // ("54" + 2 length digits + up to 8 amount digits) — so a static
    // payload is only accepted up to 259 chars. Longer profiles are
    // rejected at setup time instead of failing on the QR screen.
    const ENC_MAX = 271;
    const MAX_PAYLOAD = 259;

    // amount > 0: dynamic payload carrying that amount (integer rupiah).
    // amount == 0: the untouched static payload.
    // Returns "" when a dynamic payload cannot be built safely.
    function makePayload(base as String, amount as Number) as String {
        if (amount <= 0) {
            return base;
        }
        var tags = parseStrict(base);
        if (tags == null) {
            return "";
        }
        var t = tags as Array;
        if (getTag(t, "53") == null) {
            return "";               // no currency tag: nowhere to anchor the amount
        }
        var out = "";
        var inserted = false;
        for (var i = 0; i < t.size(); i++) {
            var pair = t[i] as Array<String>;
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
        if (!inserted) {
            return "";
        }
        out += "6304";
        out += crc16Hex(out);
        if (out.length() > ENC_MAX) {
            return "";
        }
        // Verify the result before anyone displays it: it must parse
        // strictly and carry exactly the amount the screen will show.
        var check = parseStrict(out);
        if (check == null) {
            return "";
        }
        var c = check as Array;
        var amt = getTag(c, "54");
        if (amt == null || !amt.equals(amount.toString())) {
            return "";
        }
        var poi = getTag(c, "01");
        if (poi == null || !poi.equals("12")) {
            return "";
        }
        return out;
    }

    // Strict TLV walk: returns an array of [tag, value] string pairs, or
    // null when the string is malformed in any way (short header,
    // non-numeric tag or length, value overrunning the string, trailing
    // bytes, duplicate top-level tag).
    function parseStrict(s as String) as Array or Null {
        var res = [] as Array;
        var seen = {} as Dictionary<String, Number>;
        var i = 0;
        var n = s.length();
        while (i < n) {
            if (i + 4 > n) {
                return null;
            }
            var tag = s.substring(i, i + 2) as String;
            var lenStr = s.substring(i + 2, i + 4) as String;
            if (!isDigits(tag) || !isDigits(lenStr)) {
                return null;
            }
            var len = lenStr.toNumber() as Number;
            if (i + 4 + len > n) {
                return null;
            }
            if (seen.hasKey(tag)) {
                return null;
            }
            seen.put(tag, 1);
            res.add([tag, s.substring(i + 4, i + 4 + len) as String]
                as Array<String>);
            i += 4 + len;
        }
        if (res.size() == 0) {
            return null;
        }
        return res;
    }

    function getTag(tags as Array, id as String) as String or Null {
        for (var i = 0; i < tags.size(); i++) {
            var pair = tags[i] as Array<String>;
            if (pair[0].equals(id)) {
                return pair[1];
            }
        }
        return null;
    }

    function isDigits(s as String) as Boolean {
        var b = s.toUtf8Array();
        if (b.size() == 0) {
            return false;
        }
        for (var i = 0; i < b.size(); i++) {
            var c = b[i] & 0xFF;
            if (c < 48 || c > 57) {
                return false;
            }
        }
        return true;
    }

    // A pasted payload is accepted only if it is a complete, well-formed
    // static QRIS string: strict TLV structure, mandatory fields, and a
    // CRC16 that matches the content.
    function isValidPayload(s as String) as Boolean {
        var n = s.length();
        if (n < 24 || n > MAX_PAYLOAD) {
            return false;
        }
        var tags = parseStrict(s);
        if (tags == null) {
            return false;
        }
        var t = tags as Array;
        var first = t[0] as Array<String>;
        if (!first[0].equals("00") || !first[1].equals("01")) {
            return false;
        }
        var last = t[t.size() - 1] as Array<String>;
        if (!last[0].equals("63") || last[1].length() != 4) {
            return false;
        }
        var expect = crc16Hex(s.substring(0, n - 4) as String);
        if (!expect.equals(last[1].toUpper())) {
            return false;
        }
        var poi = getTag(t, "01");
        if (poi == null || !poi.equals("11")) {
            return false;                       // profiles must be static
        }
        if (getTag(t, "54") != null) {
            return false;                       // static means: no amount embedded
        }
        var hasMerchant = false;
        for (var i = 0; i < t.size(); i++) {
            var tn = ((t[i] as Array<String>)[0]).toNumber();
            if (tn != null && tn >= 26 && tn <= 51) {
                hasMerchant = true;
            }
        }
        if (!hasMerchant) {
            return false;
        }
        if (getTag(t, "52") == null) {
            return false;
        }
        var cur = getTag(t, "53");
        if (cur == null || !cur.equals("360")) {
            return false;
        }
        var country = getTag(t, "58");
        if (country == null || !country.equals("ID")) {
            return false;
        }
        var name = getTag(t, "59");
        if (name == null || name.length() == 0) {
            return false;
        }
        if (getTag(t, "60") == null) {
            return false;
        }
        return true;
    }

    // Merchant display name (tag 59), "" when absent or malformed.
    function merchantName(s as String) as String {
        var tags = parseStrict(s);
        if (tags == null) {
            return "";
        }
        var name = getTag(tags as Array, "59");
        return name == null ? "" : (name as String);
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
