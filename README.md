# flux-tutorial 

Revamping the flux-tutorial so that the same source `typ/*.typ` can be used to 
generate all of 

1. PDF output (directly from `.typ`)
2. mdbook markdown (by converting `.typ` into `.md` via pandoc)
3. rust source (by converting the `.md` into `.rs` via some script)

When its done, will move into the `flux` repo.

## TODO

- [] finish `typ` ing the `01-refinements.typ`
- [] write `Makefile` to generate the `.md` and `.rs`
- [] test the `.md` 
- [] test the `.rs`
- [] repeat for 02, 03, ..., 08
