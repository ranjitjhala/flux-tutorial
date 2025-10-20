#import "../orly-modified.typ": alert

= Dynamic Access Control <ch:11_sets>

```fluxhidden
extern crate flux_core;
use flux_rs::{assert, attrs::*};
use std::hash::Hash;

defs!{
    fn set_emp<T>() -> Set<T> {
        set_empty(0)
    }

    fn set_add<T>(x: T, s: Set<T>) -> Set<T> {
        set_union(set_singleton(x), s)
    }

    fn set_del<T>(x:T, s: Set<T>) -> Set<T> {
        set_difference(s, set_singleton(x))
    }

    fn set_is_disjoint<T>(s1: Set<T>, s2: Set<T>) -> bool {
        set_intersection(s1, s2) == set_emp()
    }
}
```

Previously, in @ch:10_equality, we saw how to write a simple
role-based access control system, where each `Role` has a
_fixed_ set of `Permissions` associated with it, and each
`User` can only access the resources that their `Role`
allows.
//
Next, lets see how to generalize that to build
a _dynamic_ access control mechanism, where permissions
can be _added_ or _removed_ from users at runtime, while
still ensuring that they can only access resources allowed
by their `Role`.
//
To do so we will use _set-valued_ refinements to track the
set of permissions that each user currently has.

== Roles & Permissions

Lets begin by recalling the whole business of roles and permissions.

*Roles* As before, we have three kinds of users: admins, members and guests.
This time, we will _derive_ `PartialEq` and then use the `flux_core::eq!` macro
to generate the boilerplate detached specifications needed to compare two `Role`s
(described in @ch:10_equality:detached).

```flux
#[reflect]
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum Role {
    Admin,
    Member,
    Guest,
}
flux_core::eq!(Role);
use Role::*;
```

*Permissions* Next, lets define the different kinds of permissions that
users may have to access resources, using `#[reflect]` to let us talk
about `Permissions` in refinements, and the `eq!` macro to let us compare them.

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
flux_core::eq!(Permissions);
use Permissions::*;
```

== Set-Valued Refinements

Instead of statically hardwiring a `User`'s permissions to their `Role`,
our dynamic access control system will let us _add_ or _remove_ permissions
from a user at runtime. However, we will want to still enforce important
correctness requirements at compile time, and hence, require a way to
track the _set of permissions_ a user has at any given point.

*Refined Sets* To do so, we can use a _refined Set_ library
provided by the `flux-rs` crate, which like the refined-vectors
(described in @ch:06_vectors) are just a wrapper around Rust's
standard `HashSet` but where we track the actual _elements_ in the
set via a _set-valued_ refinement index `elems` whose sort is `Set<T>`,
where `T` is the type of elements in the set. That is, just like
we were tracking the `int`-valued vector _size_ in @ch:06_vectors,
here we're tracking the `Set<T>`-valued _elems_.

```flux
#[opaque]
#[refined_by(elems: Set<T>)]
#[derive(Debug)]
pub struct RSet<T> {
    pub inner: std::collections::HashSet<T>,
}
```

*Creating Sets*
The `RSet` API has a method to create an `new` set (which is empty),
and a method to add an element to a set, which _updates_ the set
refinement to include the new `elem` element, using the refinement
level `set_add` operation.

```flux
#[trusted]
impl<T> RSet<T> {
  #[spec(fn() -> RSet<T>[set_emp()])]
  pub fn new() -> RSet<T> {
    let inner = std::collections::HashSet::new();
    RSet { inner }
  }

