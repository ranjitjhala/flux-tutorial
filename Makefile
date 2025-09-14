# Find all typ files matching the pattern ??-*.typ
TYP_FILES := $(wildcard typ/??-*.typ)
# Convert typ file paths to corresponding md file paths
MD_FILES := $(patsubst typ/%.typ,md/%.md,$(TYP_FILES))

main.pdf:
	typst compile typ/main.typ main.pdf

# Pattern rule to convert typ files to md files
md/%.md: typ/%.typ
	@mkdir -p md
	pandoc $< -o $@

# Target to build all markdown files
md-files: $(MD_FILES)
	@echo "Running convert.sh to process flux code blocks in md/ directory..."
	@./convert.sh md/*.md

clean:
	rm -f main.pdf
	rm -rf md

.PHONY: md-files
