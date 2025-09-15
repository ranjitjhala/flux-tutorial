#import "@preview/mantys:1.0.2": *
#import "orly-modified.typ" as orly-modified
#import "@preview/codly:1.3.0": *
#import "@preview/codly-languages:0.1.1": *

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
    title-image: image("figs/flux.png", height: auto),
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

// Render flux blocks also as rust
#show raw.where(lang: "flux"): it => {
  set text(size: 1.2em)
  raw(it.text, lang: "rust", block: it.block)
}

// Add 1em vertical space after level 1 headings (chapters)
#show heading.where(level: 1 ): it => {
  set text(font: "Liberation Serif", size: 1em, weight: "bold")
  it
  v(0.5em)
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

#include("01-refinements.typ")
#include("02-ownership.typ")

= Random Junk

*Editable Rust*


```flux
fn stinker_pinker(x: i32) -> i32 {
  x + 1
}
```


*Plain Rust*

```flux
fn incr(x: i32) -> i32 {
  x + 2
}
```

#alert("info", [
  *Note:* Make sure you have the latest version of Flux installed before proceeding with these examples.
])


#alert("warning", [
  *Note:* Make sure you have the latest version of Flux installed before proceeding with these examples.
])

#alert("error", [
  *Note:* Make sure you have the latest version of Flux installed before proceeding with these examples.
])

#alert("success", [
  *Note:* Make sure you have the latest version of Flux installed before proceeding with these examples.
])