  #[spec(fn(self: &mut RSet<T>[@s], elem: T)
         ensures self: RSet<T>[set_add(elem, s)])]
  pub fn insert(self: &mut Self, elem: T)
  where
    T: Eq + Hash,
  {
    self.inner.insert(elem);
  }
}
```

*Membership* Next, lets write a `contains` method to test if an element is in an `RSet`.


```flux
impl<T> RSet<T> {
  #[spec(fn(set: &RSet<T>[@s], &T[@elem]) -> bool[set_is_in(elem, s.elems)])]
  pub fn contains(self: &Self, elem: &T) -> bool
  where
    T: Eq + Hash,
  {
    self.inner.contains(elem)
  }
}
```

We can now check that are refinement-leve tracking is working as expected:

```flux
fn test_set_add() {
  let read = Permissions::Read;
  let write = Permissions::Write;
  let mut s = RSet::new();
  s.insert(read);
  assert(s.contains(&read) && !s.contains(&write));
  s.insert(write);
  assert(s.contains(&read) && s.contains(&write));
}
```

*An `rset!` Macro*
Our API has enough mojo to implement a simple `rset!` macro that will
let us create `RSet`s with a more convenient syntax:

```flux
#[macro_export]
macro_rules! rset {
    () => { RSet::new() };
    ($($e:expr),+$(,)?) => {{
        let mut res = RSet::new();
        $( res.insert($e); )*
        res
    }};
}
```

We can kick the tires on the macro,

```flux
fn test_rset_macro() {
  let read = Permissions::Read;
  let write = Permissions::Write;
  let s = rset![read, write];
  assert(s.contains(&read) && s.contains(&write));
}
```

*Union & Intersection*
Next, it will be convenient to have operations that compute
the `union` and `intersection`, of two sets. We can implement these
using the corresponding operations on Rust's `HashSet`:

```flux
#[trusted]
impl<T : Eq + Hash + Clone> RSet<T> {
  #[spec(fn(&RSet<T>[@self], &RSet<T>[@other]) ->
         RSet<T>[set_intersection(self, other)])]
  pub fn intersection(&self, other: &RSet<T>) -> RSet<T> {
    let inner = self.inner.intersection(&other.inner).cloned().collect();
    RSet { inner }
  }

  #[spec(fn(&RSet<T>[@self], &RSet<T>[@other]) ->
            RSet<T>[set_union(self, other)])]
  pub fn union(&self, other: &RSet<T>) -> RSet<T> {
    let inner = self.inner.union(&other.inner).cloned().collect();
    RSet { inner }
  }
}
```

Notice that for each method `union`, `intersection`, the output type is
indexed by the corresponding refinement-level operation on the input sets.
Lets test these out.

#alert("success", [
*EXERCISE*: Fix the conditions in the `assert`s below so they verify.
You may want to split them into _multiple_ asserts to determine which
ones fail.
])

```flux
fn test_union_intersection() {
  let rd = Permissions::Read;
  let wr = Permissions::Write;
  let cm = Permissions::Comment;
  // make two sets
  let s1 = rset![rd, wr];
  let s2 = rset![wr, cm];
  // check union
  let su = s1.union(&s2);
  assert(!su.contains(&rd) && !su.contains(&wr) && !su.contains(&cm));
  // check intersection
  let si = s1.intersection(&s2);
  assert(!si.contains(&rd) && !si.contains(&wr) && !si.contains(&cm));
}
```

*Subset* Finally, it will be useful to check if one set is a
_subset_ of another, that is, that all the elements of one set
are also present in the other.

```flux
#[trusted]
impl<T: Eq + Hash> RSet<T> {
  #[spec(fn(&RSet<T>[@self], &RSet<T>[@other]) ->
         bool[set_subset(self, other)])]
  pub fn subset(&self, other: &RSet<T>) -> bool {
    self.inner.is_subset(&other.inner)
  }
}
```

We can now test some properties of `union`, `intersection` and `subset`,
for example, that the union of two sets _contains_ both sets, and the
intersection _is contained in_ both sets.

```flux
fn test_subset(s1: &RSet<Permissions>, s2: &RSet<Permissions>) {
  let su = s1.union(&s2);
  assert(s1.subset(&su) && s2.subset(&su));

  let si = s1.intersection(&s2);
  assert(si.subset(&s1) && si.subset(&s2));
}
```

#alert("success", [
*EXERCISE*: Correct the implementation of the `equals` method so that it verifies.
Note that the `==` operator is legal for the `Set<T>` sort _inside refinements_ but it
cannot be used in Rust _code_ as we did not define `PartialEq` for `RSet<T>`.
])

```flux
impl<T: Eq + Hash> RSet<T> {
  #[spec(fn(&RSet<T>[@self], &RSet<T>[@other]) -> bool[self == other])]
  pub fn equals(&self, other: &RSet<T>) -> bool {
    true // fix this
  }
}
```

== The Set of Permissions of Each Role

// Now that we have a little library for working with sets --- whose API precisely
// tracks the _elements_ in those sets via set-valued refinements --- we can return
// to our original goal of building a dynamic access control system.


Lets use our refined `RSet` library to build a dynamic access control system.
//
As before, each `Role` has a fixed set of `Permissions`
associated with it.
//
However, this time, we will specify these
as a refinement-level function (see @ch:10_equality:refinement-level-functions)
that maps each `Role` to the _maximal_ set of `Permissions`
for that role.

```flux
defs! {
    fn perms(r:Role) -> Set<Permissions> {
        if r == Role::Admin {
          set_add(Permissions::Read,
          set_add(Permissions::Write,
          set_add(Permissions::Delete,
          set_add(Permissions::Configure, set_emp()))))
        } else if r == Role::Member {
          set_add(Permissions::Read,
          set_add(Permissions::Write,
          set_add(Permissions::Comment, set_emp())))
        } else { // Role::Guest
          set_add(Permissions::Read, set_emp())
        }
    }
}
```

*A Slow Implementation* The above `permissions`
is a _refinement-level_ function that Flux refinements
can use to _specify_ access control requirements.
//
Fill in the method below that _computes_ the set
of `permissions` valid for a `Role`.

```flux
impl Role {
  #[spec(fn(&Self[@r]) -> RSet<Permissions>[perms(r)])]
  pub fn permissions(&self) -> RSet<Permissions> {
    match self {
      Admin => rset!{},     // fill these in!
      Member => rset!{},    // fill these in!
      Guest => rset!{},     // fill these in!
    }
  }
}
```

When you are done with the above, we can use it to implement a method
that _checks_ if a given `Permission` is allowed for a `Role`.


```flux
#[spec(fn(&Self[@r], &Permissions[@p]) -> bool[set_is_in(p, perms(r))])]
pub fn check_permission_slow(&self, p: &Permissions) -> bool {
    self.permissions().contains(p)
}
```


*A Fast Implementation*
//
The `check_permission_slow` method above is correct, in that Flux proves that
it returns `true` exactly if the given permission is allowed for the role.
However, it is inefficient since we spin up a bunch of sets and membership queries
to do the check.

#alert("success", [
*EXERCISE*:
Complete the below implementation of an efficient (_and_ correct)
check using pattern-matching and equality comparisons.
])

```flux
#[spec(fn(&Self[@r], &Permissions[@p]) -> bool[set_is_in(p, perms(r))])]
pub fn check_permission(&self, p: &Permissions) -> bool {
  let admin = Role::Admin;                // use this
  let guest = Role::Guest;                // use this
  let user = Role::Member;                // use this
  match p {
    Permissions::Read => true,            // fix this
    Permissions::Write => true,           // fix this
    Permissions::Comment => true,         // fix this
    Permissions::Delete => true,          // fix this
    Permissions::Configure => true,       // fix this
  }
}
```

== Users with Dynamic Permissions

The "dynamic" part of this access control system is that we want
the ability to _add_ or _remove_ permissions from a user at runtime,
while still ensuring that they can only access resources allowed by
their role.
//
To do so, we will define a `User` struct that, in addition to a `role`,
will have two fields `allowed` and `denied` that will track the
set of permissions that have been _added_ or _removed_ from the user
at runtime.

```flux
#[derive(Debug)]
struct User {
  name: String,
  role: Role,
  allow: RSet<Permissions>,
  deny: RSet<Permissions>,
}
```

*Allowed & Denied Permissions* The `allow` and `deny` fields
respectively track the set of permissions that _have been_ granted
and _should never be_ granted to the `User`. Of course, we want these
fields to always satisfy some important invariants.

1. The `allow`ed permissions should always be a _subset_ of the permissions
   associated with the user's `role`. That is, we can only allow permissions
   that are valid for the user's role;

2. The `allow`ed permissions should never contain any permission that has
   already been `denied`; that is, the `allow`ed and `deny`ed sets should
   always be _disjoint_.

*Enforcing Invariants*

Lets use the detached specification mechanism --- described
in @ch:10_equality:detached --- to enforce these invariants
by _refining_ the struct to track the `role` and `allow` and
`deny` sets as indices and then specifying the requirements
above as `#[invariant]`s on the refined struct.

