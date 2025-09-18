# Find all typ files matching the pattern ??-*.typ
TYP_FILES := $(wildcard typ/ch??_*.typ)
# Convert typ file paths to corresponding md file paths
MD_FILES := $(patsubst typ/%.typ,md/tutorial/%.md,$(TYP_FILES))
RS_FILES := $(patsubst typ/%.typ,crate/src/%.rs,$(TYP_FILES))

all: main.pdf md-files rs-files

main.pdf:
	typst compile main.typ main.pdf

md-files: $(MD_FILES)

md/tutorial/%.md: typ/%.typ
	@mkdir -p md/tutorial
	pandoc $< -t gfm -o $@
	@./scripts/markdown.hs $@
	@mv $@.out $@
	cp -r img/* md/img/

rs-files: $(RS_FILES)

crate/src/%.rs: typ/%.typ
	@mkdir -p crate/src
	@./scripts/rust.hs $< > $@

clean:
	rm -f main.pdf
	rm -rf md/tutorial/*
	rm -rf crate/src/ch*.rs
	rm -rf log

.PHONY: md-files
