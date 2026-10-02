#!/usr/bin/env bash
set -euo pipefail

if [[ "${1:-}" != "--confirm" ]]; then
  echo "BLOCKED: pass --confirm only after explicit user approval to create a QA archive." >&2
  exit 2
fi

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../../.." && pwd)"
cd "$repo_root"

archive_path="${2:-$HOME/Library/Developer/Xcode/Archives/$(date +%F)/Renit-QA.xcarchive}"
"$(dirname "${BASH_SOURCE[0]}")/inspect-ios-release.sh"

EXPO_PUBLIC_APP_ENV=QA \
EXPO_PUBLIC_QA_API_HOST=qa-api.toratora.site \
xcodebuild \
  -workspace ios/Renit.xcworkspace \
  -scheme Renit \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath "$archive_path" \
  clean archive

echo "ARCHIVED: $archive_path"
