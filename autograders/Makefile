default: setup.sh
	# fatpack so we don't have to ship our own modules
	fatpack pack run_test.lean.pl > run_test.fat.pl
	zip AG *
setup.sh: setup.base.sh
	cp setup.base.sh setup.sh
	scandeps.pl run_test.lean.pl -V | perl -ne 'print if m/\#.*X.*\?/ and !m/\[X\]/' | perl -e 'local $$/ = undef; $$in = <STDIN>; $$kv = eval "{$$in}"; print "cpanm $$_\n" for keys %$$kv' >> setup.sh
clean:
	-rm AG.zip

.PHONY: default install-deps clean
