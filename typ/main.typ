#import "@preview/mantys:1.0.2": *
#import "orly-modified.typ" as orly-modified

#show: mantys(
  name: "flux-book",
  version: "1.0.0",
  authors: (
    "Ranjit Jhala",
  ),
  license: "MIT",
  description: "Programming with Refinement Types with Rust",
  repository: "https://github.com/jneug/typst-mantys",

  /// Uncomment one of the following lines to load the above
  /// package information directly from the typst.toml file
  // ..toml("../typst.toml")e
  // ..toml("typst.toml"),

  // theme: include("orly-modified.typ"),
  // When orly-modified.typ exists, use one of these approaches:
  // #import "orly-modified.typ": my-theme
  // theme: my-theme,
  theme: orly-modified,
  theme-options: (
    title-image: image("figs/flux.png", height: auto),
  ),
  title: "Verify Rust with Flux",
  subtitle: "Refinement Types for Rust",
  date: datetime.today(),
  url: "https://flux-rs.github.io",
  abstract: [
    #lorem(50)
  ],

  // examples-scope: (
  //   scope: (:),
  //   imports: (:)
  // )

  // theme: themes.modern
)

// Set global heading numbering to use arabic numbers
#set heading(numbering: "1.1")

// Make the document title (inside the document, not on cover) italic
#show heading: it => {
  // Target headings that are likely the document title (unnumbered, early in doc)
  if it.body == "Verify Rust with Flux"  {
    set text(style: "italic")
    it
  } else {
    it
  }
}

// Add 1em vertical space after level 1 headings (chapters)
#show heading.where(level: 1): it => {
  set text(font: "Times New Roman", size: 1em, weight: "bold")
  it
  v(0.5em)
}

#show std.link: it => text(fill: blue, underline(it))


// #let code-block(lang: none, classes: (), content) = {
//   // Custom styling based on classes
//   raw(lang: lang, #content)
// }

// #code-block(lang: "python", classes: ("highlight", "numbered"))[
// def hello():
//     print("Hello, world!")
// ]


= Introduction

Fixing a hole where the rain gets in.

#lorem(30)


```rust-editable
fn incr(x: i32) -> i32 {
  x + 2
}
```

#include("01-refinements.typ")

= Basics

#lorem(30)

= References

#lorem(30)

= Structs

#lorem(30)
