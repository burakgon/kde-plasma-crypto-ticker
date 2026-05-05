import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    readonly property var symbolList: (Plasmoid.configuration.symbols || "")
        .split(",").map(s => s.trim().toUpperCase()).filter(s => s.length > 0)
    readonly property string primarySymbol: symbolList.length > 0 ? symbolList[0] : ""

    property var tickerData: ({})
    property date lastUpdate: new Date(0)
    property bool hasData: false
    property string lastError: ""

    property bool onAC: true
    property int errorBackoff: 1
    readonly property int effectiveInterval: {
        const base = Math.max(5, Plasmoid.configuration.refreshInterval || 60)
        if (root.expanded) {
            return Math.max(5, Plasmoid.configuration.expandedInterval || 15)
        }
        const mult = onAC ? 1 : Math.max(1, Plasmoid.configuration.batteryMultiplier || 2)
        return Math.min(base * mult * errorBackoff, 30 * 60)
    }

    Plasmoid.icon: "office-chart-line"
    Plasmoid.busy: !hasData && !lastError
    toolTipMainText: i18n("Crypto Ticker")
    toolTipSubText: {
        if (lastError && !hasData) return i18n("Error: %1", lastError)
        if (!hasData) return i18n("Loading…")
        let lines = []
        for (let s of symbolList) {
            const t = tickerData[s]
            if (!t) continue
            const base = stripQuote(s)
            const arrow = t.change >= 0 ? "▲" : "▼"
            lines.push(`${base}  ${formatPrice(t.price)}  ${arrow} ${t.change.toFixed(2)}%`)
        }
        lines.push("")
        const power = onAC ? i18n("AC") : i18n("Battery")
        lines.push(i18n("Updated %1 · every %2s · %3",
                        Qt.formatTime(lastUpdate, "HH:mm:ss"),
                        effectiveInterval, power))
        return lines.join("\n")
    }

    function stripQuote(symbol) {
        if (!Plasmoid.configuration.showBaseOnly) return symbol
        const quotes = ["USDT", "USDC", "FDUSD", "BUSD", "TUSD", "DAI", "USD", "EUR", "TRY", "BTC", "ETH"]
        for (const q of quotes) {
            if (symbol.endsWith(q) && symbol.length > q.length) return symbol.slice(0, -q.length)
        }
        return symbol
    }

    function formatPrice(p) {
        if (p === undefined || p === null || isNaN(p)) return "—"
        const prefix = Plasmoid.configuration.showCurrencySymbol ? "$" : ""
        if (p >= 10000) return prefix + p.toLocaleString(Qt.locale("en_US"), 'f', 0)
        if (p >= 1) return prefix + p.toLocaleString(Qt.locale("en_US"), 'f', 2)
        if (p >= 0.01) return prefix + p.toFixed(4)
        if (p >= 0.0001) return prefix + p.toFixed(6)
        return prefix + p.toPrecision(4)
    }

    function fetch() {
        if (symbolList.length === 0) return
        const url = "https://api.binance.com/api/v3/ticker/24hr?symbols=["
            + symbolList.map(s => '%22' + s + '%22').join(",") + "]"
        const xhr = new XMLHttpRequest()
        xhr.open("GET", url)
        xhr.timeout = 10000
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE) return
            if (xhr.status === 200) {
                try {
                    const arr = JSON.parse(xhr.responseText)
                    const next = {}
                    for (const t of arr) {
                        next[t.symbol] = {
                            price: parseFloat(t.lastPrice),
                            change: parseFloat(t.priceChangePercent),
                            high: parseFloat(t.highPrice),
                            low: parseFloat(t.lowPrice),
                            volume: parseFloat(t.quoteVolume),
                            open: parseFloat(t.openPrice)
                        }
                    }
                    tickerData = next
                    lastUpdate = new Date()
                    hasData = true
                    lastError = ""
                    errorBackoff = 1
                } catch (e) {
                    handleFailure(e.toString())
                }
            } else if (xhr.status === 0) {
                handleFailure(i18n("Network unavailable"))
            } else {
                handleFailure(i18n("HTTP %1", xhr.status))
            }
        }
        xhr.ontimeout = () => handleFailure(i18n("Request timed out"))
        xhr.send()
    }

    function handleFailure(msg) {
        lastError = msg
        errorBackoff = Math.min(errorBackoff * 2, 16)
    }

    function detectPower() {
        const statusPaths = [
            "file:///sys/class/power_supply/BAT0/status",
            "file:///sys/class/power_supply/BAT1/status",
            "file:///sys/class/power_supply/battery/status"
        ]
        let pending = statusPaths.length
        let foundBattery = false
        let discharging = false

        const finish = () => {
            if (--pending !== 0) return
            onAC = !foundBattery || !discharging
        }

        for (const url of statusPaths) {
            const xhr = new XMLHttpRequest()
            xhr.open("GET", url)
            xhr.onreadystatechange = () => {
                if (xhr.readyState !== XMLHttpRequest.DONE) return
                const txt = (xhr.responseText || "").trim()
                if (txt.length > 0) {
                    foundBattery = true
                    if (txt === "Discharging") discharging = true
                }
                finish()
            }
            try { xhr.send() } catch (e) { finish() }
        }
    }

    Timer {
        id: refreshTimer
        interval: root.effectiveInterval * 1000
        running: root.symbolList.length > 0
        repeat: true
        triggeredOnStart: true
        onTriggered: root.fetch()
    }

    Timer {
        id: powerTimer
        interval: 60000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.detectPower()
    }

    Connections {
        target: Plasmoid.configuration
        function onSymbolsChanged() {
            root.errorBackoff = 1
            root.fetch()
        }
    }

    compactRepresentation: CompactRepresentation {}
    fullRepresentation: FullRepresentation {}

    Plasmoid.contextualActions: [
        PlasmaCore.Action {
            text: i18n("Refresh now")
            icon.name: "view-refresh"
            onTriggered: { root.errorBackoff = 1; root.fetch() }
        }
    ]
}
