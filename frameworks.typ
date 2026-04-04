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

#set page(
  paper: "us-letter",
  margin: (x: 1.25in, y: 1.25in),
  numbering: "1",
)

#show: custom-pdfs.with(
            title: [Ramverk],
    
            course: [Kursledarutbildning Steg 1],
    
            datetag: [Oktober 2025],
    
            footer: [West Coast Swing Umeås kursledarprogram 2025-2026],
    )

= Vad är ett ramverk?
<vad-är-ett-ramverk>
Med ramverk menar vi små eller stora strukturer som kan användas för att planera/genomföra en kurs/kurstillfälle. Tanken med ett ramverk är att man använder en beprövad struktur, som i sin tur bygger på en pedagogisk princip.

#link("frameworks.pdf")[Ladda ner som PDF]

== Pedagogiska ramverk
<pedagogiska-ramverk>
==== Visa, Pröva, Instruera, Öva
<visa-pröva-instruera-öva>
Detta ramverk bygger på de pedagogiska principerna för hur personer lär. Inom dans har detta utvecklats till Visa, Pröva, Instruera, Öva. Ett ramverk som kan användas för att lära ut turer, se exemplet nedan med en Left side pass.

- #strong[Visa:] Instruktörerna börjar med att visa turen för kursdeltagarna. Kom ihåg att visa från både hållen. Räkna medan ni utför turen, både 1 2 3&4 5&6, samt gå gå trippelsteg trippelsteg. Nämn att en Left side pass ska följaren passera på förarens vänstra sida. Men inte mer information än så.

- #strong[Pröva:] Låt deltagarna pröva turen själva, med intruktörerna som räknar in dem. Rotera ett par gånger så att alla får pröva. Målet är att följaren ska ta sig från en sida till den andra, och passera föraren på rätt sida.

- #strong[Instruera:] När deltagarna har fått in de ungefärliga riktningarna i kroppen kan ni som instruktörer gå igenom turen mer i detalj, och vilka tekniska detaljer som är viktiga.

- #strong[Öva:] Nu får deltagarna tid att öva in turen med de extra detaljerna. Här kan ni också lägga till musik och räkna in deltagarna. Rotera ofta och ge ordentligt med tid att träna och ställa frågor.

==== Upplägg av kurstillfälle
<upplägg-av-kurstillfälle>
Det finns flera sätt att strukturera ett kurstillfälle, men nedan följer ett simplet koncept som är en bra utgångspunkt:

- Repetition av föregående tillfälle
- Tekniskt koncept
- Tur som kräver det tekniska konceptet

Exempel:

- Repetera föregående tillfälles tur: Left side pass
- Tekniskt koncept: snurrteknik (prep, spotting, korta steg)
- Tur som kräver det tekniska konceptet: Left side turn

==== Uppvärmning i grupp
<uppvärmning-i-grupp>
Gå gå trippelsteg

==== Frågor och feedback
<frågor-och-feedback>
Fråga deltagarna efter varje genomgång om de har frågor. Om det är relevant för många i gruppen så gå igenom det i helklass. Är det en fråga som ni bedömmer bara är relevant för deltagaren som frågar, så gå till dem och ge dem feedback så fort ni får möjlighet.

Monitorera gruppen när de tränar, ser ni något som bör tas i helgrupp så säg vad ni såg, och hur ni vill att det ska se ut i stället. Försök att inte lägga någon värdering bakom det ni såg, säg till exempel inte att det såg dåligt ut, utan snarare att det är saker som saknas, och varför något är viktigt att göra.

==== Feedback mellan kursdeltagare
<feedback-mellan-kursdeltagare>
Frågan om feedback till sina kurskamrater är alltid känslig, men generellt är det bra att uppmana sina deltagare att INTE ge oombedd feedback till sin partner. Man kan själv be om feedback, till exempel fråga sin partner hur det känns när man själv gör turen, men har de frågor eller funderingar om de gör rätt är de bättre att de frågar kursledarna. Var tydig med detta i början av kursen, samt påminn dem de första gångerna om detta.

== Strukturramverk
<strukturramverk>
==== Rotation och placering
<rotation-och-placering>
- Börja alla turer med alla förare med ansiktet åt samma håll, det kommer underlätta för er som lärare att se om det är några problem med en tur
- Rotera följare motsols (eller medsols, de flesta roterar dock motsols)
- Placera ut extra följare jämnt så att det inte blir 2 ensamma följare på rad
- Säg "high five och rotera" vid varje rotation, det går deltagarna en chans att ha en mini-interaktion med varandra
- Rotera efter deltagarna har fått prova en sak 1-2 gånger med sin partner. Har ni extra följare så måste de få testa allt i minst 2 rotationer så alla får chans att testa.

==== Räkning och taktning
<räkning-och-taktning>
- Börja på "fel fot" för att lägga över vikten på 8 vid inräkning. Förklara varför ni gör detta
- Räkna in 5,6,7,8. Försök börja inräkningen så det timar med musikens 5,6,7,8
- Växla mellan att ibland räkna turer med siffror och ibland med gå gå trippelsteg
- Annonsera nästkommande tur på sista 5&6 i en tur så förarna har en chans att förbereda sig om ni har en given sekvens ni vill att de gör. Till exempel: 1 2 3&4 under arm

==== Lärarledd eller fri övning
<lärarledd-eller-fri-övning>
Nedan följer olika sätt att ge sina kursdeltagare en struktur för att träna turer. När en tur först lärs ut så passar det lärarledda sättet. Vartefter gruppen förstår turen bättre och bättre kan man gå nedåt i listan, och avsluta med att låta paret dansa själv utan guidning.

#strong[Lärarledd:] Läraren räknar in och hela gruppen gör turen tillsammans.

#strong[Lärarledd start:] Läraren räknar in och hela gruppen gör turen tillsammans. Efter det fortsätter gruppen dansa, och förarna för turen själva, uppblandat med grundsteg.

#strong[Halvfri:] Föraren får 2 turer att alternera mellan, men väljer själv vilken tur som förs. Räknas oftast in av kursledaren.

#strong[Fritt:] Föraren väljer fritt vilka turer som dansas. Kursledaren kan dock instruerera att fokusera på en specifik tur.
