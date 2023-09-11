#!/usr/bin/env perl

use v5.36;
use utf8;
use strictures 2; # nice `use strict`, `use warnings` defaults
use open qw(:utf8); # try to use Perl's internal Unicode encoding for everything
BEGIN{$diagnostics::PRETTY = 1} # a bit noisy, but somewhat informative
use diagnostics -verbose;

# Carp
    use Carp;
    use Carp::Assert;
# filepath functions
    use Cwd qw(abs_path);
    use File::Basename qw(basename dirname);
    use File::Spec;
# misc file utilities
    use File::Temp;
    use File::Slurp;
    use Text::CSV;
    use JSON;
    use YAML::XS;
# misc scripting IO utilities
    use IO::Prompter;
    # `capture_stdout` for backticks w/o shell (escaping issues)
    use Capture::Tiny qw(:all);
    # for more complicated stuff
    # eg timeout, redirection
    use IPC::Run;
# option/arg handling
    use Getopt::Long qw(:config gnu_getopt auto_version); # auto_help not the greatest
    use Pod::Usage;
# use local modules
    use lib (
        dirname(abs_path($0)),
        ); # https://stackoverflow.com/a/46550384

# turn on features
    use builtin qw(true false is_bool reftype);
    no warnings 'experimental::builtin';
    use feature 'try';
    no warnings 'experimental::try';

    our $VERSION = version->declare('v2023.02.14');
# end prelude

my ($token) = @ARGV;
my $in = do {
    local $/ = undef;
    JSON::from_json <STDIN>;
};
say STDERR $token;
print JSON::to_json (JSON::from_json $in);

# PODNAME:
# ABSTRACT: Gradescope submission script lambda
=pod

=encoding UTF-8

=head1 SYNOPSIS

string2json.pl : B<json string → json>

map.pl -f ./string2json.pl

=head1 DESCRIPTION

unwraps quoted json string

stdin: json as json string
stdout: json

args are ignored

often used to undo stringification by F<cat.pl>,
which quotes the student submission as a json string

=head1 EXAMPLES

``on the wire"

    "\"abc\"" ↦ " "abc"

ie

    printf '"\\"abc\\""' | ./string2json.pl token

likewise

    "[]" ↦ []

while

    printf '[]' | ./string2json token

will fail

=cut

