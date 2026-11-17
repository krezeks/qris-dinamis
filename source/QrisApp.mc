import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

// QRIS Dinamis: shows a QRIS code on the watch with an adjustable
// amount. Up to three QRIS profiles, configured through the app
// settings in Garmin Connect (see QrisProfiles). Entry point;
// restores the last amount/step from storage.
class QrisApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state as Dictionary or Null) as Void {
        QrisProfiles.reload();
    }

    // Fired when the user edits the app settings in Garmin Connect:
    // re-read the profile payloads so changes apply on the next screen
    // draw, without reinstalling the app.
    function onSettingsChanged() as Void {
        QrisProfiles.reload();
        WatchUi.requestUpdate();
    }

    function onStop(state as Dictionary or Null) as Void {
    }

    function getInitialView() {
        var amount = 0;
        var step = 500;
        try {
            var a = Application.Storage.getValue("amount");
            if (a != null) {
                amount = a as Number;
            }
            // Storage key renamed whenever the default step changes
            // ("step" 10rb -> "step2" 1rb -> "step3" 500) so a step saved
            // by an earlier build is not restored over the new default.
            var s = Application.Storage.getValue("step3");
            if (s != null) {
                step = s as Number;
            }
        } catch (e) {
        }
        var view = new AmountView(amount, step);
        return [view, new AmountDelegate(view)];
    }
}
