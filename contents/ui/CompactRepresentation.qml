import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

MouseArea {
    id: compactRoot

    readonly property bool vertical: Plasmoid.formFactor === PlasmaCore.Types.Vertical
    readonly property int basePx: Plasmoid.configuration.fontSize > 0
        ? Plasmoid.configuration.fontSize
        : Kirigami.Theme.smallFont.pixelSize
    readonly property var ticker: root.tickerData[root.primarySymbol] || null

    implicitWidth: layout.implicitWidth + Kirigami.Units.smallSpacing * 2
    implicitHeight: layout.implicitHeight + Kirigami.Units.smallSpacing

    hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.MiddleButton
    onClicked: (mouse) => {
        if (mouse.button === Qt.MiddleButton) {
            root.errorBackoff = 1
            root.fetch()
        } else {
            root.expanded = !root.expanded
        }
    }

    RowLayout {
        id: layout
        anchors.centerIn: parent
        spacing: Kirigami.Units.smallSpacing
        visible: root.primarySymbol !== ""

        PlasmaComponents.Label {
            visible: Plasmoid.configuration.showSymbolName
            text: root.stripQuote(root.primarySymbol)
            font.bold: true
            font.family: "Fira Sans Condensed"
            font.pixelSize: compactRoot.basePx
            color: Kirigami.Theme.textColor
            opacity: 0.85
        }

        PlasmaComponents.Label {
            text: compactRoot.ticker ? root.formatPrice(compactRoot.ticker.price) : "—"
            font.family: "Fira Sans Condensed"
            font.pixelSize: compactRoot.basePx
            color: Kirigami.Theme.textColor
        }

        PlasmaComponents.Label {
            visible: Plasmoid.configuration.showChange && compactRoot.ticker !== null
            text: compactRoot.ticker
                ? (compactRoot.ticker.change >= 0 ? "▲" : "▼") + " " + Math.abs(compactRoot.ticker.change).toFixed(2) + "%"
                : ""
            font.family: "Fira Sans Condensed"
            font.pixelSize: Math.max(8, compactRoot.basePx - 1)
            color: compactRoot.ticker
                ? (compactRoot.ticker.change >= 0 ? Kirigami.Theme.positiveTextColor : Kirigami.Theme.negativeTextColor)
                : Kirigami.Theme.textColor
        }
    }

    PlasmaComponents.Label {
        anchors.centerIn: parent
        visible: root.primarySymbol === ""
        text: i18n("No symbols")
        font.family: "Fira Sans Condensed"
        font.pixelSize: compactRoot.basePx
        opacity: 0.6
    }
}
