<div align="center">

# Crypto Ticker

**Live Binance prices in your KDE Plasma 6 panel.**

[![Plasma 6](https://img.shields.io/badge/Plasma-6.0%2B-1d99f3?logo=kde&logoColor=white)](https://kde.org/plasma-desktop/)
[![Qt](https://img.shields.io/badge/Qt-6-41cd52?logo=qt&logoColor=white)](https://www.qt.io)
[![QML](https://img.shields.io/badge/built%20with-QML-8e44ad)](https://doc.qt.io/qt-6/qmlapplications.html)
[![License: MIT](https://img.shields.io/badge/license-MIT-yellow.svg)](LICENSE)

A small, native Plasma widget that shows real-time crypto prices in your panel — built around a single batched call to Binance's public market data API. No keys, no logins, no telemetry.

</div>

```
 ┌──────────────────────────────────┐
 │  BTC  $81,159   ▲ 1.36%          │   ← compact (panel)
 └──────────────────────────────────┘
        │
        ▼ click
 ┌──────────────────────────────────┐
 │  Crypto Ticker        ⟳   ⚙      │
 ├──────────────────────────────────┤
 │  BTC   USDT   $81,159    +1.36%  │
 │              H 81,323  L 78,202  │
 │  ETH   USDT   $3,218     +0.42%  │
 │  SOL   USDT   $214.10    -2.11%  │
 ├──────────────────────────────────┤
 │  Updated 18:42:07 · Binance      │
 └──────────────────────────────────┘
```

## Highlights

- **Native styling.** Built on `Kirigami`, `PlasmaComponents`, and `PlasmaExtras`. Picks up your theme colors, accent, font scale, and panel form factor automatically.
- **Battery-aware polling.** Reads `/sys/class/power_supply/BAT*/status` and slows the refresh rate on battery by a configurable multiplier.
- **Exponential backoff.** When Binance is unreachable, polling backs off 1× → 2× → … → 16× (capped at 30 min) and resets on success.
- **Active when watched.** The popup polls faster than the collapsed panel — fresh prices when you're looking, idle otherwise.
- **Smart symbol picker.** Live ranked search against `/api/v3/exchangeInfo` (exact → prefix → contains, top 12), with chips and a one-click pin to choose what shows in the panel.
- **One symbol in the panel,** all of them in the popup — keeps the taskbar tight.
- **Single batched HTTP request** for all symbols (`/api/v3/ticker/24hr?symbols=[…]`).
- **Condensed display font** (Fira Sans Condensed) for dense, legible readouts in tight panel space.

## Install

### From source

```bash
git clone https://github.com/burakgon/cryptoticker.git
cd cryptoticker
kpackagetool6 --type Plasma/Applet --install .
```

### Add it to the panel

Right-click your panel → **Add or Manage Widgets…** → search **Crypto Ticker** → drag onto the panel.

### Update

```bash
git pull
kpackagetool6 --type Plasma/Applet --upgrade .
kquitapp6 plasmashell && kstart plasmashell
```

### Remove

```bash
kpackagetool6 --type Plasma/Applet --remove com.bgn.cryptoticker
```

## Configuration

Right-click the widget → **Configure Crypto Ticker**.

| Setting | Description | Default |
| --- | --- | --- |
| **Symbols** | Live picker fed by Binance's `exchangeInfo`. The first entry is shown in the panel; the rest in the popup. Pin / remove via chip buttons. | `BTCUSDT, ETHUSDT, SOLUSDT` |
| **Refresh every** | Base poll interval in seconds. | `60 s` |
| **On battery** | Multiplier applied to base interval while on battery. | `2×` |
| **While popup open** | Faster interval used when the popup is expanded. | `15 s` |
| **Show symbol name** | Toggle the symbol label in the panel (price-only mode). | on |
| **Show 24h change** | Colored ▲ / ▼ percentage. | on |
| **Hide quote currency** | Show `BTC` instead of `BTCUSDT`. | on |
| **Show currency symbol** | Prefix prices with `$`. | on |
| **Font size** | Override panel font size in pixels. `0` = system default. | `0` |

## How it polls

```
effectiveInterval =
    expanded
        ? expandedInterval                      # 15 s default
        : min( refreshInterval
             × (onAC ? 1 : batteryMultiplier)   # 2× on battery
             × errorBackoff,                    # doubles per failure, cap 16
               30 min )
```

`errorBackoff` doubles on every failed fetch and resets to `1` on success or a manual refresh.

## Project layout

```
cryptoticker/
├── metadata.json
└── contents/
    ├── config/
    │   ├── main.xml          KConfig schema
    │   └── config.qml        config category model
    └── ui/
        ├── main.qml          PlasmoidItem · fetch loop · power detection · backoff
        ├── CompactRepresentation.qml   single-symbol panel pill
        ├── FullRepresentation.qml      popup list with header / footer
        └── configGeneral.qml           settings page with live symbol picker
```

## API endpoints used

Both are public, unauthenticated, and rate-limited per IP. No API key required.

| Endpoint | When | Purpose |
| --- | --- | --- |
| `GET /api/v3/exchangeInfo?permissions=SPOT` | once, when the config page opens | feed the symbol picker |
| `GET /api/v3/ticker/24hr?symbols=[…]` | every refresh tick | batched 24h stats for all configured symbols |

## Requirements

- KDE Plasma **6.0+**
- Qt **6**
- `kpackagetool6` (ships with Plasma 6)
- Optional: **Fira Sans Condensed** font for the intended condensed look (Qt falls back to your default font otherwise)

## License

[MIT](LICENSE) © Burak Goncu
