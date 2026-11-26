#!/bin/sh
# Fails when line coverage of Sources/ drops below the given percentage.
# Run after `swift test --enable-code-coverage`. Usage: scripts/check-coverage.sh 94
set -eu

minimum="${1:?usage: $0 <minimum-percent>}"
report="$(swift test --show-codecov-path)"

python3 -I - "$report" "$minimum" <<'PY'
import json
import sys

report, minimum = sys.argv[1], float(sys.argv[2])
files = json.load(open(report))["data"][0]["files"]
lines = [f["summary"]["lines"] for f in files if "/Sources/" in f["filename"]]
covered = sum(line["covered"] for line in lines)
total = sum(line["count"] for line in lines)
percent = 100 * covered / total
print(f"Sources line coverage: {percent:.1f}% ({covered}/{total}), minimum {minimum:g}%")
sys.exit(0 if percent >= minimum else 1)
PY
