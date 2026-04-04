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
            title: [Kursplanering Steg 1],
    
            course: [Kursledarutbildning Steg 1],
    
            datetag: [Oktober 2025],
    
            footer: [West Coast Swing Umeås kursledarprogram 2025-2026],
    )

= Kurslängd
<kurslängd>
Följande kursplanering är anpassad till en veckokurs som är 1 timme gånger 8 tillfällen. Vid längre/kortare kurser, samt helgkurser, kan innehållet behöva anpassas.

#link("step1_syllabus.pdf")[Ladda ner kursplanering som PDF]

= Mål
<mål>
Målet med en nybörjarkurs är att eleverna ska ha roligt, och vilja fortsätta dansa.

= Lärandemål
<lärandemål>
Efter avslutad kurs ska deltagarna:

- Kunna utföra grundturerna i WCS
- Starta på en downbeat
- Visa grundläggande frame
- Utföra grundläggande stretch och compression
- Våga leka till musiken

= Turer
<turer>
Följande turer passar att lära ut på en Nybörjarkurs. Beroende på antal gånger, samt hur gruppen är, kan detta behöva justeras något.

#table(
  columns: 3,
  align: (auto,auto,auto,),
  table.header([#strong[Left side];], [#strong[Middle];], [#strong[Right side];],),
  table.hline(),
  [Left side pass], [Sugar push], [Under arm],
  [Left side turn], [Sugar tuck], [Whip],
  [Free spin], [Starter step], [],
)
= Tekniska koncept
<tekniska-koncept>
Följande tekniska koncept är lämpliga att ta upp på en nybörjarkurs.

#table(
  columns: (25%, 75%),
  align: (auto,auto,),
  [Frame], [Håll axlarna på plats. Avslappnad biceps],
  [Stretch], [Simplifierad: se till att följarna alltid backar bakåt tills de får ett stopp],
  [Snurrteknik], [Spotting, prep, korta steg],
)
= Kursplanering
<kursplanering>
#block[
#callout(
body: 
[
Se till att läsa de pedagogiska ramverken som medföljer denna kursplanering, då de inte alltid kommer nämnas explicit i texten, utan alltid ska användas.

]
, 
title: 
[
Warning
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
== Tillfälle 1
<tillfälle-1>
#strong[Fokus teknik:] trippelsteg \
#strong[Fokus turer:] Under arm och Left side pass

=== Introduktion (\~5 min)
<introduktion-5-min>
Börja alltid med att introducera er själva och hälsa alla välkomna. Praktisk information såsom nödutgångar, eventuella avbrott i kursen, etc, tas upp innan ni kör igång och dansar. Fråga gärna vilka som testat West Coast Swing tidigare, och berätta kort att dansen har sitt ursprung i Lindy Hop.

=== Grundstegen och förning (\~15 min)
<grundstegen-och-förning-15-min>
Starta med att berätta att WCS inte har ett grundsteg på samma sätt som t ex. salsa eller bugg, utan att vi snarare använder ett par olika grundturer, eller en grundrytm när vi dansar.

- #strong[Gå gå trippelsteg:] Ställ upp deltagarna bakom er. Förarna börjar på vänster, och följarna på höger. En i lärarparet demonstrerar förarstegen och den andra följarstegen, låt deltagarna följa de rörelser ni demonstrerar. Börja med #strong[tap till sidan, för över vikten] på 1, 2. Ändra sedan till #strong[tap bakom, för över vikten];. Säg sedan till dem att lägga lite mer vikt på tap-steget, så att det blir 1 & 2. Se till att de inte flyttar huvudvikten över foten. Detta kommer naturligt att ge dem ett trippelsteg med partial, full, delay.

Välj en långsam låt med väldigt tydlig rytm för att träna till musik, ungefär 70-80 bpm första gången. Nästa steg är att låta deltagarna röra sig runt i rummet i samma rytm, både framåt och bakåt.

- #strong[Handfattning och kroppsförning:] När alla fått in grundrytmen är det dags för deltagarna att hitta en partner och testa tillsammans. Förklara för deltagarna att i WCS kommer förningen från att föraren och följaren är i stretch (ytterläge) och när föraren rör sig bakåt kommer följaren att följa med, inget extra drag behövs. Demonstrera "tvåfingerkroken" där föraren lägger fram händerna, och följaren lägger händerna ovanpå. Målet är att få kroken så nära in i knogleden som möjligt. När de fattat varandras händer så instruera dem att slappna av i armarna, samtidigt som de håller axlarna på plats (detta för att skydda axlarna), och backa med små korta steg tills de börjar känna connection. Härifrån tar föraren ett steg bakåt, vilket får följaren att följa med. Se till att göra high five och rotera följarna så alla får prova. Det här är grundförningen som vi kommer använda i grundkursen. Allt detta bör förklaras så förenklat som möjligt, och inte ta mer än 5 minuter, då det kommer repeteras kommande tillfällen.

=== Left side pass (\~20 min)
<left-side-pass-20-min>
Använd VPIÖ för att lära ut (gäller alla turer)

- Börja med att demonstrera turen från båda hållen
- Låt deltagarna testa turen, se till att rotera ett par gånger. Målet här är att följaren ska ta sig från en sida till nästa, och passera på förarens vänstra sida.
- Ge en mer detaljerad instruktion till turen.
  - Börja alltid med tvåfingerkroken och att backa ut i connection
  - Föraren positionerar sig något till vänster om följaren och går sedan bakåt på 1an
  - Både förare och följare måste vara avslappnade i armarna
  - Följaren kommer att gå rakt fram tills hen känner att connection får hen att rotera upp mot föraren igen.
  - Följaren är huvudsakligen ansvarig för att gå till ändläget och bygga upp stretch
- Låt deltagarna testa, både med er som räknar turen, och till slut med musik
- Monitorera gruppen för att se vad för problem som många har, och ta upp dessa saker i helgrupp, och visa hur det ska utföras
- Se till att deltagarna får många möjligheter att testa till musik

Introducera hur rotationen går till, att följaren roterar motsols (mest vanligt). High five och rotera.

=== Under arm (\~20 min)
<under-arm-20-min>
- Börja med att demonstrera turen från båda hållen
- Låt deltagarna testa turen, se till att rotera ett par gånger. Målet här är att följaren ska ta sig från en sida till nästa, och passera på förarens högra sida.
- Ge en mer detaljerad instruktion till turen.
  - Börja alltid med tvåfingerkroken och att backa ut i connection
  - Föraren positionerar sig något till höger om följaren
  - Säg åt förarna att titta på klockan, det kommer få dem att vända upp handen rätt så att följaren kan passera under
  - Både föraren och följaren måste vara avslappnade i armarna, annars kommer följaren att backa ut igen och inte gå under
  - Följare ska rotera över sin vänstra axel
- Låt deltagarna testa, både med er som räknar turen, och till slut med musik
- Monitorera gruppen för att se vad för problem som många har, och ta upp dessa saker i helgrupp, och visa hur det ska utföras
- Se till att deltagarna får många möjligheter att testa till musik
- Låt deltagarna växla mellan left side pass och under arm, där förarna väljer vilken tur som kommer

#block[
#callout(
body: 
[
Upplägget i efterföljande tillfällen är detsamma som ovan, men i texten kommer vi endast fokusera på de unika detaljerna för varje tur och koncept

]
, 
title: 
[
Warning
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
== Tillfälle 2
<tillfälle-2>
#strong[Fokus teknik:] Stretch och compression \
#strong[Fokus turer:] Sugar push

=== Repetition (\~25 min)
<repetition-25-min>
Börja med att fråga om det var några som missade förra tillfället. Om så, ge lite extra stöd till dessa under repetitionen. Repetitionen ska i princip gå igenom samma saker som under förra lektionen, men under kortare tid.

- Repetera gå-gå-trippelsteg
- Repetera handfattning och connection
- Repetera Left side pass
- Repetera Under arm

=== \[Extra\] Musikalitet i Under arm (\~10 min)
<extra-musikalitet-i-under-arm-10-min>
Beroende på grupp, kan ni redan nu börja introducera musikalitet och följarinitiativ. Förklara att WCS är en dans där vi använder mycket musikalitet och kommunikation mellan förare och följare. De kommer få lära sig en enkel variation som följaren kan ta initiativ till.

- Följaren indikerar redan på 2& att hon vill göra något, genom att ge lite mer connection
- Visa några enkla varianter som följaren kan göra för att förlänga 3&4 med 2-4 taktslag
- Föraren väntar in följaren, eller följer med hen om det behövs. Med väntar menar vi att föraren tar steg på stället för att hålla takten.
- Följaren ansvarar för att avsluta turen korrekt
- Se till att rotera ofta och spela olika typer av musik så de får testa

=== Övning: Pass the follower (\~10 min)
<övning-pass-the-follower-10-min>
I denna övning får följarna träna på att fortsätta sitt momentum, medans förarna får träna på att dirigera om följarens energi. Den här övningen är bra för att träna på stretch och compression. Visa övningen först, dela sedan in deltagarna i mindre grupper så de kan testa själva.

- Föraren ger följaren en riktning genom att försiktigt föra följarens överkropp. Observera att här dansar vi inte, och vi har ingen connection.
- Följaren börjar gå i den riktning hen får energin, och slutar inte gå förrän hen blir omdirigerad. Ibland kan det innebära att följaren gå in i någon, eller går in i en vägg, då måste föraren hämta upp hen och börja om.
- Det är förarens uppgift att omdirigera följaren. Är ni flera i en grupp så kan den som står i följarens väg omdirigera.

Följaren får här lära sig att gå tills det tar stopp, och inte stanna själva, och föraren får lära sig att de måste omdirigera följarens energi (föra).

Efter övningen, låt deltagarna testa Under arm och Left side pass.

=== Sugar push (\~15 min)
<sugar-push-15-min>
- Demonstrera en Sugar push och låt deltagarna testa.
- Ge en mer detaljerad instruktion till turen.
  - Compression: följaren fortsätter rörelsen framåt, tills föraren fångar upp rörelsen och för tillbaka hen
  - Föraren absorberar normalt mest av compressionen, men följaren kan också absorbera om nödvändigt
  - Viktigt att föraren inte pushar ut följaren med armarna, utan använder kroppen för att föra ut från compressionen
- Låt deltagarna träna på turen, och lägg även in de andra turerna de redan kan

== Tillfälle 3
<tillfälle-3>
#strong[Fokus teknik:] Grundläggande snurrteknik \
#strong[Fokus turer:] Left side turn

=== Uppvärmning (\~5 min)
<uppvärmning-5-min>
Lägg in en kort solouppvärmning till musik, där ni dansar:

- Gå gå steg
- Tap steg
- Trippelsteg

Lägg även in några nya steg, några förslag:

- Slides
- Grapevines
- Hitches
- Shoulder rolls / Head rolls / Hip rolls

Syftet är, förutom att de ska bli uppvärmda, att repetera trippelsteg och testa på lite andra stegkombinationer. Håll det enkelt dock.

=== Repetition (\~20 min)
<repetition-20-min>
Repetition av Sugar push och musikalitet i Under arm, samt övningen från förra gången. Var uppmärksam på de som ej var med på föregående tillfälle om de behöver extra hjälp. Lägg gärna in Left side pass och Under arm mellan turerna så att du kan se om det är något där som måste repeteras.

=== Snurrteknik (\~10 min)
<snurrteknik-10-min>
Då nästa tur är Left side turn så bör kursledarna gå igenom grundläggande snurrteknik.

Tekniken behövs främst för följarna, men även förarna har nytta av dessa övningar:

- Spotting: låt deltagaren fokusera blicken på en punkt rakt fram. Låt dem sakta rotera på stället tills de måste vrida huvudet för att åter kunna fokusera blicken på samma punkt
- Prep: snurra ett varv där prep från överkroppen används
- Små steg: Samma snurr som ovan där de också ska tänka på små steg i snurren, för att hålla balansen bättre

=== Left side turn (\~20 min)
<left-side-turn-20-min>
Ge en mer detaljerad instruktion till turen:

- Föraren steg är detsamma som i en vanlig Left side turn
- Prep på 1 och 2. Obs! Prepen på 1 är väldigt liten och är mest för att indikera för följaren att det kommer en annan prep. Prep på 2 ska föraren sätta handen något utanför förningslinjen
- Följaren håller tillbaka lite på 2 innan viktförflyttningen kommer
- Viktigt: följaren tar ner handen efter snurren, inte föraren. Detta för att undvika att föraren rycker ner följarens arm och det blir risk för skador
- När deltagarna tränar turen, säg till att de lägger till några andra turer emellan Left side turn, då ovana följare lätt kan bli yra av för mycket snurrande.

=== Fri dans (\~10 min)
<fri-dans-10-min>
De sista 10 minuterna kan med fördel användas för att låta deltagarna dansa fritt med de turer de lärt sig hittills. Spela musik och rotera ofta. Ser du att deltagarna har problem att starta själva, räkna in efter varje rotation.

== Tillfälle 4
<tillfälle-4>
#strong[Fokus teknik:] Frame \
#strong[Fokus turer:] Sugar tuck

=== Uppvärmning (\~5 min)
<uppvärmning-5-min-1>
Använd samma uppvärmning som tillfälle 3. Lägg gärna in en grapevine med snurr eller liknande så de får repetera snurrar. Lägg gärna in en enkel stegkombination som följarna kan använda för att styla Sugar tucken som lärs ut vid detta tillfälle.

=== Repetition (\~20 min)
<repetition-20-min-1>
Kort repetition av Sugar push + repetition av snurrteknik och Left side turn.

=== Sugar tuck (\~20 min)
<sugar-tuck-20-min>
Ge en mer detaljerad instruktion till turen:

- Förarens steg är detsamma som i en vanlig Sugar push
- Föraren placerar vänster hand upp, ungefär i höjd med följarens huvud
- Följaren måste fortfarande gå in i compressionen liknande som i Sugar push
- Viktigt: följaren tar ner handen efter rotationen, inte föraren. Detta för att undvika att föraren rycker ner följarens arm och det blir risk för skador
- Efter turen kommer handfattningen att vara "upp och ned", fråga deltagarna vilken tur de kan använda för att fixa till detta (Under arm)
- Låt deltagarna variera mellan vanlig Sugar push och Sugar tuck, för att tydliggöra att känslan och stegen är väldigt lika

=== Följarstyling i Sugar tuck (\~15 min)
<följarstyling-i-sugar-tuck-15-min>
Detta är också en styling som följare kan ta initiativ till och förlänga en tur.

- För att tydliggöra att följaren vill göra något, instruera dem att lägga vänsterhanden på förarens vänsterhand på &4, för att visa att de vill ha utrymme
- Visa en enkel förlängning av turen för följare (t ex. lägg till 2 gåsteg)
- Följaren ansvarar för att gå ut i stretch och avsluta turen

== Tillfälle 5
<tillfälle-5>
#strong[Fokus teknik:] Connection i sluten position \
#strong[Fokus turer:] Starter step

=== Uppvärmning (\~5 min)
<uppvärmning-5-min-2>
Vid det här tillfället kan ni låta deltagarna testa att dansa lite själva för att värma upp, då de nu förhoppningsvis kommer ihåg några turer de kan använda.

=== Repetition (\~20 min)
<repetition-20-min-2>
Kort repetition av Sugar push och Sugar tuck tillsammans, för att demonstrera på likheterna och skillnaderna däremellan. Repetera följarvariationen från 4an, lägg gärna in en annan enkel variation de kan göra.

=== Connectionövning (\~10 min)
<connectionövning-10-min>
Nu när deltagarna har provat på några turer, passar det att lägga in en teknikövning med mer fokus på connection. Både hand i hand och connection bak i ryggen. Viktiga detaljer att ta upp:

- Connection på ryggen: handen ska vara vinklad, inga fingrar in i ryggen
- Handen på undre delen av följarens vänstra skulderblad
- Viktigt att följaren söker connection, dock utan att luta sig bakåt då de då blir tunga

=== Starter step med Left side pass (\~25 min)
<starter-step-med-left-side-pass-25-min>
Förklara att när man börjar dansen börjar man oftast i sluten position (de kan redan ha haft frågor om detta om de sett socialdans). Då starter step är en av de mer "kontroversiella" turerna i hur den ska utföras, låter vi er själva bestämma vilken variant ni lär ut. Försök dock vara konsekventa med andra kursledare inom er förening, och var medveten om de olika varianterna.

- #strong[Tap, step:] Tap på 1 och steg på 2, ankarsteg på 3&4
- #strong[Trippelsteg:] Trippelsteg på 1&2, ankarsteg på 3&4

Alla varianter bör dock börja med att paret hittar takten först, tap, step om ni lär ut varianten med tap, step eller trippelsteg, eller step tap om ni lär ut varianten med step, tap. Låt deltagarna få in rytmen ett tag med musik för att hitta känslan, innan ni börjar med starter step.

Då detta är första gången de testar sluten position är det en del punkter som är extra viktiga. Förutom de punkter som är listade för closed connection ovan så är även följande saker viktiga att nämna:

- Se till att förarens frame följer med i starter stepet, ibland lämnar förarna kvar följarna när de själva går åt sidan
- Förklara att förningen kommer från den hand som är närmast följarens center. Vilket betyder att förarens vänsterhand inte för

Då starter step utan en utgång blir lite tråkig att träna på, lägg till en Left side pass från sluten position till öppen. Principen här är densamma som för en vanlig Left side pass, men då föraren har connection i ryggen är det därifrån förningen kommer ifrån. Ha dem gärna släppa vänsterhanden helt för att träna på förning från handen på ryggen.

== Tillfälle 6
<tillfälle-6>
#strong[Fokus teknik:] Stretch och compression \
#strong[Fokus turer:] Whip

=== Uppvärmning (\~5 min)
<uppvärmning-5-min-3>
Fri dans för deltagarna.

=== Repetition (\~20 min)
<repetition-20-min-3>
Kort repetition av Starter step och connection.

=== Stretch och compression (\~15 min)
<stretch-och-compression-15-min>
Repetera beskrivning av stretch och compression och hur det används i WCS. Låt deltagarna öva på att alltid gå till ändlägena och vänta på förning. Bra övningar:

- Pass the follower, från tillfälle 2
- Dansövning: Förarna lägger in gå-gå steg mellan turerna, så att följarna måste vänta på förning. Lägg in gå-gå steg i compressionen i Sugar push

=== Whip (\~25 min)
<whip-25-min>
Introducera deras första 8-taktstur genom att demonstrera rytmen och låta dem testa gå-gå trippelsteg gå-gå trippelsteg på stället. En Whip är en av de svårare turerna att behärska, och kommer kräva en del träning innan de får till den. Några viktiga punkter att tänka på i Whipen:

- Föraren öppnar upp sin fram något innan ettan, så att följaren får en naturlig "prep" innan steget, vilket får henne att rotera automatiskt
- Föraren bör fånga upp följarens rygg så snart som möjligt, för att kunna "släppa ut och dra in" på steg 3&4
- Följaren måste fortsätta momentum bakåt tills hen får en redirect
- På steg 4 ska följaren ha höger fot fram, men inte än ha lagt över vikten, vikten kommer på &et efteråt
- Förare ska inte heller ha lagt över vikten på 4an, utan viktförflyttningen sker på &et efteråt. Många förare är alldeles för snabba att lägga över vikten, och kan då inte längre föra ut följaren ordentligt
- Stanna på 4an ett par gånger för att inspektera positionerna som förare och följare har
- Så fort handen connectar med ryggen så är det den förningspunkt som gäller, då den är närmare följarens center, den andra handen för ej ut, utan rotationen och förningen ut kommer från förarens rotation och frame
- Förare har en tendens att pusha ut följaren på 5&6 med sin vänsterarm. För att undervika detta kan deltagarna träna på att släppa den andra handen så fort de connectat i ryggen

== Tillfälle 7
<tillfälle-7>
#strong[Fokus teknik:] Adaption av connection \
#strong[Fokus turer:] Handbyten och Freespin

=== Uppvärmning (\~5 min)
<uppvärmning-5-min-4>
Fri dans för deltagarna.

=== Repetition (\~25 min)
<repetition-25-min-1>
Repetition av Whip och connection. Ta gärna lite extra tid att repetera detta, då Whipen är ganska svår att få in, och deltagarna ofta har många frågor.

=== Handbyten och grundturer i olika handfattningar (\~15 min)
<handbyten-och-grundturer-i-olika-handfattningar-15-min>
Då deltagarna redan kan en hel del grundturer vid det här laget, passar det här att lägga in handbyten. Visa några enkla handbyten, till exempel i Under arm (höger i höger), Left side pass (höger i höger), och Sugar push (höger i vänster). Låt deltagarna själva testa på grundturerna i olika handfattningar först, för att sedan gå igenom om de har några tankar kring hur väl de olika turerna fungerar i olika handfattningar.

=== Freespin (\~15 min)
<freespin-15-min>
Låt deltagarna göra en Sugar push med handbyte, så de hamnar höger i vänster. Viktiga punkter att tänka på i Freespin är:

- Förarens och följarens steg är desamma som i en vanlig Left side turn
- Föraren höjer inte armen för att signalera att följaren ska gå under, utan håller handen låg, för att sedan släppa efter preppen på 2

Många gånger är Freespin höger i vänster lättare att göra för deltagarna än en Left side turn, då både föraren och följaren får lite mer utrymme då handfattningen är annorlunda.

== Tillfälle 8
<tillfälle-8>
- Repetition av turer, antingen alla turer individuellt eller genom en slinga

=== Slinga av alla turer
<slinga-av-alla-turer>
Nedan följer en variant av en slinga på 2x32 slag, som kan varieras utefter behov. Då de aldrig kommer att komma ihåg hela slingan är det viktigt att ni som kursledare hela tiden ropar ut vilken tur som kommer härnäst.

#table(
  columns: (25.93%, 33.33%, 40.74%),
  align: (auto,auto,auto,),
  table.header([Takt], [Tur], [Kommentar],),
  table.hline(),
  [1-4], [Starter step], [],
  [5-10], [Left side pass], [],
  [11-16], [Under arm], [Lägg gärna in följarstylingen på 3&4],
  [17-22], [Sugar push], [Miniphrase change, möjlighet till styling],
  [23-28], [Left side turn], [],
  [29-32], [Start av Tuck turn], [Phrase change kommer på 5an],
  [1-6], [Fortsätt Tuck turn], [Förläng turen med 4 slag, följarstyling],
  [7-12], [Free spin], [],
  [13-20], [Whip], [Miniphrase change, lägg eventuellt in en slide på 5an],
  [21-26], [Left side pass in i sluten], [],
  [27-32], [Left side pass ut ur sluten], [],
  [Eventuellt ta nästa phrase change], [], [],
)




