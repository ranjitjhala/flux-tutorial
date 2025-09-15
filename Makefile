# Find all typ files matching the pattern ??-*.typ
TYP_FILES := $(wildcard typ/??-*.typ)
# Convert typ file paths to corresponding md file paths
MD_FILES := $(patsubst typ/%.typ,md/%.md,$(TYP_FILES))
RS_FILES := $(patsubst typ/%.typ,src/%.rs,$(TYP_FILES))

all: main.pdf md-files rs-files

main.pdf:
	typst compile typ/main.typ main.pdf

md-files: $(MD_FILES)

md/%.md: typ/%.typ
	@mkdir -p md
	pandoc $< -o $@
	@./scripts/markdown.sh $@

rs-files: $(RS_FILES)

src/%.rs: typ/%.typ
	@mkdir -p src
	@./scripts/rust.sh $< > $@

clean:
	rm -f main.pdf
	rm -rf md
	rm -rf src

.PHONY: md-files