```flux
#[specs {
 #[refined_by(role:Role, allow:Set<Permissions>, deny:Set<Permissions>)]
 #[invariant(set_subset(allow, perms(role)))]
 #[invariant(set_intersection(allow, deny) == set_emp())]
 struct User {
    name: String,
    role: Role[role],
    allowed: RSet<Permissions>[allow],
    denied: RSet<Permissions>[deny],
 }
}]
const _: () = ();
```

The two `#[invariant]`s correspond directly to our requirements.
Lets check that Flux will only allow constructing legal `User`s
that satisfy these invariants.

#alert("success", [
*EXERCISE*: Can you fix the errors that Flux finds in `alice` and `bob`?
])

```flux
fn test_user() {
    let alice = User {
        name: "Alice".to_string(),
        role: Guest,
        allow: rset!{ Read, Write },
        deny: rset!{ },
    };
    let bob = User {
        name: "Bob".to_string(),
        role: Admin,
        allow: rset!{ Read, Write, Delete },
        deny: rset!{ Write },
    };
}
```

== Dynamically Changing Permissions

Next, lets write methods to create new `User`s and check their permissions:

```flux
impl User {
  #[spec(fn(name: String, role: Role) ->
         Self[User{role:role, allow: set_emp(), deny: set_emp()}])]
  fn new(name: String, role: Role) -> Self {
      Self {
          name,
          role,
          allow: RSet::new(),
          deny: RSet::new(),
      }
  }
}
```

