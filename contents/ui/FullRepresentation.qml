import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.extras as PlasmaExtras
import org.kde.kirigami as Kirigami

PlasmaExtras.Representation {
    id: full

    Layout.minimumWidth: Kirigami.Units.gridUnit * 20
    Layout.minimumHeight: Kirigami.Units.gridUnit * 16
    Layout.preferredWidth: Kirigami.Units.gridUnit * 22
    Layout.preferredHeight: Kirigami.Units.gridUnit * 18

    collapseMarginsHint: true

    header: PlasmaExtras.PlasmoidHeading {
        RowLayout {
            anchors.fill: parent
            spacing: Kirigami.Units.smallSpacing

            Kirigami.Heading {
                Layout.fillWidth: true
                level: 2
                text: i18n("Crypto Ticker")
                elide: Text.ElideRight
                font.family: "Fira Sans Condensed"
            }

            PlasmaComponents.ToolButton {
                icon.name: "view-refresh"
                display: QQC2.AbstractButton.IconOnly
                onClicked: root.fetch()
                QQC2.ToolTip.visible: hovered
                QQC2.ToolTip.text: i18n("Refresh now")
            }

            PlasmaComponents.ToolButton {
                icon.name: "configure"
                display: QQC2.AbstractButton.IconOnly
                onClicked: Plasmoid.internalAction("configure").trigger()
                QQC2.ToolTip.visible: hovered
                QQC2.ToolTip.text: i18n("Configure…")
            }
        }
    }

    contentItem: ColumnLayout {
        spacing: 0

        PlasmaExtras.PlaceholderMessage {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root.symbolList.length === 0
            iconName: "office-chart-line"
            text: i18n("No symbols configured")
            explanation: i18n("Open settings and add Binance trading pairs.")
            helpfulAction: Kirigami.Action {
                text: i18n("Configure…")
                icon.name: "configure"
                onTriggered: Plasmoid.internalAction("configure").trigger()
            }
        }

        PlasmaExtras.PlaceholderMessage {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root.symbolList.length > 0 && !root.hasData && root.lastError !== ""
            iconName: "network-disconnect"
            text: i18n("Couldn't load prices")
            explanation: root.lastError
        }

        QQC2.ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root.symbolList.length > 0 && (root.hasData || root.lastError === "")
            clip: true

            ListView {
                id: list
                model: root.symbolList
                spacing: 0

                delegate: QQC2.ItemDelegate {
                    id: del
                    width: ListView.view.width
                    hoverEnabled: true
                    padding: Kirigami.Units.largeSpacing

                    readonly property var ticker: root.tickerData[modelData] || null
                    readonly property color changeColor: ticker
                        ? (ticker.change >= 0 ? Kirigami.Theme.positiveTextColor : Kirigami.Theme.negativeTextColor)
                        : Kirigami.Theme.disabledTextColor

                    contentItem: RowLayout {
                        spacing: Kirigami.Units.largeSpacing

                        ColumnLayout {
                            Layout.minimumWidth: Kirigami.Units.gridUnit * 5
                            spacing: 0

                            PlasmaComponents.Label {
                                text: root.stripQuote(modelData)
                                font.bold: true
                                font.family: "Fira Sans Condensed"
                                font.pixelSize: Kirigami.Theme.defaultFont.pixelSize + 1
                                elide: Text.ElideRight
                            }
                            PlasmaComponents.Label {
                                text: {
                                    const quotes = ["USDT","USDC","FDUSD","BUSD","TUSD","DAI","USD","EUR","TRY","BTC","ETH"]
                                    for (const q of quotes) if (modelData.endsWith(q)) return q
                                    return ""
                                }
                                font.family: "Fira Sans Condensed"
                                font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                                opacity: 0.6
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            PlasmaComponents.Label {
                                Layout.fillWidth: true
                                horizontalAlignment: Text.AlignRight
                                text: ticker ? root.formatPrice(ticker.price) : "—"
                                font.bold: true
                                font.family: "Fira Sans Condensed"
                                font.pixelSize: Kirigami.Theme.defaultFont.pixelSize + 1
                            }
                            PlasmaComponents.Label {
                                Layout.fillWidth: true
                                horizontalAlignment: Text.AlignRight
                                visible: ticker !== null
                                text: ticker
                                    ? i18n("H %1  L %2",
                                           root.formatPrice(ticker.high),
                                           root.formatPrice(ticker.low))
                                    : ""
                                font.family: "Fira Sans Condensed"
                                font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                                opacity: 0.6
                            }
                        }

                        ColumnLayout {
                            Layout.minimumWidth: Kirigami.Units.gridUnit * 4.5
                            spacing: 0

                            RowLayout {
                                Layout.alignment: Qt.AlignRight
                                spacing: Kirigami.Units.smallSpacing / 2

                                PlasmaComponents.Label {
                                    text: ticker ? (ticker.change >= 0 ? "▲" : "▼") : ""
                                    color: del.changeColor
                                    font.family: "Fira Sans Condensed"
                                    font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                                }
                                PlasmaComponents.Label {
                                    text: ticker
                                        ? (ticker.change >= 0 ? "+" : "") + ticker.change.toFixed(2) + "%"
                                        : ""
                                    color: del.changeColor
                                    font.bold: true
                                    font.family: "Fira Sans Condensed"
                                }
                            }
                            PlasmaComponents.Label {
                                Layout.alignment: Qt.AlignRight
                                visible: ticker !== null
                                text: ticker
                                    ? i18n("Vol %1", formatVolume(ticker.volume))
                                    : ""
                                font.family: "Fira Sans Condensed"
                                font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                                opacity: 0.6
                            }
                        }
                    }
                }
            }
        }
    }

    footer: Item {
        implicitHeight: footerRow.implicitHeight + Kirigami.Units.smallSpacing * 2

        Kirigami.Separator {
            anchors { left: parent.left; right: parent.right; top: parent.top }
        }

        RowLayout {
            id: footerRow
            anchors {
                fill: parent
                leftMargin: Kirigami.Units.largeSpacing
                rightMargin: Kirigami.Units.largeSpacing
                topMargin: Kirigami.Units.smallSpacing
                bottomMargin: Kirigami.Units.smallSpacing
            }
            PlasmaComponents.Label {
                Layout.fillWidth: true
                text: root.hasData
                    ? i18n("Updated %1 · Binance", Qt.formatTime(root.lastUpdate, "HH:mm:ss"))
                    : i18n("Binance")
                font.family: "Fira Sans Condensed"
                font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                opacity: 0.6
                elide: Text.ElideRight
            }
        }
    }

    function formatVolume(v) {
        if (!v || isNaN(v)) return "—"
        if (v >= 1e9) return (v / 1e9).toFixed(2) + "B"
        if (v >= 1e6) return (v / 1e6).toFixed(2) + "M"
        if (v >= 1e3) return (v / 1e3).toFixed(1) + "K"
        return v.toFixed(0)
    }
}
