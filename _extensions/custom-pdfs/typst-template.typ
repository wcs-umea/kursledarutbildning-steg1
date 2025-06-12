
#set text(fill: rgb("#444444"))
#set par(leading: 0.7em)
#set block(spacing: 1.4em)


#set table(
  gutter: 0.0em,
  stroke: rgb("C0C0C0"),
  inset: (right: 1.5em, top: 0.5em, bottom: 0.5em),
)



#let custom-pdfs(
  course: none,
  title: none,
  datetag: none,
  footer: none,

  body

) = {
  // create the first page
  set align(center)
  image("img/wcsumea-logo-black.svg", width: 50%)
  v(100pt)
  text(size: 4em, weight: "bold", title)
  v(20pt)
  text(size: 2.5em, weight: "bold", datetag)
  v(100pt)
  text(size: 1.5em, weight: "bold", course)
  pagebreak()

  // set the toc and formatting
  show heading.where(level: 1): set text(fill: rgb("#621273"))
  show heading.where(level: 1): set text(top-edge: "ascender")

  show heading: set heading(numbering: "1.")
  outline(title: "Innehållsförteckning", depth: 2)

  show heading: set block(above: 2em)

  set align(left)

  // body font
  set text(12.5pt)


  set page(
    margin: (left: 2.5cm, right: 2.5cm, top: 2.5cm, bottom: 3cm),

    footer: {
      set text(8pt)
      set par(leading: 0.5em)
      set block(spacing: 1em)
      set par(justify: true)
      footer
      set text(6pt)
    }
  )



  // underline links.
  show link: underline

  // page body
  grid(
    columns: 1fr,
    row-gutter: 20pt,
    

    // body flow
    {
      set par(justify: true)
      body
    }

  )
}