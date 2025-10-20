#import "../orly-modified.typ": alert

= Iteration <ch:13_iteration>

```fluxhidden
 use flux_rs::attrs::*;
```

#alert("error", [TODO])

== While Loops

```flux
#[spec(fn(&[f64][@n], &[f64][n]) -> f64)]
fn dot_product_while(a: &[f64], b: &[f64]) -> f64 {
    let mut sum = 0.0;
    let mut i = 0;
    while i < a.len() {
        sum += a[i] * b[i];
        i += 1;
    }
    sum
}
```

== Range Loops

```flux
    // 2. while-with-range
    #[spec(fn(&[f64][@n], &[f64][n]) -> f64)]
    fn dot_product_range(a: &[f64], b: &[f64]) -> f64 {
        let mut sum = 0.0;
        let rng = 0..a.len();
        let mut it = rng.into_iter();
        while let Some(i) = it.next() {
            sum += a[i] * b[i];
        }
        sum
    }
```

== For Loops

```flux
// 3. for-with-range
#[spec(fn(&[f64][@n], &[f64][n]) -> f64)]
fn dot_product_for(a: &[f64], b: &[f64]) -> f64 {
    let mut sum = 0.0;
    for i in 0..a.len() {
        sum += a[i] * b[i];
    }
    sum
}
```

== Enumerate

```flux
    // 4. for-loop with enumerate
    #[spec(fn(&[f64][@n], &[f64][n]) -> f64)]
    fn dot_product_enumerate(a: &[f64], b: &[f64]) -> f64 {
        let mut sum = 0.0;
        for (i, vi) in a.iter().enumerate() {
            sum += vi * b[i];
        }
        sum
    }
```

== Foreach with Closure

```flux
#[spec(fn(&[f64][@n], &[f64][n]) -> f64)]
fn dot_product_foreach(a: &[f64], b: &[f64]) -> f64 {
    let mut sum = 0.0;
    (0..a.len()).for_each(|i| sum += a[i] * b[i]);
    sum
}
```

== Map with Closure

```flux
#[spec(fn(&[f64][@n], &[f64][n]) -> f64)]
  fn dot_product_map(a: &[f64], b: &[f64]) -> f64 {
    (0..a.len()).map(|i| (a[i] * b[i])).sum()
}
```
