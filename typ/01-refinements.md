# Refining Types

Types bring order to code. For example, if a variable `i` has type
`usize` then we know that `i` is a number that can be used to index a
vector. Similarly, if `names` has type `Vec<&str>` then we can be
certain that `names` is a collection of strings which may *be* indexed
but of course, not used *as* an index. However, by itself, `usize` does
not tell us how *big* or *small* the number is. The programmer must
still rely on their own wits, lots of tests, and a dash of optimism, to
ensure that all the different bits fit properly at run-time.

[Refinements](https://arxiv.org/abs/2010.07763) are a promising new way
to extend type checkers with *logical* constraints that specify
additional correctness requirements that can be verified at
compile-time, thereby entirely eliminating various classes of run-time
problems. Lets see how flux lets you refine basic or primitive types
like `i32` or `usize` or `bool` with logical constraints that can be
checked at compile time.

## Indexed Types

The simplest kind of refinement type in flux is a type that is *indexed*
by a logical value. For example

::: {align="center"}
  -------------- ----------------------------------------------------
  **Type**       **Meaning**
  `i32[10]`      The singleton set of `i32` values equal to `10`
  `bool[true]`   The singleton set of `bool` values equal to `true`
  -------------- ----------------------------------------------------
:::

### Flux Specifications

First off, we need to add some incantations that pull in the mechanisms
for writing flux specifications as Rust *attributes*.

``` flux
#![allow(unused)]
extern crate flux_rs;
use flux_rs::attrs::*;
```

### Post-Conditions

We can already start using these indexed types to start writing (and
checking) code. For example, we can write the following specification
which says that the value *returned* by `mk_ten` must in fact be `10`

``` flux
#[spec(fn() -> i32[10])]
pub fn mk_ten() -> i32 {
    5 + 4
}
```

**Push Play** Push the "run" button in the pane above. You will see a
red squiggle that and when you hover over the squiggle you will see an
error message

``` bash
error[...]: refinement type error
  |
7 |     5 + 4
  |     ^^^^^ a postcondition cannot be proved
```

which says that that the *postcondition might not hold* which means that
the *output* produced by `mk_ten` may not in fact be an `i32[10]` as
indeed, in this case, the result is `9`! You can eliminate the error by
*editing* the body to `5 + 4 + 1` or `5 + 5` or just `10`.
