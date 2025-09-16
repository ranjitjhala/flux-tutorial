# Find all typ files matching the pattern ??-*.typ
TYP_FILES := $(wildcard typ/ch??_*.typ)
# Convert typ file paths to corresponding md file paths
MD_FILES := $(patsubst typ/%.typ,md/tutorial/%.md,$(TYP_FILES))
RS_FILES := $(patsubst typ/%.typ,src/%.rs,$(TYP_FILES))

all: main.pdf md-files rs-files

main.pdf:
	typst compile main.typ main.pdf

md-files: $(MD_FILES)

md/tutorial/%.md: typ/%.typ
	@mkdir -p md/tutorial
	pandoc $< -t gfm -o $@
	@./scripts/markdown.sh $@
	cp -r typ/figs/* md/

rs-files: $(RS_FILES)

src/%.rs: typ/%.typ
	@mkdir -p src
	@./scripts/rust.sh $< > $@

clean:
	rm -f main.pdf
	rm -rf md/tutorial/*.md
	rm -rf src/ch*.rs

.PHONY: md-files
