/*
#import "../orly-modified.typ": alert

= Refining Types <ch:01_refinements>

Types bring order to code. For example, if a variable `i` has
type `usize` then we know that `i` is a number that can be used
to index a vector. Similarly, if `names` has type `Vec<&str>`
then we can be certain that `names` is a collection of strings
which may _be_ indexed but of course, not used _as_ an index.
//
However, by itself, `usize` does not tell us how _big_ the number is,
or whether it may safely be used to index into `names`.
//
The programmer must still rely on their own wits, lots of tests, and
a dash of optimism, to ensure that all the different bits fit properly
at run-time.

#link("https://arxiv.org/abs/2010.07763")[Refinements] are a
promising new way to extend type checkers with _logical_
constraints that specify additional correctness requirements
that can be verified at compile-time, thereby entirely
eliminating various classes of run-time problems.
//
Lets see how flux lets you refine basic or primitive
types like `i32` or `usize` or `bool` with logical constraints that
can be checked at compile time.

#alert("info", [
  *Flux Specifications:* First off, we need to add some incantations that pull in the mechanisms for writing Flux specifications as Rust attributes.
  This is done by importing the `flux_rs` crate and the `flux_rs::attrs` module.
])



*/



#![allow(unused)]
extern crate flux_rs;
use flux_rs::attrs::*;



/*


== Indexed Types

The simplest kind of refinement type in flux is a type that is
_indexed_ by a logical value. For example

#align(center)[
#table(
  columns: 2,
  align: (left, left),
  [*Type*], [*Meaning*],
  [`i32[10]`], [The  singleton set of `i32` values equal to `10`],
  [`bool[true]`], [The singleton set of `bool` values equal to `true`],
  [`char['c']`], [The singleton set of `char` values equal to `'c'`],

)
]

For example, lets write a little block of code with variables whose types are refined like the above.

*/



fn examples() {
  let x = 10;     // x: i32[10]
  let y = true;   // y: bool[true]
  let z = 'c';    // z: char['c']
}



/*

#alert("info", [
  *Flux View:* If you open this `.rs` file in the
  #link("https://marketplace.visualstudio.com/items?itemName=RanjitJhala.flux-checker")[VSCode extension], toggle the `Flux View`, check the `trace` box and hit save, then on the right you should see the type annotations for each variable, as shown in the figure below @fig:examples.
])

#figure(
  image("../img/ch01_examples.png", width: 90%),
  caption: [Viewing Flux types in VSCode],
) <fig:examples>


=== Post-Conditions

We can now use these indexed types to start writing (and checking)
code. For example, we can write the following specification which
says that the value _returned_ by `mk_ten` must, in fact, be `10`

*/



#[spec(fn() -> i32[10])]
pub fn mk_ten() -> i32 {
    5 + 4
}



/*

When you run `flux` on this code, for example, by pushing the
"run" button in the pane above in the online demo, or hitting
save in your editor, `flux` will produce a little red squiggle
under the `5 + 4`, with the error message

```
error[E0999]: refinement type error
  |
6 |     5 + 4
  |     ^^^^^ a postcondition cannot be proved
  |
note: this is the condition that cannot be proved
  |
4 | #[spec(fn() -> i32[10])]
  |                    ^^
```

The error message says that `flux` cannot prove that
the output expression `5 + 4` has the type `i32[10]`,
as indeed, in this case, the output result equals `9`!
//
You can eliminate the error by editing the body
to `5 + 4 + 1` or `5 + 5` or just `10`.

// // <!-- SLIDE -->

=== Pre-Conditions

You can use an index to restrict the _inputs_ that a function expects.

*/



#[spec(fn (b:bool[true]))]
pub fn assert(b:bool) {
  if !b { panic!("assertion failed") }
}



/*

The specification for `assert` says you can only call it with the input `true`. So if you write

*/



fn test_assert(){
  assert(2 + 2 == 4);
  assert(2 + 2 == 5); // fails to type check
}



/*

then Flux will complain that

```
error[E0999]: refinement type error
   |
10 |   assert(2 + 2 == 5); // fails to type check
   |   ^^^^^^^^^^^^^^^^^^ a precondition cannot be proved
   |
note: this is the condition that cannot be proved
   |
 3 | #[spec(fn (b:bool[true]))]
   |                   ^^^^
```

meaning at the second call to `assert` the input _may not_
be `true`, as of course, in this case, it is `false`!
Can you edit the code of `test` to fix the error?

// // <!-- SLIDE -->

== Index Parameters

Its not terribly exciting to only talk about _fixed_ values
like `10` or `true`. To be more useful, `flux` lets you index
types by refinement _parameters_.

*/



#[spec(fn(n:i32) -> bool[0 < n])]
pub fn is_pos(n: i32) -> bool {
  if 0 < n { true } else { false }
}



/*

For example, you can write a function `is_pos` whose type says that it

- *takes* as _input_ some `i32` _indexed by_ `n`
- *returns* as _output_ the `bool` _indexed by_ `0 < n`

That is, `is_pos` returns `true` _exactly when_ `0 < n`.

We might use this function to check that:

*/



