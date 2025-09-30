#import "../orly-modified.typ": alert

= Introduction <ch:00_introduction>

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

*Flux* is a _plugin_ for Rust that uses
#link("https://arxiv.org/abs/2010.07763")[refinement types]
a promising new way to extend type checkers with _logical_
constraints that specify additional correctness requirements
that can be verified at compile-time, thereby entirely
eliminating various classes of run-time problems.

== Goals

This is a tutorial on how to use Flux to write Rust with refinement types.
