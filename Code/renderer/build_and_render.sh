#!/usr/bin/env bash
set -euo pipefail

# Navigate to repository root (M3_Gaussian_Elimination/)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$PROJECT_ROOT"

echo "Compiling 1080p AVFoundation/CoreGraphics Motion Graphics Engine..."
clang++ -O3 -x objective-c++ -fobjc-arc \
    -framework AppKit \
    -framework Foundation \
    -framework AVFoundation \
    -framework CoreMedia \
    -framework CoreGraphics \
    -framework CoreText \
    -framework CoreVideo \
    Code/renderer/render_video.mm -o /tmp/m3_render_video

echo "Running renderer..."
/tmp/m3_render_video
rm -f /tmp/m3_render_video
echo "Done! Video saved to Video/M3_Gaussian_Elimination.mp4"
