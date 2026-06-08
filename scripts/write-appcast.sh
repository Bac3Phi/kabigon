#!/usr/bin/env bash
# Writes the Sparkle appcast for the current release ZIP.
set -euo pipefail

cd "$(dirname "$0")/.."

VERSION="${1:?usage: scripts/write-appcast.sh <version> <asset-path>}"
ASSET="${2:?usage: scripts/write-appcast.sh <version> <asset-path>}"
SIGN_UPDATE="${SIGN_UPDATE:-}"

if [ -z "$SIGN_UPDATE" ]; then
    SIGN_UPDATE="$(find .build/artifacts -name sign_update -path '*Sparkle*' 2>/dev/null | head -1)"
fi

if [ -z "$SIGN_UPDATE" ] || [ ! -x "$SIGN_UPDATE" ]; then
    echo "error: Sparkle sign_update tool not found" >&2
    exit 1
fi

if [ -n "${SPARKLE_ED_PRIVATE_KEY:-}" ]; then
    ED_ATTRS="$(printf '%s' "$SPARKLE_ED_PRIVATE_KEY" | "$SIGN_UPDATE" --ed-key-file - "$ASSET")"
else
    ED_ATTRS="$("$SIGN_UPDATE" "$ASSET")"
fi

mkdir -p docs
cat > docs/appcast.xml <<EOF
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0"
     xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle"
     xmlns:dc="http://purl.org/dc/elements/1.1/">
    <channel>
        <title>Kabigon Updates</title>
        <link>https://github.com/Bac3Phi/kabigon/releases</link>
        <description>Release feed for Kabigon.</description>
        <language>en</language>
        <item>
            <title>Kabigon $VERSION</title>
            <sparkle:version>$VERSION</sparkle:version>
            <sparkle:shortVersionString>$VERSION</sparkle:shortVersionString>
            <sparkle:minimumSystemVersion>13.0</sparkle:minimumSystemVersion>
            <enclosure url="https://github.com/Bac3Phi/kabigon/releases/download/v$VERSION/Kabigon-$VERSION.zip"
                       $ED_ATTRS type="application/zip" />
        </item>
    </channel>
</rss>
EOF

echo "Wrote docs/appcast.xml for Kabigon $VERSION"
