/*
#import "../orly-modified.typ": alert

= Refining Enums <ch:04_enums>

*/



#![allow(unused)]
extern crate flux_rs;
use flux_rs::attrs::*;
use flux_rs::assert;



/*

Previously in @ch:03_structs we saw how to refine structs to constrain the space
of legal values, for example, to define a `Positivei32` or a `Range` `struct` where
the `start` was less than or equal to the `end`. Next, lets see how the same mechanism
can be profitably used to let us check properties of `enums` at compile time.

// <!-- SLIDE -->

== Failure is an Option

Rust's type system is really terrific for spotting all
manner of bugs at compile time. However, that just makes
it all the more disheartening to get runtime errors like

```
thread panicked ... called `Option::unwrap()` on a `None` value
```

Lets see how to refine `enum`'s like `Option` to
let us `unwrap` without the anxiety of run-time failure.

// <!-- SLIDE -->

=== A Refined Option <ch:04_enums:refined-option>

To do so, lets define a custom `Option` type
#footnote[
  Fear not, you can use this method on your existing code using `std::option::Option`!
  In @ch:07_externs we will learn about _extern specifications_ which will explain how
  to do so.
] that is indexed by a `bool` which indicates whether or not the option is
valid (i.e. `Some` or `None`):

*/



#[refined_by(valid: bool)]
pub enum Option<T> {
    #[variant((T) -> Option<T>[{valid: true}])]
    Some(T),
    #[variant(Option<T>[{valid: false}])]
    None,
}



/*

As with `std::option::Option`, we have two variants

- `Some`, with the "payload" `T` and
- `None`, without.

However, we have tricked out the type in two ways.

1. We used a `refined_by` attribute to add a `bool` sorted index whose job is to track if the option is `valid`;
2. We used the `variant` attribute to define the value of `valid` for the `Some` and `None` cases.

// <!-- SLIDE -->

=== Constructing Options

The definition above tells Flux that `Some(12)`
has the refined type `Option<i32>[{valid: true}]`,
and `None` has the refined type `Option<i32>[{valid: false}]`.

#alert("info", [
*TIP:* When there is a _single_ refinement index we
can skip the `{valid:b}` and just write `b`, so we
could have equivalently written `Option<T>[true]`
and `Option<T>[false]` above.
])

*/



#[spec(fn () -> Option<i32>[true])]
fn test_some() -> Option<i32> {
  Option::Some(12)
}

#[spec(fn () -> Option<i32>[false])]
fn test_none() -> Option<i32> {
  Option::None
}



/*

// <!-- SLIDE -->

=== Destructing Options by Pattern Matching

The neat thing about refining variants is that _pattern matching_
on the `enum` tells Flux what the variant's refinements are.
For example, consider the following implementation of `is_some`

*/



impl<T> Option<T> {
  #[spec(fn(&Self[@valid]) -> bool[valid])]
  pub fn is_some(&self) -> bool {
    match self {
      Option::Some(_) => true, // valid == true
      Option::None => false,   // valid == false
    }
  }
}



/*

If you look at the code for `is_some` in the Flux view, you will see that
in the `Some(_)` branch, Flux additionally knows the *Constraint* that
`valid == true`, and in the `None` branch, it knows that `valid == false`.

#figure(
  grid(
    columns: 1,
    gutter: 1em,
    image("../img/ch04_is_some_1.png", width: 95%),
    image("../img/ch04_is_some_2.png", width: 95%)
  ),
  caption: [Pattern matching tells Flux about the `enum`'s index value.]
)

// <!-- SLIDE -->

=== Checking Code is Unreachable

When working with `Option` types, or more generally,
with `enum`s, we often have situations in pattern-match
cases where we "know" that that case will not arise.

Typically we mark those cases with an `unreachable!()` call.

With Flux, we can _prove_, at compile-time,
that those cases will never, in fact, be executed.

*/



#[spec(fn () -> _ requires false)]
fn unreachable() -> ! {
    assert(false);  // flux will prove this is unreachable
    unreachable!(); // panic if we ever get here
}



/*

#alert("info", [
*TIP:* Usually, we write the _preconditions_ on the input values
of a function as refinement types for the respective input parameters.
However, if there are _no_ inputs, you can use a `requires` clause.
Here, the precondition `false` ensures that the _only_ way that
a call to `unreachable` can be verified is when flux can prove
that the call-site is "dead code".
])

For example, we can test that `unreachable` is indeed unreachable
by writing a little function that calls it, but only under impossible
conditions

*/



fn test_unreachable_if(n: usize) {
  let x = 12 + n;
  if x < 12 {
    unreachable(); // impossible as 12 <= x
  }
}



