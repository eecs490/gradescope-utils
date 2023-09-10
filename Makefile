# this is huge hack to do a couple things before building with `dzil build`

# we're using `dzil` as the perl build sytem
# but there's bits and pieces that don't fit eg haskell has its own build tools

default: install-deps install-build-deps
	# build our haskell stuff
	cabal install field-n-eq --installdir=./bin/ --install-method=copy
	mv bin/field-n-eq bin/field-n-eq?
	# final
	dzil build # NOTE: you may need to install `dzil` with `cpanm Dist::Zilla`
	dzil test --release # for some reason pod syntax checker requires the --release flag
install.packed.pl:
	cpanm App::FatPacker
	fatpack pack install.pl > install.packed.pl
install: default
	perl install.pl
install-lite:
	perl install.packed.pl
eecs490:
	TMP=$$(mktemp);\
	cp dist.ini $$TMP;\
	perl -pi -e 's/^license.*$$//s' dist.ini;\
	echo '-remove = License' >> dist.ini;\
	$(MAKE);\
	cp $$TMP dist.ini
# install bin/ build dependencies
install-deps:
	# perl
	## getting perl dependencies is really hard
	## this list is mostly manually curated and most likely nonexhaustive
	cpanm Carp::Assert
	cpanm Text::CSV
	cpanm JSON
	cpanm IO::Prompter
	cpanm IPC::Run
	cpanm Test::Pod
	# ruby
	bundler install
	# haskell
	cabal build --only-dependencies
# these are the build system's own dependencies
# (yeah...)
install-build-deps:
	dzil authordeps --missing | cpanm
install-runtime-deps:
	# nonexhaustive list
	cpanm Want
	cpanm strictures
	cpanm Carp::Assert
	cpanm Text::CSV
	cpanm JSON
	cpanm File::Slurp
	cpanm IO::Prompter
	cpanm Capture::Tiny
	cpanm IPC::Run
	cpanm YAML::XS
	cpanm Email::Address::XS
clean:
	dzil clean
clean-full: clean
	-rm -r dist-newstyle
	-rm -r vendor
	-rm install.packed.pl
# rebuild everything for release
package:
	$(MAKE) clean-full
	$(MAKE) install.packed.pl
	$(MAKE)

.PHONY: default install eecs490 install-deps install-build-deps install-runtime-deps clean clean-full package
