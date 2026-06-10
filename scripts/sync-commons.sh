#!/usr/bin/env bash
# splatoon-commons (@v1) からステージマスタと画像を Resources/Commons/ に同期する。
# commons更新時に再実行してコミットする。
set -euo pipefail

BASE="https://cdn.jsdelivr.net/gh/tora-spl/splatoon-commons@v1"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEST="$ROOT/Resources/Commons"
MAP="$ROOT/IkaMachiKit/Sources/IkaMachiKit/Resources/stage-map.json"

mkdir -p "$DEST/stages"

echo "stages.json を取得..."
curl -fsSL "$BASE/data/stages.json" -o "$DEST/stages.json"

echo "ステージ画像を取得..."
for id in $(python3 -c "
import json
for e in json.load(open('$MAP')):
    if e.get('commonsId'):
        print(e['commonsId'])
"); do
  curl -fsSL "$BASE/assets/img/stages/$id.png" -o "$DEST/stages/$id.png" \
    && echo "  ✓ $id.png" \
    || echo "  ✗ $id.png (commonsに未収録)"
done

echo "完了: $DEST"
