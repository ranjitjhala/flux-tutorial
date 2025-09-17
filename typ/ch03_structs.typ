#import "../orly-modified.typ": alert

= Refining Structs <ch:03_structs>

```fluxhidden
#![allow(unused)]
extern crate flux_rs;
use flux_rs::attrs::*;

#[flux_rs::spec(fn (bool[true]))]
fn assert(b: bool) {
    if !b {
        panic!("assertion failed");
    }
}
```

Previously, we saw how to slap refinements on existing _built-in_
or _primitive_ Rust types. For example,

- `i32[10]` specifies the `i32` that is _exactly_ equal to `10` and
- `i32{v: 0 <= v && v < 10}` specifies an `i32` between `0` and `10`.

Next, lets see how to attach refinements to _user-defined_ types,
so we can precisely define the set of _legal_ values of those types.

// <!-- SLIDE -->

== Positive Integers <ch:03_structs:positive-integers>

Lets start with a question posted by
#link("https://github.com/Connor-GH")[Conner-GH]
on the Flux Github
#link("https://github.com/flux-rs/flux/issues/1106")[repository]:
//
#quote[
How do you create a `Positivei32`? I can think of two ways: `struct Positivei32 { val: i32, }` and truct `Positivei32(i32);` but I do not know how to apply the refinements for them. I want it to be an invariant that the i32 value is >= 0. How would I do this?
]

With Flux, you can define the `Positivei32` type as follows:

```flux
#[refined_by(n: int)]
#[invariant(n > 0)]
struct Positivei32 {
  #[field(i32[n])]
  val: i32
}
```

In addition to defining the plain Rust type `Positivei32`,
the refinements say _three_ distinct things:

1. the `refined_by(n: int)` tells flux to refine each
   `Positivei32` with a special `int`-sorted _index_ named `n`,
2. the `invariant(n > 0)` says that the index `n`
   is always positive, and
3. the `field` attribute on `val` says that the
   type of the field `val` is an `i32[n]`
   i.e. is an `i32` whose exact value is `n`.

// <!-- SLIDE -->

=== Creating Positive Integers

Now, you would create a `Positivei32` pretty much as you might in Rust:

```flux
#[spec(fn() -> Positivei32)]
fn mk_positive_1() -> Positivei32 {
  Positivei32 { val: 1 }
}
```

and Flux will prevent you from creating an _illegal_ `Positivei32`, like

```flux
#[spec(fn() -> Positivei32)]
fn mk_positive_0() -> Positivei32 {
  Positivei32 { val: 0 }
}
```

// <!-- SLIDE -->

=== A Constructor

#alert("success", [
*EXERCISE:* Consider the following `new` constructor for `Positivei32`.
Why does Flux reject it? Can you figure out how to fix the `spec` for
the constructor so Flux will be appeased?
])

```flux
impl Positivei32 {
  pub fn new(val: i32) -> Self {
    Positivei32 { val }
  }
}
```

// <!-- SLIDE -->

=== A "Smart" Constructor

#alert("success", [
*EXERCISE:* Here is a different, constructor that should work
for _any_ input `n` but which may return `None` if the input is
invalid. Can you _fix the code_ so that Flux accepts `new_opt`?
])

```flux
impl Positivei32 {
  pub fn new_opt(val: i32) -> Option<Self> {
      Some(Positivei32 { val })
  }
}
```

// <!-- SLIDE -->

=== Tracking the Field Value

In addition to letting us constrain the underlying `i32` to be positive,
the `n: int` index lets Flux precisely _track_ the value of the `Positivei32`.
For example, we can say that the following function returns a particular `Positivei32` whose value is `10`:

```flux
#[spec(fn() -> Positivei32[{n:10}])]
fn mk_positive_10() -> Positivei32 {
  Positivei32 { val: 10 }
}
```

#alert("info", [
*TIP:* When there is a single index, we can just write `Positivei32[10]`.
])

Since the field `val` corresponds to the _tracked index_,
Flux "knows" what `val` is from the index, which lets us
check that

```flux
#[spec(fn() -> i32[10])]
fn test_ten() -> i32 {
    let p = mk_positive_10(); // p   : Positivei32[{n: 10}]
    let res = p.val;          // res : i32[10]
    res
}
```

// <!-- SLIDE -->

=== Tracking the Value in the Constructor

#alert("success", [
*EXERCISE:* Scroll back up, and modify the `spec` for `new`
so that the below code verifies. That is, modify the `spec`
so that it says what the value of `val` is when `new` returns
a `Positivei32`. You will likely need to _combine_ indexes
and constraints as shown in the example `add_points` in
@ch:01_refinements:combining-indexes-and-constraints.
])

```flux
#[spec(fn() -> i32[99])]
fn test_new() -> i32 {
    let p = Positivei32::new(99);
    let res = p.val;
    res
}
```

// <!-- SLIDE -->

=== Field vs. Index?

At this point, you might be wondering why, since `n` is the value of the field `val`,
we didn't just name the index `val` instead of `n`?

Indeed, we could have named it `val`.

However, we picked a different name to emphasize that the index is _distinct from_
the field. The field actually exists at run-time, but in contrast, the index is a
_type-level property_ that only lives at compile-time.

