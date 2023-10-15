# https://stackoverflow.com/a/25668869
EXECUTABLES = curl hugo
K := $(foreach exec,$(EXECUTABLES),\
        $(if $(shell which $(exec)),some string,$(error "No $(exec) in PATH")))

ifeq ($(shell uname -s),Linux)
	OE_ARCH := Linux-x86_64
else
	OE_ARCH := MacOS-x86_64
endif

CURL:=curl -s -L

layout-filenames:=render-image.html render-link.html
layout-files:=$(foreach f, $(layout-filenames), layouts/_default/_markup/$(f))

.DEFAULT_GOAL := preview
.PHONEY := test browser server article.% code.% gallery.% status.% local \
	obsidian-export clean-content drafts preview production clean-public

# ----------------------------------
# Actual file based targets

$(layout-files):
	exec $(CURL) https://raw.githubusercontent.com/haxrob/obsidian-to-hugo-pages/main/layout/$(@F) -o $@

layouts/.touchfile:
	test -d layouts/_default/_markup || mkdir -p layouts/_default/_markup
	touch layouts/.touchfile

bin/.touchfile:
	test -d bin || mkdir bin
	touch bin/.touchfile

bin: bin/.touchfile

bin/obsidian-export: bin
	exec $(CURL) https://github.com/zoni/obsidian-export/releases/download/v22.11.0/obsidian-export_$(OE_ARCH).bin -o $@
	chmod a+x bin/obsidian-export

# ----------------------------------
# Phoney targets

layouts: layouts/.touchfile | $(layout-files)

clean-content:
	@test -d content || mkdir content
	@rm -Rf content/*

obsidian-export: layouts bin/obsidian-export clean-content bin/obsidian-export
	exec ./bin/obsidian-export ./vault ./content

server: obsidian-export
	hugo server -D --disableFastRender --logLevel debug -b ''

browser:
	exec open http://localhost:1313/

clean-public:
	@test -d public || mkdir public
	@rm -Rf public/*

drafts: obsidian-export clean-public
	exec hugo -D --logLevel debug -e preview -b ''

# ----------------------------------
# Targets for different bilberry theme page types
article.%:
	exec hugo new article/$*/index.md -c vault

status.%:
	exec hugo new status/$*.md -c vault

code.%:
	exec hugo new code/$*/index.md -c vault

gallery.%:
	exec hugo new gallery/$@.md -c vault

# ----------------------------------
# Cloudflare runner targets
preview: obsidian-export
	exec hugo --logLevel debug -e preview -b "$(CF_PAGES_URL)"

production: obsidian-export
	exec hugo --logLevel debug -e production --minify

