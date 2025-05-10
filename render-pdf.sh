#!/bin/bash
set -euo pipefail

echo "Rendering changed slides:"
for file in material/*.qmd; do
  echo " - $file"
  quarto render "$file"
done

echo "Rendering HTML slides to PDF..."
for f in material/*.qmd; do
  base=$(basename "$f" .qmd)
  html="_site/material/$base.html"
  pdf="_site/material/$base.pdf"

  if [ -f "$html" ]; then
    echo "Generating PDF for $html"
    docker run --rm -t \
      -v "$(pwd)":/slides \
      ghcr.io/astefanutti/decktape \
      "$html" "$pdf"
  else
    echo "Skipping: $html not found"
  fi
done

