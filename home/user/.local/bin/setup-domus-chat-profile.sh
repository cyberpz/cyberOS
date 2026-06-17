#!/bin/bash
# setup-domus-chat-profile.sh — Crea il profilo Firefox dedicato per DOMUS Chat.

set -e

PROFILE_DIR="$HOME/.mozilla/firefox/domus-chat"
URL="https://10.10.10.100"

# Rimuovi profilo esistente se corrotto
rm -rf "$PROFILE_DIR"
mkdir -p "$PROFILE_DIR/chrome"

# Abilita userChrome.css e preferenze minimi
cat > "$PROFILE_DIR/user.js" <<'EOF'
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);
user_pref("browser.tabs.drawInTitlebar", false);
user_pref("media.navigator.enabled", true);
user_pref("media.peerconnection.enabled", true);
user_pref("media.navigator.permission.disabled", true);
user_pref("media.autoplay.default", 0);
EOF

# Nascondi UI Firefox
cat > "$PROFILE_DIR/chrome/userChrome.css" <<'EOF'
#TabsToolbar,
#nav-bar,
#PersonalToolbar,
#urlbar-container,
.titlebar-buttonbox {
    visibility: collapse !important;
}
#main-window {
    background-color: #000a00 !important;
}
EOF

# Aggiungi certificato di Domus come trusted CA (C,,)
if command -v openssl >/dev/null 2>&1 && command -v certutil >/dev/null 2>&1; then
    TMP_CERT=$(mktemp)
    openssl s_client -connect "${URL#https://}":443 -servername "${URL#https://}" </dev/null 2>/dev/null \
        | openssl x509 -outform PEM > "$TMP_CERT" || true
    if [ -s "$TMP_CERT" ]; then
        certutil -N -d "$PROFILE_DIR" --empty-password 2>/dev/null || true
        certutil -A -n "domus.local" -t "C,," -i "$TMP_CERT" -d "$PROFILE_DIR" 2>/dev/null || true
    fi
    rm -f "$TMP_CERT"
fi

echo "Profilo DOMUS Chat creato in $PROFILE_DIR"
