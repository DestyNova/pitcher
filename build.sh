#!/usr/bin/env bash

set -euo pipefail

mkdir -p public
cp -r static/* public

elm make src/Main.elm --output public/app.js
uglifyjs public/app.js -o public/app.min.js
