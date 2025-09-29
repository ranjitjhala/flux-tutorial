/*
#import "../orly-modified.typ": alert

= Const Generics

// [Online demo](https://flux.goto.ucsd.edu/index.html#?demo=arrays.rs)

Rust has a built-in notion of _arrays_: collections of objects of
the same type `T` whose size is known at compile time.
As their sizes are known, arrays can be allocated contiguously in memory,
enabling fast access and manipulation.

When I asked ChatGPT what arrays were useful for, it replied
with several nice examples, including low-level systems programming (e.g.
packets of data represented as `struct`s with array-valued fields), storing configuration data, or small sets of related values, such as storing the red, green, and blue values for a pixel:

```rust
type Pixel = [u8; 3]; // RGB values

let pix0: Pixel = [255,   0, 127]; // rose pink
let pix1: Pixel = [  0, 255, 127]; // spring green
```

== Compile-time Safety...

As the size of the array is known at compile time, Rust can make sure that
we don't create arrays of the wrong size, or access them out of bounds.
For example, `rustc` will grumble if you try to make a `Pixel` with 4 elements:

```rust
error[E0308]: mismatched types
   |
52 | let pix2 : Pixel = [0,0,0,0];
   |            -----   ^^^^^^^^^ expected an array of 3 elements,
   |            |                 found one with 4 elements
   |            |
   |            expected due to this
```

Similarly, `rustc` will wag a finger if you try to access a `Pixel` at an invalid index.

```rust
error: this operation will panic at runtime
   |
54 | let b0 = pix0[3];
   |          ^^^^^^^ index out of bounds: length is 3 but index is 3
   |
```

== ... Run-time Panic!

However, the plain type system works only upto a point. For example, consider the
following function to compute the average `color` value of a collection of `&[Pixel]`

```rust
fn average_color(pixels: &[Pixel], i: usize) -> u64 {
    let mut sum = 0;
    for p in pixels {
        sum += p[i] as u64;
    }
    sum / pixels.len() as u64
}
```

Now, `rustc` does not complain about the above code, even though it may panic if
`color` is out of bounds (or, of course, if the slice `pixels` is empty!).
For example

```rust
fn main() {
    let pixels = [ [255, 0, 0], [0, 255, 0], [0, 0, 255] ];
    let avg = average(&pixels, 3);
    println!("Average: {}", avg);
}
```

panics at runtime:

```
thread 'main' panicked ... index out of bounds: the len is 3 but the index is 3
```

== Refined Compile-time Safety <ch:06_consts:refined-compile-time-safety>

Fortunately, Flux knows about the sizes of arrays and slices. At compile time,
`flux` warns about two possible errors in `average_color`

#figure(
    image("../img/04-arrays-average-error.png", width: 90%),
    caption: [Flux warns about possible errors in `average_color`],
)

1. The index `i` may be out of bounds when accessing `p[i]` and
2. The division can panic as `pixels` may be empty (i.e. have length `0`).

We can fix these errors by requiring that the input

- `i` be a valid color index, i.e. `i < 3` and
- `pixels` be non-empty, i.e. have size `n` where `0 < n`

```rust
#[spec(fn(pixels: &[Pixel][@n], i:usize{i<3}) -> u64 requires 0 < n)]
```

#figure(
    image("../img/04-arrays-average-fix.gif", width: 90%),
    caption: [Refinements ensure `average_color` is safe],
)

== Const Generics

Rust also lets us write arrays that are _generic_ over the size. For example,
suppose we want to take two input arrays `x` and `y` of the same size `N` and
compute their dot product. We can write

```rust
fn dot<const N:usize>(x: [f32;N], y: [f32;N]) -> f32 {
    let mut sum = 0.0;
    for i in 0..N {
        sum += x[i] * y[i];
    }
    sum
}
```

This is very convenient because `rustc` will prevent us from calling `dot` with
arrays of different sizes, for example we get a compile-time error

```rust
error[E0308]: mismatched types
   |
68 |     dot([1.0, 2.0], [3.0, 4.0, 5.0]);
   |     ---             ^^^^^^^^^^^^^^^ expected an array with a fixed size of 2 elements, found one with 3 elements
   |     |
   |     arguments to this function are incorrect
   |
```

However, suppose we wanted the `dot` product of just the first `k` elements

```rust
fn dot_k<const N:usize>(x: [f32;N], y: [f32;N], k: usize) -> f32 {
    let mut sum = 0.0;
    for i in 0..k {
        sum += x[i] * y[i];
    }
    sum
}
```

Now, unfortunately, `rustc` will not prevent us from calling `dot_k` with `k` set to a value that is too large!

```rust
thread 'main' panicked at ... index out of bounds: the len is 2 but the index is 2
```

Yikes.

== Refined Const Generics

Fortunately, Flux understands const-generics as well!

First off, it warns us about the fact that the accesses with the index may be out of bounds.

#figure(
    image("../img/04-arrays-dotk-error.png", width:90%),
    caption: [Flux warns about possible out-of-bounds access in `dot_k`],
)

We can fix it in two ways.

#strong[The Permissive] approach is to accept any `k` but restrict the iteration to the valid elements

```rust
fn dot_k<const N:usize>(x: [f32;N], y: [f32;N], k: usize) -> f32 {
    let mut sum = 0.0;
    let n = if k < N { k } else { N };
    for i in 0..n {
        sum += x[i] * y[i];
    }
    sum
}
```

#figure(
    image("../img/04-arrays-dotk-permissive.gif", width:83%),
    caption: [A permissive version of `dot_k` that always works],
)

#strong[The Strict] approach is to require that `k` be less than or equal to `N`

```rust
#[sig(fn(x: [f32;N], y: [f32;N], k:usize{k <= N}) -> f32)]
fn dot_k<const N:usize>(x: [f32;N], y: [f32;N], k: usize) -> f32 {
    let mut sum = 0.0;
    for i in 0..k {
        sum += x[i] * y[i];
    }
    sum
}
```

#alert("success", [
*EXERCISE:* Do you understand why in the code below (1)adding the type signature moved the error from the body of `dot_k` into the call-site inside `test`, and then (2) editing `test` to call `dot_k` with `k=2` _fixed_ the error?
])

#figure(
    image("../img/04-arrays-dotk-strict.gif", width:83%),
    caption: [A strict version of `dot_k` that requires `k <= N`],
)

== Summary

Rust's (sized) arrays are great, and Flux's refinements make them even better,
by ensuring indices are guaranteed to be within the arrays bounds. Const generics
let us write functions that are polymorphic over array sizes, and again, refinements
let us precisely track those sizes to prevent out-of-bounds errors!
*/
