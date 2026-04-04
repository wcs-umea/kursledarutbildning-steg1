// Some definitions presupposed by pandoc's typst output.
#let blockquote(body) = [
  #set text( size: 0.92em )
  #block(inset: (left: 1.5em, top: 0.2em, bottom: 0.2em))[#body]
]

#let horizontalrule = line(start: (25%,0%), end: (75%,0%))

#let endnote(num, contents) = [
  #stack(dir: ltr, spacing: 3pt, super[#num], contents)
]

#show terms: it => {
  it.children
    .map(child => [
      #strong[#child.term]
      #block(inset: (left: 1.5em, top: -0.4em))[#child.description]
      ])
    .join()
}

// Some quarto-specific definitions.

#show raw.where(block: true): set block(
    fill: luma(230),
    width: 100%,
    inset: 8pt,
    radius: 2pt
  )

#let block_with_new_content(old_block, new_content) = {
  let d = (:)
  let fields = old_block.fields()
  fields.remove("body")
  if fields.at("below", default: none) != none {
    // TODO: this is a hack because below is a "synthesized element"
    // according to the experts in the typst discord...
    fields.below = fields.below.abs
  }
  return block.with(..fields)(new_content)
}

#let empty(v) = {
  if type(v) == str {
    // two dollar signs here because we're technically inside
    // a Pandoc template :grimace:
    v.matches(regex("^\\s*$")).at(0, default: none) != none
  } else if type(v) == content {
    if v.at("text", default: none) != none {
      return empty(v.text)
    }
    for child in v.at("children", default: ()) {
      if not empty(child) {
        return false
      }
    }
    return true
  }

}

// Subfloats
// This is a technique that we adapted from https://github.com/tingerrr/subpar/
#let quartosubfloatcounter = counter("quartosubfloatcounter")

#let quarto_super(
  kind: str,
  caption: none,
  label: none,
  supplement: str,
  position: none,
  subrefnumbering: "1a",
  subcapnumbering: "(a)",
  body,
) = {
  context {
    let figcounter = counter(figure.where(kind: kind))
    let n-super = figcounter.get().first() + 1
    set figure.caption(position: position)
    [#figure(
      kind: kind,
      supplement: supplement,
      caption: caption,
      {
        show figure.where(kind: kind): set figure(numbering: _ => numbering(subrefnumbering, n-super, quartosubfloatcounter.get().first() + 1))
        show figure.where(kind: kind): set figure.caption(position: position)

        show figure: it => {
          let num = numbering(subcapnumbering, n-super, quartosubfloatcounter.get().first() + 1)
          show figure.caption: it => {
            num.slice(2) // I don't understand why the numbering contains output that it really shouldn't, but this fixes it shrug?
            [ ]
            it.body
          }

          quartosubfloatcounter.step()
          it
          counter(figure.where(kind: it.kind)).update(n => n - 1)
        }

        quartosubfloatcounter.update(0)
        body
      }
    )#label]
  }
}

// callout rendering
// this is a figure show rule because callouts are crossreferenceable
#show figure: it => {
  if type(it.kind) != str {
    return it
  }
  let kind_match = it.kind.matches(regex("^quarto-callout-(.*)")).at(0, default: none)
  if kind_match == none {
    return it
  }
  let kind = kind_match.captures.at(0, default: "other")
  kind = upper(kind.first()) + kind.slice(1)
  // now we pull apart the callout and reassemble it with the crossref name and counter

  // when we cleanup pandoc's emitted code to avoid spaces this will have to change
  let old_callout = it.body.children.at(1).body.children.at(1)
  let old_title_block = old_callout.body.children.at(0)
  let old_title = old_title_block.body.body.children.at(2)

  // TODO use custom separator if available
  let new_title = if empty(old_title) {
    [#kind #it.counter.display()]
  } else {
    [#kind #it.counter.display(): #old_title]
  }

  let new_title_block = block_with_new_content(
    old_title_block, 
    block_with_new_content(
      old_title_block.body, 
      old_title_block.body.body.children.at(0) +
      old_title_block.body.body.children.at(1) +
      new_title))

  block_with_new_content(old_callout,
    block(below: 0pt, new_title_block) +
    old_callout.body.children.at(1))
}

// 2023-10-09: #fa-icon("fa-info") is not working, so we'll eval "#fa-info()" instead
#let callout(body: [], title: "Callout", background_color: rgb("#dddddd"), icon: none, icon_color: black, body_background_color: white) = {
  block(
    breakable: false, 
    fill: background_color, 
    stroke: (paint: icon_color, thickness: 0.5pt, cap: "round"), 
    width: 100%, 
    radius: 2pt,
    block(
      inset: 1pt,
      width: 100%, 
      below: 0pt, 
      block(
        fill: background_color, 
        width: 100%, 
        inset: 8pt)[#text(icon_color, weight: 900)[#icon] #title]) +
      if(body != []){
        block(
          inset: 1pt, 
          width: 100%, 
          block(fill: body_background_color, width: 100%, inset: 8pt, body))
      }
    )
}


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
#import "@preview/fontawesome:0.5.0": *

#set page(
  paper: "us-letter",
  margin: (x: 1.25in, y: 1.25in),
  numbering: "1",
)

#show: custom-pdfs.with(
            title: [Planering Prova-På],
    
            course: [Kursledarutbildning Steg 1],
    
            datetag: [Oktober 2025],
    
            footer: [West Coast Swing Umeås kursledarprogram 2025-2026],
    )

