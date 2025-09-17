#import "@preview/mantys:1.0.2": *
#import "@preview/codly:1.3.0": *
#import "@preview/codly-languages:0.1.1": *
#import "orly-modified.typ" as orly-modified

#show: mantys(
  name: "flux-book",
  version: "1.0.0",
  authors: (
    "Ranjit Jhala",
  ),
  license: "MIT",
  description: "Programming Rust with Refinement Types",
  repository: "https://github.com/jneug/typst-mantys",

  /// Uncomment one of the following lines to load the above
  /// package information directly from the typst.toml file
  // ..toml("../typst.toml")
  // ..toml("typst.toml"),

  theme: orly-modified,
  theme-options: (
    title-image: image("img/flux.png", height: auto),
  ),
  wrap-snippets: true,
  title: "Verify Rust with Flux",
  subtitle: "Programming Rust with Refinement Types",
  date: datetime.today(),
  url: "https://flux-rs.github.io",
  abstract: [
    #lorem(50)
  ],
)

// Set global heading numbering to use arabic numbers
#set heading(numbering: "1.1")

// // Special handling for Index heading - no numbering
// #show heading: it => {
//   if it.body == [Index] {
//     // Remove numbering for Index heading
//     set heading(numbering: none)
//     it
//   } else {
//     // Use default numbering for other headings
//     it
//   }
// }

// Reset figure counter for each chapter
#show heading.where(level: 1): it => {
  counter(figure).update(0)
  it
}

// Style figure captions with chapter-based numbering
#show figure: it => {
  let chapter-num = counter(heading).get().first()
  let fig-num = counter(figure).get().first()

  block[
    #it.body
    #align(center)[
      *Figure #chapter-num.#fig-num:* #it.caption.body
    ]
  ]
}

// Enable and style references with chapter-based figure numbering
#show ref: it => {
  let el = it.element
  if el != none and el.func() == figure {
    // Get the chapter number at the figure's location
    let chapter-num = counter(heading).at(el.location()).first()
    // Get the figure number within that chapter
    let fig-num = counter(figure).at(el.location()).first()
    // Display as "Chapter.Figure" (e.g., "2.1")
    link(el.location())[Figure #chapter-num.#fig-num]
  } else {
    // Default reference
    it
  }
}

// Render flux blocks also as rust
#show raw.where(lang: "flux"): it => {
  set text(size: 1.2em)
  raw(it.text, lang: "rust", block: it.block)
}

// Render flux blocks also as rust
#show raw.where(lang: "flux"): it => {
  set text(size: 1.2em)
  raw(it.text, lang: "rust", block: it.block)
}

// Hide fluxhidden blocks completely
#show raw.where(lang: "fluxhidden"): it => {
  // Return nothing to hide the block completely
  []
}

// Style quotes: italics, centered, 80% width
#show quote: it => {
  align(left)[
    #v(-1.0em)  // Reduce whitespace above the quote
    #block(
      width: 95%,
      inset: 1em,
      [#set text(style: "italic")
       #it.body]
    )
    #v(-1.0em)  // Reduce whitespace above the quote
  ]
}


// Add 1em vertical space after level 1 headings (chapters)
#show heading.where(level: 1 ): it => {
  set text(font: "Liberation Serif", size: 1em, weight: "bold")
  it
  v(1em)
}

// Add vertical space after level 2 headings (sections)
#show heading.where(level: 2): it => {
  it
  v(0.7em)
}

#show heading.where(level: 3): it => {
  it
  v(0.4em)
}


// Add 1em vertical space after level 1 headings (chapters)
// #show heading.where(level: 3): it => {
//   set text(font: "Liberation Serif", size: 1em, weight: "bold")
//   it
//   // v(0.1em)
// }


#show std.link: it => text(fill: blue, underline(it))

= Introduction

Fixing a hole where the rain gets in.

#lorem(30)

#include("typ/ch01_refinements.typ")
#include("typ/ch02_ownership.typ")
#include("typ/ch03_structs.typ")
#include("typ/ch04_enums.typ")
#include("typ/ch05_vectors.typ")
#include("typ/ch06_consts.typ")
#include("typ/ch07_externs.typ")
#include("typ/ch08_traits.typ")
