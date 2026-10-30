# Example Demo Catalog — coverage audit (2026-10-30)

## Scope and result

This PR modifies the PTools Example application only; there are no PTools public API or runtime behavior changes.

- Cataloged module IDs: **258**
- Modules marked `runnable`: **124**
- New interactive API lab routes: **20**
- Pre-existing descriptors linked to the registry: **17**
- Runnable module IDs still without an attached demo: **51**

The old validator checked that every module had a registry row, but did not prevent a growing number of `runnable` module rows with empty demos. It also could not distinguish a real new lab from a metadata-only fallback. This PR introduces a decreasing baseline and a real-handler check for the added labs.

## New labs

- `text.filter-words-lab`
- `data.country-codes-lab`
- `ui.accessibility-lab`
- `ui.content-state-lab`
- `navigation.deep-link-lab`
- `storage.namespace-lab`
- `debug.simulation-clock-lab`
- `navigation.route-value-lab`
- `ui.checkbox-lab`
- `text.pinyin-lab`
- `ui.half-circle-lab`
- `input.searchbar-lab`
- `ui.pagecontrol-lab`
- `device.haptics-lab`
- `core.date-parser-lab`
- `network.connectivity-lab`
- `security.keychain-lab`
- `ui.symbols-lab`
- `debug.logging-lab`
- `modern.web-lab`

These are standalone UIKit examples driven by the real library APIs. Sensitive operations are confined to an ephemeral KeyChain service. Networking demos read diagnostics or show offline content and do not start a production HTTP service. Hardware haptics may not produce an effect on the Simulator.

## Verification

Static catalog and registry consistency checked: **no unknown IDs, no duplicate mappings, no unregistered descriptors, and no new labs missing routes**.

Run from repository root on macOS:

```sh
python3 Scripts/Example/validate_demo_coverage.py --check
xcodebuild -workspace PooTools.xcworkspace -scheme PooTools-Example -configuration Debug -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build
```

The Swift Example build requires Xcode and installed project dependencies. This change has not been claimed as device- or simulator-build verified in the GitHub connector environment.

## Remaining `runnable` modules without a directly registered demo

The remainder needs an API-by-API audit. Some IDs are umbrella/compatibility surfaces, some expose device-only functionality, and some share existing working demos. Do not attach an unrelated demo only to make counts green.

- `poo-tools-bank-card`
- `poo-tools-calendar`
- `poo-tools-contact`
- `poo-tools-customer-label`
- `poo-tools-debugtracking-eyes`
- `poo-tools-guide`
- `poo-tools-hud`
- `poo-tools-iap`
- `poo-tools-image-picker`
- `poo-tools-instructions`
- `poo-tools-keyboard`
- `poo-tools-launch-time-profiler`
- `poo-tools-location`
- `poo-tools-media-core`
- `poo-tools-motion`
- `poo-tools-net-work`
- `poo-tools-osskit-speech`
- `poo-tools-paging-control`
- `poo-tools-pdf`
- `poo-tools-picker`
- `poo-tools-search`
- `poo-tools-security`
- `poo-tools-slider`
- `poo-tools-smart-screenshot`
- `poo-tools-socket-kit`
- `poo-tools-speed-panel`
- `poo-tools-step-count`
- `poo-tools-stepper`
- `poo-tools-tips-view`
- `poo-tools-whats-news-kit`
- `ptcalendar-permission`
- `ptcamera-permission`
- `ptcontacts-permission`
- `ptface-idpermission`
- `pthealth-permission`
- `ptlocation-permission`
- `ptmedia-permission`
- `ptmic-permission`
- `ptmotion-permission`
- `ptnotification-permission`
- `ptools-background-tasks`
- `ptools-httpfile-portal`
- `ptools-httpserver`
- `ptools-notifications`
- `ptools-overlay`
- `ptools-permission-core`
- `ptools-simulation`
- `ptreminders-permission`
- `ptsiri-permission`
- `ptspeech-permission`
- `pttracking-permission`

## Follow-up acceptance bar

A module is complete only when its sample can be launched from the Example catalog, invokes the real PTools API, handles requirements and failure states, and has a verified Simulator or physical-device test path. The baseline must only decrease.