/*

In fact, `rustc` translates `if` statements roughly into the equivalent of the below
code using `match`

*/



fn test_unreachable_match(n: usize) {
  let x = 12 + n;
  let b = x < 12;
  match b {
    true => unreachable(),
    false => ()
  }
}



/*

If you look at the Flux view of `test_unreachable_if` or `test_unreachable_match`
you will see what Flux knows in each branch or `match` arm:

#figure(
  grid(
    columns: 1,
    gutter: 1em,
    image("../img/ch04_unreachable_true.png", width: 85%),
    image("../img/ch04_unreachable_false.png", width: 85%)
  ),
  caption: [Types of variables in the `test_unreachable_match` function.]
)

Notice that the input parameter `n` has the type `usize[a0]` meaning some unknown
integer `a0` but with the constraint that `a0 >= 0` because it is a `usize`;
`x` has the type `usize[12 + a0]` #footnote[What about the possibility of
arithmetic overflow if `n` is large? Don't worry, you can configure Flux to
check for those, but we'll save that for a later day.], and so `b` has the
type `bool[12 + a0 < 12]`, meaning that `b` is `true` _exactly when_ `12 + a0 < 12`.
//
Now, in the `true` arm, Flux knows that the index for `b` must be true, that
is, it adds the additional *Constraint* `12 + a0 < 12` which is impossible _i.e._
which _implies_ the precondition `false` of `unreachable`, and hence the call is verified.
//
In the `false` arm, Flux knows that `b` is false, i.e. it adds the
negated constraint `!(12 + a0 < 12)`, which of course, does _not_ imply `false`.
So if you try to sneak a call to `unreachable` in the `false` arm, Flux would
report an error.

#alert("info", [
  *Halting Problem:* If you're familiar with the notion of
  the #link("https://en.wikipedia.org/wiki/Halting_problem")[Halting Problem]
  you might wonder how Flux could possibly prove that `unreachable` is unreachable,
  since that a textbook example of an #link("https://en.wikipedia.org/wiki/Undecidable_problem")[undecidable problem]. Rest assured, Flux can not and does not solve the Halting Problem.
  It is a sound but incomplete analysis, meaning that if it says
  that `unreachable` is unreachable, then it really is unreachable,
  but you can easily write code that is unreachable but that Flux
  _cannot prove_ to be unreachable.
])

// <!-- SLIDE -->

=== Unwrap Without Anxiety!

Lets use our refined `Option` to implement a safe `unwrap` function.

*/



impl<T> Option<T> {
  #[spec(fn(Self[true]) -> T)]
  pub fn unwrap(self) -> T {
    match self {
      Option::Some(v) => v,
      Option::None => unreachable(),
    }
  }
}



/*

The `spec` requires that `unwrap` is _only_ called
with an `Option` whose (`valid`) index is `true`,
i.e. `Some(...)`.
//
The `None` pattern is matched only when the index
is `false`, which, as shown below, adds the impossible
constraint `true = false` in the `match` arm for `None`.
//
Hence, Flux concludes that pattern is dead code,
much like the `x < 12` branch is dead code in the
`test_unreachable` above.

#figure(
  image("../img/ch04_unwrap.png", width: 85%),
  caption: [The `None` arm is `unreachable` when matching `valid` `Option` values.]
)


// <!-- SLIDE -->

== Using `unwrap`

Next, lets see some examples of how to _use_ refined options
to safely `unwrap`.

// <!-- SLIDE -->

=== Safe Division

Here's a safe divide-by-zero function that returns an `Option<i32>`

*/



#[spec(fn(n:i32, k:i32) -> Option<i32>)]
pub fn safe_divide(n: i32, k: i32) -> Option<i32> {
  if k > 0 {
    Option::Some(n / k)
  } else {
    Option::None
  }
}



/*

#alert("success", [
*EXERCISE:* Why does the test below fail to type check?
Can you fix the `spec` for `safe_divide` so Flux is happy
with `test_safe_divide`?
])

*/



fn test_safe_divide() -> i32 {
    safe_divide(10, 2).unwrap()
}



/*

// <!-- SLIDE -->

=== Smart Constructors Revisited

Recall the `struct Positivei32` from @ch:03_structs:positive-integers
and the smart constructor we wrote for it.

*/



#[refined_by(n: int)]
#[invariant(n > 0)]
struct Positivei32 {
    #[field(i32[n])]
    val: i32
}

impl Positivei32 {
  #[spec(fn(val: i32) -> Option<Self>)]
  pub fn new(val: i32) -> Option<Self> {
    if val > 0 {
      Option::Some(Positivei32 { val })
    } else {
      Option::None
    }
  }
}



