pragma Singleton
import Quickshell
import QtQuick

Singleton {
    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    readonly property var now: clock.date
    readonly property real synodicMonth: 29.53059
    readonly property var referenceNewMoon: new Date(Date.UTC(2000, 0, 6, 18, 14))

    function moonAgeDaysFor(dateObj) {
        const diffDays = (dateObj - referenceNewMoon) / 86400000;
        return ((diffDays % synodicMonth) + synodicMonth) % synodicMonth;
    }

    function moonPhaseDegreeFor(dateObj) {
        const age = moonAgeDaysFor(dateObj);
        var degree = 360 - ((age / synodicMonth) * 360);
        if (degree >= 355 || degree <= 5)
            return 0;
        if (degree >= 175 && degree <= 185)
            return 180;
        return degree;
    }

    function moonPhaseNameFor(dateObj) {
        const age = moonAgeDaysFor(dateObj);
        if (age < 1.85 || age >= 27.68) return "New Moon";
        if (age < 5.54) return "Waxing Crescent";
        if (age < 9.23) return "First Quarter";
        if (age < 12.92) return "Waxing Gibbous";
        if (age < 16.61) return "Full Moon";
        if (age < 20.30) return "Waning Gibbous";
        if (age < 23.99) return "Last Quarter";
        return "Waning Crescent";
    }

    readonly property real synodicDays: moonAgeDaysFor(now)

    readonly property string time: {
        const h = now.getHours().toString().padStart(2, "0");
        const m = now.getMinutes().toString().padStart(2, "0");
        return h + ":" + m;
    }

    readonly property string date: {
        const months = ["JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"];
        return months[now.getMonth()] + "·" + now.getDate().toString().padStart(2, "0");
    }

    readonly property string weekday: {
        const days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
        return days[now.getDay()];
    }

    readonly property string daytime: {
        const h = now.getHours();
        if (h >= 5 && h < 12)
            return "Dawn";
        if (h >= 12 && h < 17)
            return "Noon";
        if (h >= 17 && h < 21)
            return "Dusk";
        return "Dark";
    }

    readonly property real moonPhaseDegree: moonPhaseDegreeFor(now)
    readonly property string moonPhaseName: moonPhaseNameFor(now)
}
