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
    readonly property bool empty: root.primarySymbol === ""

    readonly property int contentWidth: empty
        ? emptyIcon.implicitWidth
        : layout.implicitWidth
    readonly property int contentHeight: empty
        ? emptyIcon.implicitHeight
        : layout.implicitHeight

    implicitWidth: contentWidth
    implicitHeight: contentHeight

    Layout.minimumWidth: vertical ? -1 : contentWidth
    Layout.preferredWidth: contentWidth
    Layout.maximumWidth: vertical ? Number.POSITIVE_INFINITY : contentWidth
    Layout.minimumHeight: vertical ? contentHeight : -1
    Layout.preferredHeight: contentHeight
    Layout.maximumHeight: vertical ? contentHeight : Number.POSITIVE_INFINITY
    Layout.fillWidth: vertical
    Layout.fillHeight: !vertical

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
        visible: !compactRoot.empty

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

    Kirigami.Icon {
        id: emptyIcon
        anchors.centerIn: parent
        visible: compactRoot.empty
        source: "office-chart-line"
        implicitWidth: Kirigami.Units.iconSizes.smallMedium
        implicitHeight: Kirigami.Units.iconSizes.smallMedium
        opacity: 0.7
    }
}
