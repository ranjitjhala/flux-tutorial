# Find all typ files matching the pattern ??-*.typ
TYP_FILES := $(wildcard typ/??-*.typ)
# Convert typ file paths to corresponding md file paths
MD_FILES := $(patsubst typ/%.typ,md/tutorial/%.md,$(TYP_FILES))
RS_FILES := $(patsubst typ/%.typ,src/ch%.rs,$(TYP_FILES))

all: main.pdf md-files rs-files

main.pdf:
	typst compile typ/main.typ main.pdf

md-files: $(MD_FILES)

md/tutorial/%.md: typ/%.typ
	@mkdir -p md/tutorial
	pandoc $< -t gfm -o $@
	@./scripts/markdown.sh $@

rs-files: $(RS_FILES)

src/ch%.rs: typ/%.typ
	@mkdir -p src
	@./scripts/rust.sh $< > $@

clean:
	rm -f main.pdf
	rm -rf md/tutorial/*.md
	rm -rf src

.PHONY: md-files
