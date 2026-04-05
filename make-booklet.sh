#!/usr/bin/env bash
set -euo pipefail

#echo "Rendering HTML slides to PDF..."
#for f in material/*.qmd; do
#  base=$(basename "$f" .qmd)
#  html="_site/material/$base.html"
#  pdf="booklet-pdfs/presentations/$base.pdf"

#  if [ -f "$html" ]; then
#    echo "Generating PDF for $html"
#    docker run --rm -t \
#      -v "$(pwd)":/slides \
#      ghcr.io/astefanutti/decktape \
#      reveal \
#      "$html" "$pdf" --fragments=false
#  else
#    echo "Skipping: $html not found"
#  fi
#done


# Combine them
LIST=( "booklet-pdfs/presentations/patterns.pdf" 
       "booklet-pdfs/presentations/frameworks.pdf" 
       "booklet-pdfs/presentations/safe_environment.pdf"
       "booklet-pdfs/presentations/music.pdf"
)
pdfunite "${LIST[@]}" "booklet-pdfs/presentations/presentations.pdf"

# Re-order them
python3 booklet-pdfs/reorder_slides.py \
        booklet-pdfs/presentations/presentations.pdf \
        booklet-pdfs/presentations/presentations_reordered.pdf

# Make 4 slides per page
echo "Making 4 slides per page"
pdfjam booklet-pdfs/presentations/presentations_reordered.pdf \
       --nup 2x2 \
       --paper a4paper \
       --angle 90 \
       --delta "1cm 1cm" \
       --outfile booklet-pdfs/presentations/presentations_final.pdf

# Build list of inputs
INPUTS=( "_site/booklet-pdfs/cover-page.pdf" 
         "booklet-pdfs/blank.pdf"  
         "booklet-pdfs/step1_syllabus.pdf" 
         "booklet-pdfs/try-out.pdf" 
         "booklet-pdfs/blank.pdf"  
         "booklet-pdfs/frameworks.pdf"
         "booklet-pdfs/blank.pdf"  
         "booklet-pdfs/presentations/presentations_final.pdf"
         "booklet-pdfs/blank.pdf"
         )

# # Use pdfunite (part of poppler) for simple concatenation
# # Alternative: call ghostscript, pypdf, etc.
pdfunite "${INPUTS[@]}" "booklet-pdfs/booklet_step1.pdf"

echo "Booklet PDF generated"
