#import "@preview/mantys:1.0.2": *
#import "@preview/codly:1.3.0": *
#import "@preview/codly-languages:0.1.1": *
#import "orly-modified.typ" as orly-modified

#show: mantys(
  name: "flux-book",
  show-index: false,
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
  title: "Verifying Rust with Flux",
  subtitle: "Programming Rust with Refinement Types",
  date: datetime.today(),
  url: "https://flux-rs.github.io",
  abstract: [
Flux is a refinement type checker plugin for Rust that lets
you specify a range of correctness properties and have them
be verified at compile time.
//
Flux works by extending Rust's types with logical assertions
describing additional correctness requirements that are checked
during compilation.
//
This lets us eliminate various classes of run-time problems,
from arithmetic underflows or overflows, to out-of-bounds
array accesses, to application-specific assertions and invariants
about business logic.
//
This is a tutorial about how to write Rust with refinement types.
],
)


// Set global heading numbering to use arabic numbers
#set heading(numbering: "1.1")
#counter(heading).update(0)

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
  } else if el != none and el.func() == heading {
    // Handle heading references
    if el.level == 1 {
      // Level 1 headings are chapters
      let chapter-num = counter(heading).at(el.location()).first()
      link(el.location())[Chapter #chapter-num]
    } else {
      // Other levels use default behavior
      it
    }
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
  set text(font: "Palatino", size: 1em, weight: "bold")
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



#show std.link: it => text(fill: blue, underline(it))

#include("typ/ch00_introduction.typ")
#include("typ/ch01_refinements.typ")
#include("typ/ch02_ownership.typ")
#include("typ/ch03_structs.typ")
#include("typ/ch04_enums.typ")
#include("typ/ch05_vectors.typ")
#include("typ/ch06_consts.typ")
#include("typ/ch07_externs.typ")
#include("typ/ch08_traits.typ")

// --------------------------------------------------------

#include("typ/ch09_anf.typ")
#include("typ/ch10_scope.typ")
#include("typ/ch11_sparse.typ")
#include("typ/ch12_neural.typ")
