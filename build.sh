#!/usr/bin/env bash

set -euo pipefail

mkdir -p public
cp -r static/* public

# incremental piano
echo "Building IncrementalPiano..."
elm make src/IncrementalPiano.elm --output public/IncrementalPiano.js
uglifyjs public/IncrementalPiano.js -o public/IncrementalPiano.min.js

# quick pitch
echo "Building QuickPitch..."
elm make src/QuickPitch.elm --output public/QuickPitch.js
uglifyjs public/QuickPitch.js -o public/QuickPitch.min.js

# pitch test
echo "Building PitchTest..."
elm make src/PitchTest.elm --output public/PitchTest.js
uglifyjs public/PitchTest.js -o public/PitchTest.min.js
