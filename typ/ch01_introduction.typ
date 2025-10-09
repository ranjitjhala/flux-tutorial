#import "../orly-modified.typ": alert

= Introduction <ch:01_introduction>

Types bring order to code.

For example, if a variable `i` has type `usize` then we
know that `i` is a number that can be used to index a vector.
//
Similarly, if `names` has type `Vec<&str>` then we can
be certain that `names` is a collection of strings which
may _be_ indexed but of course, not used _as_ an index.
//
By itself, however, a type like `usize` does not tell us
how _big_ the number is, or whether it may safely be used
to index into `names`.
//
The programmer must still rely on their own wits, lots of tests, and
a dash of optimism, to ensure that all the different bits fit properly
at run-time.

== Flux

Flux is a _plugin_ for Rust that uses
refinement types #footnote[https://arxiv.org/abs/2010.07763],
a promising new way to extend type checkers with _logical_
constraints that specify additional correctness requirements.
//
In a nutshell, Flux lets you decorate Rust's types ---
for functions, structs, enums, traits, impls, _etc._ ---
with logical constraints that describe the _legal_ values
that those entities may take or produce.
//
The Flux type checker then uses a neat piece of technology called
an SMT solver #footnote[https://en.wikipedia.org/wiki/Satisfiability_modulo_theories],
 to verify, at _compile-time_ that, in fact,
your code only ever constructs values that satisfy these constraints.

If Flux _cannot prove_ that the constraints are _always_ satisfied,
it will issue a error that prevents your code from compiling.
//
Sometimes, this is because your _code_ has an error that needs fixing.
And sometimes, this is because your _types_ have to be juiced up
to give Flux enough clues to verify the code.
//
However, once your code _does_ verify, you can rest assured that
a host of run-time errors simply cannot occur, including
array out-of-bounds errors, arithmetic underflows and
any other assertion that you can express in Flux's logic.



== Goals

This is a tutorial on how to use Flux
to write Rust with refinement types.
//
The main goal of the tutorial is to explain:

1. What refinement types _mean_ and how they relate to code;
2. Where to _write_ refinement types to specify properties of code;
3. How to _understand_ when checking fails how to fix the code or the types.
//
We hope to do the above via a sequence of ten
or so chapters, which have several exercises
for you to work through to understand
//
what refinement types are,
what they can do for you, and
how you can use them to write better Rust code.


== Doing the Tutorial Online

The easiest way to do this tutorial is in your web browser
#footnote[https://flux-rs.github.io/flux/tutorial/01-refinements.html].
//
While the web pages look like a plain old `mdbook` site,
in fact, each code snippet is _editable_ and has a
_run_ icon which, upon clicking, runs `flux` on that
file and shows you errors (if any).

#figure(
  grid(
    columns: 1,
    gutter: 1em,
    image("../img/ch00_play_1.png", width: 95%),
    image("../img/ch00_play_2.png", width: 95%)
  ),
  caption: [Click the blue "play" button to run Flux on the file; edit to fix errors.]
)

== Doing the Tutorial Locally

You might prefer to run it locally on your own machine,
so that you can use your own editor and development
environment or save your work for later.
//
To do so:

1. *Install* `flux` #footnote[https://flux-rs.github.io/flux/guide/install.html#installing-and-running-flux];

2. *Clone* the tutorial repository #footnote[`git clone git clone git@github.com:flux-rs/flux-tutorial.git`];

3. *Run* `cargo flux` inside `flux-tutorial` to see the errors.

As you work through the tutorial, you can uncomment the lines
in the `include` section of the `Cargo.toml` to have Flux check
the code in the different chapters.
