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
        abs_path(File::Spec->rel2abs('../lib/', dirname(abs_path($0)))),
        ); # https://stackoverflow.com/a/46550384

# turn on features
    use builtin qw(true false is_bool reftype);
    no warnings 'experimental::builtin';
    use feature 'try';
    no warnings 'experimental::try';

    our $VERSION = version->declare('v2023.04.18');
# end prelude
use Gradescope::Color qw(color_print);

my %options;
GetOptions(\%options,
    'help|h|?',
    ) or pod2usage(-exitval => 1, -verbose => 2);
pod2usage(-exitval => 0, -verbose => 2) if $options{help};

my $in = do {
    local $/ = undef;
    JSON::from_json <STDIN>;
};
my %in = %{$in};
if(scalar(keys %in) == 1){
    my $out = $in{(keys(%in))[0]};
    color_print(JSON::to_json($out, {pretty => 1, canonical => 1}), 'JSON');
}
else{
    confess '[error] stdin is not a singleton kv';
}

# PODNAME:
# ABSTRACT: Gradescope submission script lambda
=pod

=encoding UTF-8

=head1 SYNOPSIS

singletonkv2scalar.pl : B<json hash → json>

does not take args

=head1 DESCRIPTION

stdin: a json hash with one key
stdout: just the single value

=cut

