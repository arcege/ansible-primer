#!/bin/bash

mkdir -p docs
python -m markdown < README.md > docs/index.html

for mdfile in [0-9]*-*/README.md; do
    name=$(dirname "${mdfile}")
    python -m markdown < "${mdfile}" > "docs/${name}.html"
done

echo "Open browser to file://$PWD/docs"