// <!-- SLIDE -->

== Integers in a Range

Of course, once we can index and constrain a single field, we can do so for many fields.
//
For instance, suppose we wanted to write a `Range` type with two fields `start` and `end`
which are integers such that `start <= end`. We might do so as

```flux
#[refined_by(start: int, end: int)]
#[invariant(start <= end)]
struct Range {
  #[field(i32[start])]
  start: i32,
  #[field(i32[end])]
  end: i32,
}
```

This time around, for brevity, we're using
the _same_ names for the index as the field
even though they are _conceptually distinct_ things.

// <!-- SLIDE -->

=== Legal Ranges

The refined `struct` specification ensures we only create legal `Range` values.

```flux
fn test_range() {
    vec![
        Range { start: 0, end: 10 }, // ok
        Range { start: 15, end: 5 }, // rejected!
    ];
}
```

#alert("error", [show error message])

// <!-- SLIDE -->

=== A Range Constructor

#alert("success", [
*EXERCISE:* Fix the specification of the `new`
constructor for `Range` so that both `new` and
`test_range_new` are accepted by flux. (Again,
you will need to _combine_ indexes and constraints
as shown in the example `add_points` shown
in @ch:01_refinements:combining-indexes-and-constraints.
])

```flux
impl Range {
    pub fn new(start: i32, end: i32) -> Self {
        Range { start, end }
    }
}

#[spec(fn() -> Range[{start: 0, end: 10}])]
fn test_range_new() -> Range {
    let rng = Range::new(0, 10);
    assert(rng.start == 0);
    assert(rng.end == 10);
    rng
}
```

// <!-- SLIDE -->

=== Combining Ranges

Lets write a function that computes the _union_ of two ranges.
For example, given the range from `10-20` and `15-25`, we might
want to return the the union is `10-25`, using the `min`
and `max` functions defined below.

```flux
fn union(r1: Range, r2: Range) -> Range {
  let start = min(r1.start, r2.start);
  let end = max(r2.end, r2.end);
  Range { start, end }
}
```

#alert("success", [
*EXERCISE:* Can you figure out how to fix the `spec`
for `min` and `max` so that Flux will accept that
`union` only constructs legal `Range` values?
])


```flux
fn min(x:i32, y:i32) -> i32 {
  if x < y { x } else { y }
}

fn max(x:i32, y:i32) -> i32 {
  if x < y { y } else { x }
}


```

// // <!-- SLIDE -->

== Refinement Functions

When _code_ get's more complicated, we like to abstract it into reusable
functions. Flux lets us do the same for refinements too. For example, we
can define refinement-level functions `min` and `max` which take `int`
(not `i32` or `usize` but logical `int`) as input and return that as output.

```flux
defs! {
    fn min(x: int, y: int) -> int {
        if x < y { x } else { y }
    }
    fn max(x: int, y: int) -> int {
        if x < y { y } else { x }
    }
}
```

We can now use refinement functions like `min` and `max` inside types.
For example, the output type of `decr` precisely tracks the decremented value.

```flux
impl Positivei32 {
  #[spec(fn(&Self[@p]) -> Self[max(1, p.n - 1)])]
  fn decr(&self) -> Self {
    let val = if self.val > 1 { self.val - 1 } else { self.val };
    Positivei32 { val }
  }
}
```

You can test that `decr` indeed strongly updates (as described in @ch:02_ownership:strongly-mutable-references) the value of its reference
argument:

```flux
fn test_decr() {
  let p = Positivei32{val: 2}; // p : Positivei32[2]
  assert(p.val == 2);
  let p = p.decr();            // p : Positivei32[1]
  assert(p.val == 1);
  let p = p.decr();            // p : Positivei32[1]
  assert(p.val == 1);
}
```

// // <!-- SLIDE -->

=== Combining Ranges, Precisely

Lets rewrite `union` as an `impl` method on `Range`.

```flux
impl Range {
  #[spec(fn(&Self[@r1], &Self[@r2]) -> Self)]
  pub fn union(&self, other: &Range) -> Range {
    let start =
      if self.start < other.start { self.start } else { other.start };
    let end =
      if self.end < other.end { other.end } else { self.end };
    Range { start, end }
  }
}
```

#alert("success", [
*EXERCISE:* The above `union` method  says _some_ `Range`
is returned, but nothing about _what_ that range actually is.
Fix the `spec` for the `union` method above so that Flux
verifies the `assert` calls in `test_union` below.
])

```flux
fn test_union() {
  let r1 = Range { start: 10, end: 20 };
  let r2 = Range { start: 15, end: 25 };
  let r3 = r1.union(&r2);
  assert(r3.start == 10);
  assert(r3.end == 25);
}
```

== Summary

To conclude, we saw how you can use Flux to refine
user-defined `struct` to

1. *track* at the type-level, the values of fields, and
2. *constrain* the sets of _legal_ values for those structs.
//
To see a more entertaining example, check out
#link("https://github.com/flux-rs/flux/blob/f200714dfae5e7c9a3bdf7231191499f56aac45b/tests/tests/pos/surface/date.rs")[this code]
that shows how we can use refinements to
ensure that only _legal_ `Date`s can be
constructed at compile time!
