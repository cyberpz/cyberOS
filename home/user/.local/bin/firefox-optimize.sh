#!/bin/bash
# firefox-optimize.sh — Applica ottimizzazioni Firefox per cyberOS

PROFILE_DIR=$(find "$HOME/.mozilla/firefox" -maxdepth 1 -type d -name '*.default-esr' | head -1)

if [ -z "$PROFILE_DIR" ]; then
    echo "Profilo Firefox default-esr non trovato."
    exit 1
fi

USER_JS="$PROFILE_DIR/user.js"

cat > "$USER_JS" <<'EOF'
// Firefox optimizations for cyberOS / DebianPz
// Reduce disk I/O on NVMe/live USB and improve RAM usage

// Cache in RAM instead of disk (faster, no NVMe writes)
user_pref("browser.cache.disk.enable", false);
user_pref("browser.cache.memory.enable", true);
user_pref("browser.cache.memory.capacity", 524288); // 512 MB RAM cache

// Reduce session store frequency (default 15s, now 10 min)
user_pref("browser.sessionstore.interval", 600000);

// Reduce number of content processes (save RAM)
user_pref("dom.ipc.processCount", 4);

// Disable Pocket, Firefox View, Sponsored content
user_pref("extensions.pocket.enabled", false);
user_pref("browser.tabs.firefox-view", false);
user_pref("browser.newtabpage.activity-stream.showSponsored", false);
user_pref("browser.newtabpage.activity-stream.showSponsoredTopSites", false);

// Compact UI
user_pref("browser.compactmode.show", true);

// Smooth scrolling
user_pref("general.smoothScroll", true);

// Reduce telemetry
user_pref("datareporting.healthreport.uploadEnabled", false);
user_pref("toolkit.telemetry.enabled", false);
user_pref("toolkit.telemetry.unified", false);

// Hardware acceleration
user_pref("layers.acceleration.force-enabled", true);
EOF

echo "Ottimizzazioni Firefox applicate in $USER_JS"
