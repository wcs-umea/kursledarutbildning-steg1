#!/usr/bin/env python3

import sys
from pathlib import Path
from pypdf import PdfReader, PdfWriter

def reorder_for_pdfjam(input_pdf: str, output_pdf: str) -> None:
    reader = PdfReader(input_pdf)
    writer = PdfWriter()

    n = len(reader.pages)

    for start in range(0, n, 4):
        block = list(range(start, min(start + 4, n)))

        if len(block) == 4:
            # original block: [0,1,2,3] => [1,3,0,2]
            # i.e. page order 2,4,1,3
            reordered = [block[1], block[3], block[0], block[2]]
        else:
            reordered = block

        for i in reordered:
            writer.add_page(reader.pages[i])

    with open(output_pdf, "wb") as f:
        writer.write(f)

def main():
    if len(sys.argv) != 3:
        print("Usage: reorder_slides.py input.pdf output.pdf")
        sys.exit(1)

    input_pdf = sys.argv[1]
    output_pdf = sys.argv[2]

    if not Path(input_pdf).exists():
        print(f"Input file not found: {input_pdf}")
        sys.exit(1)

    reorder_for_pdfjam(input_pdf, output_pdf)
    print(f"Wrote reordered PDF to: {output_pdf}")

if __name__ == "__main__":
    main()