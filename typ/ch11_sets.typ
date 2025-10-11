#import "../orly-modified.typ": alert

= Set-based Access Control <ch:11_sets>

booger.
Hopefully by this point you have a reasonable idea of the main
tools that Flux provides for refining types to capture correctness
requirements. In this, our first case study, lets see how to use
those tools to implement a simple _role-based access control_ (RBAC)
system, where Flux will help ensure key invariants about the permissions
granted to different users.
//
In doing so, we'll get some more practice with the tools we have already seen, and learn about various other
aspects of Flux, including how to use

1. _Set-valued_ refinements,
2. _Detached_ specifications,
3. Enum _variants_ as indexes,
4. Flux level _refinement functions_,


```fluxhidden
extern crate flux_core;
use crate::rset;
use flux_rs::{assert, attrs::*};
```

== Reflection <ch:10_rbac:reflection>

A bird flying high above our access-control system, or more plausibly,
an LLM attempting to summarize its code, would observe that it consists
of three main entities: _users_ who want to access resources, _roles_
that are assigned to each user, and the _permissions_ that may be granted
to each role.

*Roles* Lets suppose that we want to track three kinds of users:
administrators, members and guests. We might represent these three
roles using a Rust `enum`:

```flux
#[reflect]
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum Roles {
    Admin,
    Member,
    Guest,
}
```

*Reflection*
The key new bit in the  definition of `Role` is the
`#[reflect]` attribute, which tells Flux that we intend
to use variants of this `enum` inside refinements.
//
Why not just automatically `reflect` all `enum`s?
Currently, only a very restricted subset of `enum`s
are reflected: those whose variants take _no_ parameters.
Hence, Flux requires us to explicitly mark such `enum`s
with the `#[reflect]` attribute.
//
For example, we can now write a function
that checks if a given role is an `Admin` and returns `true` if so, and `false`
otherwise.

```flux
#[spec(fn (&Role[@r]) -> bool[r == Role::Admin])]
pub fn is_admin(r: &Role) -> bool {
    match r {
        Role::Admin => true,
        Role::User | Role::Guest => false,
    }
}
```

*EXERCISE:* Complete the specification and implementation of functions
`is_member` and `is_guest` below.

```flux
fn is_guest(r: &Role) -> bool {
    true
}
```

When you are done, all the `assert`
statements in the `test_role` function
should be verified by Flux.
//
By the way, you might wonder why we defined
the `let`-bound `admin` instead of just _directly_
using `Role::Admin`.
//
The reason is that the direct-usage ends up
using a `rustc` feature called const-promotion
which Flux currently does not support (but will very soon!)
```flux
fn test_role() {
  let admin = Role::Admin;
  let member = Role::Member;
  let guest = Role::Guest;
  assert(is_admin(&admin) && !is_admin(&member) && !is_admin(&guest));
  assert(!is_guest(&admin) && !is_guest(&member) && is_guest(&guest));
}
```


== Detached Specifications <ch:10_rbac:detached>

*Permissions* Next, lets define the different kinds of permissions that
users may have to access resources. Again, we can use an `enum` with a
`#[reflect]` attribute.

```flux
#[reflect]
#[derive(Clone, Copy, PartialEq, Eq, Hash)]
pub enum Permissions {
    Read,
    Write,
    Comment,
    Delete,
    Configure,
}
```

*Equality Comparison* While `match` statements are quite handy,
sometimes we will just want to check if two `Role`s or two
`Permissions` are the same, for example, to see if a user's `Role`
grants them a particular `Permission`.
However, here, we hit a little bump on the road:

```flux
fn test_equality() {
    let read = Permissions::Read;
    let write = Permissions::Write;
    assert(read == read);
    assert(read != write);
}
```

Flux is unable to even verify these utterly trivial (dis)equalities! Once we get past
the first few stages of grief, we might realize that this is because of how `==` and `!=`
are implemented in Rust via the `PartialEq` trait.

```rust
trait PartialEq<Rhs = Self> {
    fn eq(&self, other: &Rhs) -> bool;
    fn ne(&self, other: &Rhs) -> bool { !self.eq(other) }
}
```


To do so, we will need

- Motivation: PartialEq for Role
```
flux_core::eq!(Permissions);

fn test_eq_perm(p1: Permissions, p2: Permissions) {
    let read = Permissions::Read; // const-promotion
    let write = Permissions::Write; // const-promotion
    assert(read == read);
    assert(read != write);
}
```

- Detached spec for Role
  - is_guest()
  - PartialEq
- eq! macro link
- eq! for Permissions
  - test

== Set-Valued Refinements <ch:10_rbac:sets>

- RSet, set_empty, set_add, set_is_in, set_union, rset!


== Role Capabilities

- english
- flux defs!
- check_permissions_slow
- check_permissions_fast

== User Invariants

- `User` with spec as comments
- `User` with spec as detached spec
  - tests about good / bad users

== Granting Permissions

- `fn allow()` and `fn deny()`

== Access Control

- Write specs for `read`, `write`, `delete` etc.

== Summary