#!/usr/bin/env bash
# Builds the download page into _site/: fills the placeholders in index.html,
# copies the app logo and draws the QR code for the APK link.
#
# Used by release-apk.yml (after every release) and pages.yml (when only the
# page changed), so both publish the same page.
#
# Needs the pure-Python qrcode package (pip install qrcode) and:
#   VERSION       release version, e.g. 1.0.0
#   DATE          release date as shown on the page, e.g. 2026-11-05
#   DOWNLOAD_URL  link to the newest APK
set -euo pipefail
: "${VERSION:?}" "${DATE:?}" "${DOWNLOAD_URL:?}"

mkdir -p _site
cp .github/pages/index.html _site/index.html
cp assets/icon/logo.png _site/logo.png

python3 -c 'import sys, qrcode, qrcode.image.svg as svg; qrcode.make(sys.argv[1], image_factory=svg.SvgPathImage, box_size=10, border=2).save(sys.argv[2])' \
  "$DOWNLOAD_URL" _site/qr.svg

sed -i \
  -e "s|__DOWNLOAD_URL__|$DOWNLOAD_URL|g" \
  -e "s|__VERSION__|$VERSION|g" \
  -e "s|__DATE__|$DATE|g" \
  _site/index.html

if grep -q '__[A-Z_]*__' _site/index.html; then
  echo "::error::Unfilled placeholder in index.html"
  exit 1
fi
