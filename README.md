# flux-tutorial

Revamping the flux-tutorial so that the same source `typ/*.typ` can be used to
generate all of

1. PDF output (directly from `.typ`)
2. mdbook markdown (by converting `.typ` into `.md` via pandoc)
3. rust source (by converting the `.md` into `.rs` via some script)

When its done, will move into the `flux` repo.

## TODO

- [] move bitvector to ch13 (depends on the reflect stuff)
- [] ch loop