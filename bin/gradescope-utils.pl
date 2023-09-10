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
        File::Spec->catdir($ENV{HOME}, '.local', 'share', 'gradescope-utils', 'lib'),
        ); # https://stackoverflow.com/a/46550384
 
# turn on features
    use builtin qw(true false is_bool reftype);
    no warnings 'experimental::builtin';
    use feature 'try';
    no warnings 'experimental::try';

    our $VERSION = version->declare('v2023.05.01');
# end prelude
use Gradescope::Color qw(color_print);

my @ARGV_pristine = @ARGV;
my %options;
GetOptions(\%options,
    'help|h|?',
    'list|l',
);
$ENV{PATH} = "${\(File::Spec->catdir($ENV{HOME}, '.local', 'share', 'gradescope-utils', 'bin'))}:$ENV{PATH}";
my $print_help = sub{
    color_print(scalar(File::Slurp::read_file(File::Spec->catfile($ENV{HOME}, '.local', 'share', 'gradescope-utils', 'README.md'))), 'md');
    exit 0;
};
if($options{help} && @ARGV == 0){
    &$print_help;
}
if($options{list} && @ARGV == 0){
    say basename($_) for (grep {-x} File::Slurp::read_dir(File::Spec->catdir($ENV{HOME}, '.local', 'share', 'gradescope-utils', 'bin'), {prefix => 1}));
    exit 0;
}
&$print_help if @ARGV == 0; # same as help
# fix ARGV for subcommand calls
if(can_run($ARGV_pristine[0])){
    exec(@ARGV_pristine);
}
else{
    croak "[error] `@ARGV_pristine` failed to run";
}

# PODNAME:
# ABSTRACT: Gradescope-Utils wrapper
=pod

=encoding utf8

=head1 NAME

=head1 SYNOPSIS

=head1 DESCRIPTION

See README.md

=cut
