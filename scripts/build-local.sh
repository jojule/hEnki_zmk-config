#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
# Official ARM64 image with Zephyr SDK 0.16.9, also used by the Corne config.
image='zmkfirmware/zmk-dev-arm:4.1-branch@sha256:77b62cbc6c62ca0026ed9eb511dd7fc2a13692d1b9ddbaf92bca510612390db8'
mkdir -p "$repo_dir/.local-build"

docker run --rm -i --platform linux/arm64 \
  --mount "type=bind,source=$repo_dir,target=/workspace" \
  --workdir /workspace/.local-build \
  --entrypoint /bin/bash "$image" -s 2>&1 <<'BUILD' | tee "$repo_dir/.local-build/build.log"
set -euo pipefail
mkdir -p config
cp /workspace/config/west.yml config/west.yml
if [ ! -f .west/config ]; then
  west init -l config
fi
west update --narrow -o=--depth=1
west zephyr-export

python3 - <<'PY' > targets.tsv
import yaml
with open('/workspace/build.yaml') as source:
    for target in yaml.safe_load(source)['include']:
        print(target['board'], target['shield'], sep='\t')
PY

while IFS=$'\t' read -r board shield; do
  west build -p always -s zmk/app -d "build/$shield" -b "$board" -- \
    -DZMK_CONFIG=/workspace/config -DZMK_EXTRA_MODULES=/workspace -DSHIELD="$shield"
done < targets.tsv

# Refresh firmware only after both halves build successfully.
mkdir -p /workspace/firmware
while IFS=$'\t' read -r board shield; do
  cp "build/$shield/zephyr/zmk.uf2" "/workspace/firmware/$shield.uf2"
done < targets.tsv
west manifest --freeze --active-only > /workspace/firmware/west-manifest.yml
git -C zmk rev-parse HEAD > /workspace/firmware/zmk-revision.txt
cd /workspace
find config boards zephyr -type f -print0 | sort -z | \
  xargs -0 sha256sum > firmware/source-SHA256SUMS
sha256sum build.yaml scripts/build-local.sh >> firmware/source-SHA256SUMS
cd /workspace/firmware
sha256sum ./*.uf2 > SHA256SUMS
cat SHA256SUMS
BUILD

printf '\nFirmware: %s/firmware\nBuild log: %s/.local-build/build.log\n' "$repo_dir" "$repo_dir"
