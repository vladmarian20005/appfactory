#!/usr/bin/env bash
# Scaffold a new app from the template.
#   factory/tools/new-app.sh <slug> "<Display Name>" [bundle-id]
set -euo pipefail
slug=${1:?slug}; name=${2:?display name}; bundle=${3:-com.factory.$slug}
root=$(cd "$(dirname "$0")/.." && pwd)
dest="$root/apps/$slug/ios"
[ -e "$dest" ] && { echo "$dest already exists"; exit 1; }
target=$(echo "$name" | tr -cd '[:alnum:]')
mkdir -p "$root/apps/$slug"
cp -R "$root/template" "$dest"
rm -rf "$dest/.build" "$dest"/*.xcodeproj
for f in "$dest/project.yml" "$dest/App/"*.swift "$dest/App/Products.storekit"; do
  sed -i '' "s/TemplateApp/$target/g; s/com\.factory\.templateapp/$bundle/g; s/templateapp/$slug/g" "$f"
done
sed -i '' "s|INFOPLIST_KEY_CFBundleDisplayName: $target|INFOPLIST_KEY_CFBundleDisplayName: \"$name\"|; s|path: ../FactoryKit|path: ../../../FactoryKit|" "$dest/project.yml"
sed -i '' "s/name: \"$target\"/name: \"$name\"/" "$dest/App/AppInfo.swift"
mv "$dest/App/TemplateApp.swift" "$dest/App/$target.swift"
(cd "$dest" && xcodegen generate -q)
echo "Created $dest (target $target, bundle $bundle)"