*Allowing Permissions*
//
A newly created `User` only has a `role` but no `allow`ed or `deny`ed `Permissions`,
which ensures the invariants hold.
//
Lets write a method to _add_ a `Permission` to the `allow`ed set of a `User`.
//
Note that we must take care to ensure that the given `Permission` is  valid
for the user's `role` (to satisfy the first invariant) and that it is not
already in the `deny`ed set (to satisfy the second invariant).
//
Thus, we make the method return `true` if the permission was successfully
added, and `false` otherwise.

```flux
impl User {
  #[spec(fn(me: &mut Self[@u], &Permissions[@p]) -> bool[allowed(u, p)]
            ensures me: Self[User{allow: add(u, p), ..u }])]
  fn allow(&mut self, p: &Permissions) -> bool {
    if self.role.check_permission(&p) && !self.deny.contains(&p) {
      self.allow.insert(*p);
      true
    } else {
      false
    }
  }
}
```

In the type above, the refinement-level function `allowed`
checks if a permission _can be added_ to the `allow`ed set,
and the `add` function returns the extended permissions:

```flux
defs! {
  fn allowed(u: User, p: Permissions) -> bool {
    set_is_in(p, perms(u.role)) && !set_is_in(p, u.deny)
  }
  fn add(u: User, p: Permissions) -> Set<Permissions> {
    if allowed(u, p) {
      set_add(p, u.allow)
    } else {
      u.allow
    }
  }
}
```

Notice that the type for the `allow` uses a _strong reference_
described in @ch:03_ownership:strongly-mutable-references,
to _conditionally change_ the type of the `User`
when we _add_ permissions.


```flux
fn test_allow() {
  let read = Read;
  let write = Write;
  let mut guest = User::new("guest".to_string(), Role::Guest);
  assert(guest.allow(&read));           // can allow read
  assert(guest.allow.contains(&read));  // read is now allowed
  assert(!guest.allow(&write));         // cannot allow write
  assert(!guest.allow.contains(&read)); // write is not allowed
}
```

*Denying Permissions* Next, lets write a similar method to _deny_
a permission, by adding it to the `deny`ed set, (as long as it is
not already in the `allow`ed set.


```flux
impl User {
  #[spec(fn(me: &mut Self[@u], &Permissions[@p]) -> bool[deny(u, p)]
            ensures me: Self[User { deny: del(u, p), ..u }])]
  fn deny(&mut self, p: &Permissions) -> bool {
    if !self.allow.contains(p) {
      self.deny.insert(*p); true
    } else {
      false
    }
  }
}
```

#alert("success", [
*EXERCISE*: Correct the definitions of the `deny`
and `del` refinement-level functions so that the
implementation of the `deny` method above verifies.
])

```flux
defs! {
  fn deny(u: User, p: Permissions) -> bool {
    true // fix this
  }
  fn del(u: User, p: Permissions) -> Set<Permissions> {
    set_emp() // fix this
  }
}
```

== Access Control

Finally, we can use the `allow` set to control which `User`s
are allowed to perform certain actions.
//
Unlike in our previous system (@ch:10_equality),
that used the `User`'s _fixed_ `Role`, we can now
use the _dynamic_ `allow` set to make this determination.

```flux
impl User {
  #[spec(fn(&Self[@u]) requires set_is_in(Read, u.allow)))]
  fn read(&self) { /* ... */ }

  #[spec(fn(&Self[@u]) requires set_is_in(Write, u.allow)))]
  fn write(&self) { /* ... */ }

  #[spec(fn(&Self[@u]) requires set_is_in(Comment, u.allow)))]
  fn comment(&self) { /* ... */ }

  #[spec(fn(&Self[@u]) requires set_is_in(Delete, u.allow)))]
  fn delete(&self) { /* ... */ }

  #[spec(fn(&Self[@u]) requires set_is_in(Configure, u.allow)))]
  fn configure(&self) { /* ... */ }
}
```

Flux checks that `User`s have the appropriate permissions to call these methods.

```flux
fn test_access_ok() {
  let configure = Permissions::Configure;
  let alice = User::new("Alice".to_string(), Role::Admin);
  aliceconfigure();        // type error!
  alice.allow(&configure);  // add it to the allowed set
  alice.configure();        // ok!
}
```

== Summary

In this chapter, we saw how to build a dynamic access control system,
by indexing types with _set-valued_ refinements that track users'
permissions, and strong references which _conditionally_ change
types when we mutate references.