/*

#alert("success", [
*EXERCISE:* The code below has a function that
invokes the smart constructor and then `unwrap`s
the result. Why is Flux complaining? Can you fix
the `spec` of `new` so that the `test_unwrap` figure
out how to fix the `spec` of `new` so that `test_new_unwrap`
is accepted?
])

*/



fn test_new_unwrap() {
    Positivei32::new(10).unwrap();
}



/*

// <!-- SLIDE -->

== TypeStates: A Refined Timer

Lets look a different way to use refined `enum`s.

On the
#link("https://flux-rs.zulipchat.com/#narrow/channel/486098-general/topic/greetings/near/509911720")[Flux Zulip] we were asked if we could write an `enum` to represent a `Timer`
with two variants:

- `Inactive`,  indicating that the timer is not running, and
- `CountDown(n)`,  indicating that the timer is counting down from `n` seconds,

where we could then use refinements to ensure that a `Timer` can only
be set to `Inactive` when `n < 1`.

// <!-- SLIDE -->

=== Refined Timers

To do so, lets define the `Timer`, refined with an `int` index that tracks
the number of remaining seconds.

*/



#[refined_by(remaining: int)]
enum Timer {
    #[variant(Timer[0])]
    Inactive,

    #[variant((usize[@n]) -> Timer[n])]
    CountDown(usize)
}



/*

The flux definitions ensure that `Timer` has two variants

- `Inactive`, which has a `remaining` index of `0`, and
- `CountDown(n)`, which has a `remaining` index of `n`.

// <!-- SLIDE -->

=== Timer Implementation

We can now implement the `Timer` with a constructor and a method to set it to `Inactive`.

*/



impl Timer {
    #[spec(fn (n: usize) -> Timer[n])]
    pub fn new(n: usize) -> Self {
       Timer::CountDown(n)
    }

    #[spec(fn (self: &mut Self[0]))]
    fn deactivate(&mut self) {
        *self = Timer::Inactive
    }
}



/*

// <!-- SLIDE -->

=== Deactivate the Timer

Now, Flux will only let us `deactivate` a timer whose countdown is at `0`.

*/



fn test_deactivate() {
  let mut t0 = Timer::new(0);
  t0.deactivate(); // verifies

  let mut t3 = Timer::new(3);
  t3.deactivate(); // rejected
}



/*

The above code produces an error because `t3` has the type `Timer[3]`



#figure(
  grid(
    columns: 1,
    gutter: 1em,
    image("../img/ch04_test_deactivate.png", width: 85%),
```
error[E0999]: refinement type error
   --> src/ch04_enums.rs:495:3
    |
495 |   t3.deactivate(); // rejected
    |   ^^^^^^^^^^^^^^^ a precondition cannot be proved
    |
note: this is the condition that cannot be proved
   --> src/ch04_enums.rs:470:32
    |
470 |     #[spec(fn (self: &mut Self[0]))]
    |                                ^
```
  ),
  caption: [Flux rejects the call to `deactivate` on a `Timer[3]`.]
)

// <!-- SLIDE -->

=== Ticking the Timer

Here is a function to `tick` the timer down by one second.

// <!-- // #[spec(fn (self: &mut Self[@s]) ensures self: Self[if n > 1 then n-1 else 0])] -->

*/



impl Timer {
  #[spec(fn (self: &mut Self[@s]) ensures self: Self)]
  fn tick(&mut self) {
    match self {
      Timer::CountDown(s) => {
        let n = *s;
        if n > 0 {
          *s = n - 1;
        }
      }
      Timer::Inactive => {},
    }
  }
}



/*

#alert("success", [
*EXERCISE:* Can you fix the `spec` for `tick` so that Flux accepts `test_tick`?
])

*/



fn test_tick() {
  let mut t = Timer::new(3);
  t.tick();       // should decrement to 2
  t.tick();       // should decrement to 1
  t.tick();       // should decrement to 0
  t.deactivate(); // should set to Inactive
}



/*

== Summary

In this chapter, we saw how you refine an `enum` with indices, and then specify
the values of the indices for each `variant`. This let us, for example, determine
whether an `Option` is `Some` or `None` at compile time, and to safely `unwrap`
the former, and to encode a "typestate" mechanism for a `Timer` that ensures we
only `deactivate` when the timer has expired. You can do other fun things, like

- track the #link("https://github.com/flux-rs/flux/blob/main/tests/tests/pos/enums/list00.rs")[length] of a linked list,
- track the #link("https://github.com/flux-rs/flux/blob/main/tests/tests/pos/enums/list01.rs")[set of elements] in the list, or
- determine whether an expression is in normal form (@ch:09_anf), or
- ensure the layers of a neural network are composed correctly (@ch:12_neural).
*/
