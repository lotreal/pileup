.PHONY:debug

debug:
	bin/build.sh

a:
	bin/build.sh Flash3DPhysics.as

tag:TAGS
TAGS:
	find -L . -name "*.as" | ctags -e -L -