pub fn test_pos(n: i32) {
  let m = if is_pos(n) { n - 1 } else { 0 };
  assert(0 <= m);
}



/*

// // <!-- SLIDE -->

== Existential Types

Often we don't care about the _exact_ value of a thing, but just
care about some _properties_ that it may have. For example, we might
not care that an `i32` is equal to `5` or `10` or `n` but that it is
non-negative or less than `n`.
//
Flux allows such specifications by pairing plain Rust types
with _assertions_ that constrain the value#footnote[These are _not_ arbitrary Rust expressions: they are a subset of _pure_ expressions from logics that can be efficiently decided by SMT Solvers.]. For example, the type

- `i32{v: 0 < v}` denotes the set of `i32` values that are positive,
- `i32{v: n <= v}` denotes the set of `i32` values greater than or equal to `n`.


// // <!-- SLIDE -->

=== Existential Output Types

We can rewrite `mk_10` with the output type `i32{v:0 < v}` that
specifies that the value returned by `mk_ten_pos`
is positive (not necessarily equal to `10`).

*/



#[spec(fn() -> i32{v: 0 < v})]
pub fn mk_ten_pos() -> i32 {
    5 + 5
}



/*

// // <!-- SLIDE -->

=== An `abs`olute value function

Lets write a function that computes the _absolute_
value of an `i32` and give it a refined type which
says the result is non-negative _and_ exceeds the input `n`.

*/



#[spec(fn (n:i32) -> i32{v: 0 <= v && n <= v})]
pub fn abs(n: i32) -> i32 {
    if 0 <= n {
      n
    } else {
      0 - n
    }
}



/*


The figure below @fig:ch01-abs shows the Flux view for `abs`.
You can see the types at the `then` and the `else`
branches. In the either case, `n` has the _indexed_
type `i32[n]`, i.e. the value equals the logical
integer `n`.
//
However, in the `then` branch shown on the left,
note the additional *`Constraint`* of the form
`0 <= n` that arises from the branch condition.
//
Correspondingly, in the `else` branch shown on
the right, we have the _negation_ of that condition.
Further, `res` has type `i32[0 - n]`.

#figure(
  image("../img/ch01_abs.png", width: 90%),
  placement: top,
  caption: [How `if-else` branches affect Flux types],
) <fig:ch01-abs>

// // <!-- SLIDE -->

== Combining Indexes and Constraints <ch:01_refinements:combining-indexes-and-constraints>

Sometimes, we want to _combine_ indexes and constraints in a specification.
For example, suppose we have some code that manipulates
_scores_ which are required to be between `0` and `100`.
Now, suppose we want to write a function that adds `k`
points to a score `s`. We want to specify that

- The _inputs_ `s` and `k` must be non-negative,
- the _inputs_ `s + k <= 100`, and
- The _output_ equals `s + k`.

*/



#[spec(fn (s:usize{s + k <= 100}, k:usize) -> usize[s + k])]
fn add_points(s: usize, k: usize) -> usize {
    s + k
}
fn test_add_points() {
    assert(add_points(20, 30) == 50);
    assert(add_points(90, 30) == 120); // fails to type check
}



/*

Note that we

1. _constrain_ the inputs to `s + k <= 100`, and
2. _refine_ the value of the output to be exactly `usize[s + k]`.

#alert("success", [
*EXERCISE:* Why does Flux reject the second call to `add_points`?
])

// // <!-- SLIDE -->

=== Example: `factorial`

As a last example, lets write a function to compute the factorial of `n`

*/



#[spec(fn (n:i32) -> i32{v:1<=v && n<=v})]
pub fn factorial(n: i32) -> i32 {
    let mut i = 0;
    let mut res = 0;
    while i < n {
        i += 1;
        res = res * i;
    }
    res
}



/*

The specification says the input must be non-negative, and the
output is at least as large as the input. Unlike the previous
examples, here we're actually _changing_ the values of `i` and `res`.

#alert("success", [
*EXERCISE:* Why does flux reject the definition of `factorial`? Can you fix the code so that it is accepted?
])
// // <!-- SLIDE -->

== Summary

In this chapter, we saw how Flux lets you

1. *refine* basic Rust types like `i32` and `bool` with
    _indices_ and _constraints_ that let you respectively
    define the sets of values that inhabit that type, and

2. *specify contracts* on functions that state _pre-conditions_ on
   the sets of legal inputs that they accept, and _post-conditions_
   that describe the outputs that they produce.

The whole point of Rust, of course, is to allow for efficient _imperative_
sharing and updates, without sacrificing thread- or memory-safety.
//
In the next chapter, we will see how Flux melds refinements and Rust's ownership to make refinements get along with imperative code.

// [flux-grammar]: https://github.com/flux-rs/flux/blob/main/book/src/guide/specs.md#grammar-of-refinements
// [flux-github]: https://github.com/liquid-rust/flux/
*/