= Längd
<längd>
En Prova-På är oftast en timme lång, men detta kan givetvis variera.

#link("try-out.pdf")[Ladda ner som PDF]

= Mål
<mål>
Målet med en Prova-På lektion är alltid att de som kommer ska ha roligt och vilja komma tillbaka för att dansa mer.

Fokusera därför på att deltagarna ska ha roligt, teknik är sekundärt.

= Upplägg
<upplägg>
Det finns flera olika upplägg på en Prova-På. Nedan presenteras 2 olika varianter, men de kan såklart varieras efter tycke och smak.

== Start av Prova-På
<start-av-prova-på>
Börja med ett presentera er och var ni kommer ifrån. Berätta kort vad West Coast Swing är och var den kommer ifrån. Var tydlig med att syftet med denna Prova-På är inte att de ska lära sig turerna perfekt, utan för att få ett smakprov på vad West Coast Swing är. Berätta också att tempot kommer vara högre än på en vanlig kurs, så att de ska hinna prova på lite olika turer.

== Grundsteg / rytm
<grundsteg-rytm>
Förklara att inom WCS har vi inte ett enda grundsteg, som i till exempel bugg, men snarare grundturer, och att ni kommer testa på några olika idag. Gå igenom grundrytmen (gå gå trippelsteg) med dem. Börja med att de får gå på stället till grundrytmen (förare börjar på vänster och följare på höger). Räkna högt med dem. Välj en taktfast långsam låt (ungefär 80-85 bpm).

== Connection / förning
<connection-förning>
Välj en väldigt förenklad variant av connection och förning. Visa handfattning som en "tvåfingerkrok" där man försöker få connection närmare handflatan. Förning sker genom att ha avslappnade armar och föraren tar ett steg bakåt. Låt deltagarna testa att starta ett par gånger tillsammans, kom ihåg att rotera så alla får prova.

#block[
#callout(
body: 
[
Allt ovan bör inte ta mer än 10-15 minuter.

]
, 
title: 
[
Obs!
]
, 
background_color: 
rgb("#fcefdc")
, 
icon_color: 
rgb("#EB9113")
, 
icon: 
fa-exclamation-triangle()
, 
body_background_color: 
white
)
]
== Turer
<turer>
Följande upplägg kan ni använda för de turer ni lär ut. Kom ihåg att hålla det enkelt och inte ge lika många detaljer som en vanlig kurs. Syftet är att de ska prova på, inte kunna turerna perfekta. Demonstrera att WCS är en slotten dance som är stationär, där vi dansar på en linje. Det är lätt att deltagarna börjar röra sig cirkulärt och runt i rummet annars.

- Börja med att demonstrera turen från båda hållen
- Låt deltagarna testa turen, se till att rotera ett par gånger. Målet här är att följaren ska ta sig från startpositionen till slutpositionen
- När alla fått testa på med en partner kan ni ge några fler detaljer:
  - Börja alltid med tvåfingerkroken och att backa ut i connection
  - Föraren går rakt bakåt på 1an, och kliver sedan ur spår
  - Följaren är huvudsakligen ansvarig för att gå till ändläget och bygga upp stretch
- Låt deltagarna testa, både med er som räknar turen, och till slut med musik
- Se till att deltagarna får många möjligheter att testa till musik

=== Left side pass (\~10-15 min)
<left-side-pass-10-15-min>
- Viktigt här är att föraren kliver ur följarens slot
- Ett vanligt problem är att både föraren och följaren spänner armarna för mycket, och då inte kan passera varandra på en rak linje

=== Under arm (\~10 min)
<under-arm-10-min>
- Ge liknelsen med att föraren kollar på klockan, det skapar en öppning som följaren kan passera genom
- Även här brukar spända armar göra att följarna backar tillbaka ut, istället för att passera

=== Sugar push (\~10 min)
<sugar-push-10-min>
- Introducera compression genom liknelser. Exempelvis: fånga ett ägg och kasta tillbaka (rörelsen måste saktas in för att inte knäcka ägget)

=== Variation på Under arm (\~5 min)
<variation-på-under-arm-5-min>
Beroende på tid och grupp kan ni lägga in en variation på slutet. Berätta att WCS är en dans där följaren kan influera mycket. Här kan följaren lägga in en förlängning på 3&4 i Under arm. Visa en eller två olika varianter som följaren kan testa. Följaren visar detta genom att öka connection innan 3. Föraren väntar på följaren tills hen är färdig.

== Fri dans (\~5-10 min)
<fri-dans-5-10-min>
Sista minuterna bör ni låta deltagarna dansa fritt och rotera ofta, för att avsluta med mycket dans.
