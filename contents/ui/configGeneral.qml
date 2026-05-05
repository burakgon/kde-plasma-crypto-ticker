import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    id: page

    property alias cfg_refreshInterval: refreshSpin.value
    property alias cfg_batteryMultiplier: batteryMultSpin.value
    property alias cfg_expandedInterval: expandedSpin.value
    property alias cfg_showChange: changeCheck.checked
    property alias cfg_showBaseOnly: baseOnlyCheck.checked
    property alias cfg_showCurrencySymbol: currencyCheck.checked
    property alias cfg_showSymbolName: nameCheck.checked
    property alias cfg_fontSize: fontSpin.value
    property string cfg_symbols: ""

    readonly property var currentSymbols: cfg_symbols.split(",").map(s => s.trim().toUpperCase()).filter(s => s)

    function setSymbols(arr) {
        cfg_symbols = arr.join(",")
    }

    function addSymbol(sym) {
        sym = (sym || "").trim().toUpperCase()
        if (!sym) return
        const list = currentSymbols.slice()
        if (list.indexOf(sym) !== -1) return
        list.push(sym)
        setSymbols(list)
    }

    function removeSymbol(sym) {
        setSymbols(currentSymbols.filter(s => s !== sym))
    }

    function pinSymbol(sym) {
        const list = currentSymbols.filter(s => s !== sym)
        list.unshift(sym)
        setSymbols(list)
    }

    ListModel { id: suggestionsModel }
    property var allSymbols: []
    property var allMeta: ({})
    property bool exchangeInfoLoaded: false
    property string exchangeInfoError: ""

    readonly property var knownQuotes: [
        "USDT","USDC","FDUSD","BUSD","TUSD","DAI",
        "USD","EUR","GBP","TRY","JPY","BRL","AUD","RUB","UAH","ZAR","ARS","MXN","PLN","RON",
        "BTC","ETH","BNB","XRP","DOGE","SOL","TRX"
    ]

    Component.onCompleted: fetchExchangeInfo()

    function splitSymbol(sym) {
        for (const q of knownQuotes) {
            if (sym.endsWith(q) && sym.length > q.length) {
                return { base: sym.slice(0, -q.length), quote: q }
            }
        }
        return { base: sym, quote: "" }
    }

    function fetchExchangeInfo() {
        const xhr = new XMLHttpRequest()
        xhr.open("GET", "https://api.binance.com/api/v3/ticker/price")
        xhr.timeout = 20000
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE) return
            if (xhr.status === 200) {
                try {
                    const arr = JSON.parse(xhr.responseText)
                    const syms = new Array(arr.length)
                    const meta = {}
                    for (let i = 0; i < arr.length; i++) {
                        const s = arr[i].symbol
                        syms[i] = s
                        meta[s] = splitSymbol(s)
                    }
                    allSymbols = syms
                    allMeta = meta
                    exchangeInfoLoaded = true
                    exchangeInfoError = ""
                    refreshSuggestions(searchField.text)
                } catch (e) {
                    exchangeInfoError = e.toString()
                }
            } else if (xhr.status === 0) {
                exchangeInfoError = i18n("Network unavailable")
            } else {
                exchangeInfoError = i18n("HTTP %1", xhr.status)
            }
        }
        xhr.ontimeout = () => exchangeInfoError = i18n("Timed out")
        xhr.send()
    }

    function refreshSuggestions(query) {
        suggestionsModel.clear()
        const q = (query || "").trim().toUpperCase()
        if (q.length < 1) return
        const exact = []
        const prefix = []
        const contains = []
        for (let i = 0; i < allSymbols.length; i++) {
            const sym = allSymbols[i]
            const m = allMeta[sym]
            if (sym === q || (m && m.base === q)) exact.push(sym)
            else if (sym.startsWith(q) || (m && m.base.startsWith(q))) prefix.push(sym)
            else if (sym.indexOf(q) !== -1) contains.push(sym)
            if (exact.length >= 12) break
        }
        const ordered = exact.concat(prefix).concat(contains).slice(0, 12)
        for (const sym of ordered) {
            const m = allMeta[sym] || { base: sym, quote: "" }
            suggestionsModel.append({ symbol: sym, base: m.base, quote: m.quote })
        }
    }

    // --- Symbols section ---

    ColumnLayout {
        Kirigami.FormData.label: i18n("Symbols:")
        Kirigami.FormData.labelAlignment: Qt.AlignTop
        Layout.fillWidth: true
        Layout.preferredWidth: Kirigami.Units.gridUnit * 26
        spacing: Kirigami.Units.smallSpacing

        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            QQC2.TextField {
                id: searchField
                Layout.fillWidth: true
                placeholderText: page.exchangeInfoLoaded
                    ? i18n("Search e.g. BTC, ETHUSDT, SOL…")
                    : (page.exchangeInfoError ? i18n("Couldn't reach Binance") : i18n("Loading symbols…"))
                enabled: page.exchangeInfoLoaded
                onTextChanged: page.refreshSuggestions(text)
                Keys.onReturnPressed: addBtn.activate()
                Keys.onEnterPressed: addBtn.activate()
            }

            QQC2.Button {
                id: addBtn
                icon.name: "list-add"
                text: i18n("Add")
                enabled: searchField.text.trim().length > 0
                function activate() {
                    if (suggestionsModel.count > 0) {
                        page.addSymbol(suggestionsModel.get(0).symbol)
                    } else {
                        page.addSymbol(searchField.text)
                    }
                    searchField.text = ""
                }
                onClicked: activate()
            }
        }

        Kirigami.Card {
            Layout.fillWidth: true
            visible: searchField.text.length > 0 && suggestionsModel.count > 0

            contentItem: ColumnLayout {
                spacing: 0

                Repeater {
                    model: suggestionsModel
                    delegate: QQC2.ItemDelegate {
                        Layout.fillWidth: true
                        contentItem: RowLayout {
                            spacing: Kirigami.Units.largeSpacing
                            QQC2.Label {
                                text: model.symbol
                                font.bold: true
                                font.family: "Fira Sans Condensed"
                            }
                            QQC2.Label {
                                Layout.fillWidth: true
                                text: model.base + " / " + model.quote
                                opacity: 0.6
                                font.family: "Fira Sans Condensed"
                            }
                            QQC2.Label {
                                visible: page.currentSymbols.indexOf(model.symbol) !== -1
                                text: i18n("added")
                                opacity: 0.5
                                font: Kirigami.Theme.smallFont
                            }
                        }
                        onClicked: {
                            page.addSymbol(model.symbol)
                            searchField.text = ""
                        }
                    }
                }
            }
        }

        QQC2.Label {
            Layout.fillWidth: true
            visible: page.currentSymbols.length === 0
            text: i18n("No symbols added yet.")
            opacity: 0.6
            font: Kirigami.Theme.smallFont
        }

        Flow {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing
            visible: page.currentSymbols.length > 0

            Repeater {
                model: page.currentSymbols

                Rectangle {
                    height: chipRow.implicitHeight + Kirigami.Units.smallSpacing
                    width: chipRow.implicitWidth + Kirigami.Units.largeSpacing
                    radius: height / 2
                    color: index === 0 ? Kirigami.Theme.highlightColor : Kirigami.Theme.alternateBackgroundColor
                    border.width: 1
                    border.color: index === 0 ? Kirigami.Theme.highlightColor : Kirigami.Theme.separatorColor

                    RowLayout {
                        id: chipRow
                        anchors.centerIn: parent
                        spacing: Kirigami.Units.smallSpacing

                        Kirigami.Icon {
                            visible: index === 0
                            source: "pin"
                            color: Kirigami.Theme.highlightedTextColor
                            implicitWidth: Kirigami.Units.iconSizes.small
                            implicitHeight: Kirigami.Units.iconSizes.small
                        }

                        QQC2.Label {
                            text: modelData
                            font.bold: true
                            font.family: "Fira Sans Condensed"
                            color: index === 0 ? Kirigami.Theme.highlightedTextColor : Kirigami.Theme.textColor
                        }

                        QQC2.AbstractButton {
                            visible: index !== 0
                            implicitWidth: Kirigami.Units.iconSizes.small
                            implicitHeight: Kirigami.Units.iconSizes.small
                            QQC2.ToolTip.visible: hovered
                            QQC2.ToolTip.text: i18n("Pin to panel")
                            contentItem: Kirigami.Icon {
                                source: "pin"
                                color: Kirigami.Theme.textColor
                                opacity: parent.hovered ? 1.0 : 0.4
                            }
                            onClicked: page.pinSymbol(modelData)
                        }

                        QQC2.AbstractButton {
                            implicitWidth: Kirigami.Units.iconSizes.small
                            implicitHeight: Kirigami.Units.iconSizes.small
                            QQC2.ToolTip.visible: hovered
                            QQC2.ToolTip.text: i18n("Remove")
                            contentItem: Kirigami.Icon {
                                source: "edit-delete-remove"
                                color: index === 0 ? Kirigami.Theme.highlightedTextColor : Kirigami.Theme.textColor
                                opacity: parent.hovered ? 1.0 : 0.5
                            }
                            onClicked: page.removeSymbol(modelData)
                        }
                    }
                }
            }
        }

        QQC2.Label {
            Layout.fillWidth: true
            text: i18n("The first symbol is shown in the panel; the rest appear in the popup.")
            opacity: 0.7
            wrapMode: Text.WordWrap
            font: Kirigami.Theme.smallFont
        }
    }

    Item { Kirigami.FormData.isSection: true }

    // --- Refresh section ---

    QQC2.SpinBox {
        id: refreshSpin
        Kirigami.FormData.label: i18n("Refresh every:")
        from: 5
        to: 3600
        stepSize: 5
        textFromValue: (v) => i18n("%1 s", v)
        valueFromText: (t) => parseInt(t)
    }

    QQC2.SpinBox {
        id: batteryMultSpin
        Kirigami.FormData.label: i18n("On battery:")
        from: 1
        to: 10
        textFromValue: (v) => v === 1 ? i18n("Same as AC") : i18n("%1× slower", v)
        valueFromText: (t) => parseInt(t) || 1
    }

    QQC2.SpinBox {
        id: expandedSpin
        Kirigami.FormData.label: i18n("While popup open:")
        from: 5
        to: 60
        stepSize: 5
        textFromValue: (v) => i18n("%1 s", v)
        valueFromText: (t) => parseInt(t)
    }

    QQC2.Label {
        Layout.preferredWidth: Kirigami.Units.gridUnit * 26
        text: i18n("Polling pauses on errors with exponential backoff (up to 16×).")
        font: Kirigami.Theme.smallFont
        opacity: 0.7
        wrapMode: Text.WordWrap
    }

    Item { Kirigami.FormData.isSection: true }

    // --- Display section ---

    QQC2.CheckBox {
        id: nameCheck
        Kirigami.FormData.label: i18n("Display:")
        text: i18n("Show symbol name")
    }

    QQC2.CheckBox {
        id: changeCheck
        text: i18n("Show 24h change percentage")
    }

    QQC2.CheckBox {
        id: baseOnlyCheck
        text: i18n("Hide quote currency (BTC instead of BTCUSDT)")
    }

    QQC2.CheckBox {
        id: currencyCheck
        text: i18n("Show currency symbol ($)")
    }

    Item { Kirigami.FormData.isSection: true }

    QQC2.SpinBox {
        id: fontSpin
        Kirigami.FormData.label: i18n("Font size:")
        from: 0
        to: 32
        textFromValue: (v) => v === 0 ? i18n("Default") : i18n("%1 px", v)
        valueFromText: (t) => t === i18n("Default") ? 0 : parseInt(t)
    }

    QQC2.Label {
        Layout.preferredWidth: Kirigami.Units.gridUnit * 26
        text: i18n("0 = system default. The widget always uses Fira Sans Condensed.")
        font: Kirigami.Theme.smallFont
        opacity: 0.7
        wrapMode: Text.WordWrap
    }
}
