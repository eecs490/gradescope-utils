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
    use IPC::Run qw(run);
    use IPC::Cmd qw(can_run);
# option/arg handling
    use Getopt::Long qw(:config gnu_getopt auto_version); # auto_help not the greatest
    use Pod::Usage;
# use local modules
    use lib (
        dirname(abs_path($0)),
        abs_path(File::Spec->rel2abs('../lib/', dirname(abs_path($0)))),
        ); # https://stackoverflow.com/a/46550384
 
# turn on features
    use builtin qw(true false is_bool reftype);
    no warnings 'experimental::builtin';
    use feature 'try';
    no warnings 'experimental::try';

    our $VERSION = version->declare('v2022.12.27');
# end prelude
use Gradescope::Translate;
use Gradescope::Color qw(color_print);

my %options;
GetOptions(\%options,
    'help|h|?',
    'delimiter|d=s',
    'keyheader|k=s@',
    'valueheader|v=s@',
    ) or pod2usage(-exitval => 1, -verbose => 2);
pod2usage(-exitval => 0, -verbose => 2) if $options{help};

$options{delimiter} //= ':';
$options{keyheader} //= ['token'];
$options{valueheader} //= ['submission'];

$options{keyheader} = [$options{delimiter}, @{$options{keyheader}}];

my %kv = Gradescope::Translate::read_csv(*STDIN,
    $options{keyheader}, $options{valueheader});
color_print(JSON::to_json(\%kv, {pretty => 1, canonical => 1}), 'JSON');

# PODNAME:
# ABSTRACT: Gradescope submission script component
=pod

=encoding utf8

=head1 SYNOPSIS

csv2json.pl : B<csv → json hash>

csv2json.pl [options]

csv2json.pl [-k token] [-v uniqname] < I<csv>

=head1 DESCRIPTION

converts a csv to json key-value with perl's Text::CSV and JSON modules

stdin: a csv
stdout: json hash

=head1 OPTIONS

=head2 keyheader|k

csv column header(s) that will for the json hash key

mutliple headers can be specified by repeating C<-k>

=head2 valueheader|v

csv column header(s) that will for the json hash value

mutliple headers can be specified by repeating C<-v>

if multiple headers are specified,
the json value is again a hash, with the value headers for keys

=head2 delimiter|d

if multiple csv column headers are specified,
each column is joined with the specified delimiter
for the json hash key

=cut
