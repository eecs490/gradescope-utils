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
    # `capture_stdout` for backticks w/o shell
    use Capture::Tiny qw(:all);
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

    our $VERSION = version->declare('v2022.11.13');
# end prelude
use Gradescope::Translate;

my %options;
GetOptions(\%options,
    'help|h|?',
    'fun|lambda|f|λ=s@',
    'token2uniqname|t=s'
) or pod2usage(-exitval => 1, -verbose => 2);
pod2usage(-exitval => 0, -verbose => 2) if $options{help} || @ARGV < 1;

$options{fun} //= ['cat'];

my ($submissions_zip) = @ARGV;
$submissions_zip = abs_path($submissions_zip);
my $tmpdir = File::Temp->newdir();
capture_stdout {
    system('cp', $submissions_zip, $tmpdir)
}, $? >> 8 && confess;
capture_stdout {
    system('unzip', '-d', $tmpdir, File::Spec->catfile($tmpdir, basename($submissions_zip)))
}, $? >> 8 && confess "'${\(File::Spec->abs2rel($submissions_zip))}' is probably not a zip";
my $assignment_export = glob File::Spec->catfile($tmpdir, 'assignment*export');
my %md_yaml = %{(YAML::XS::LoadFile(File::Spec->catfile($assignment_export, 'submission_metadata.yml')))[0]};
my %output; # uniqname ↦ submission	perl hash accumulator
for my $submission_id (keys %md_yaml){
    use Email::Address::XS (); # use an actual email address parser instead of regex
    # NOTE: I think submitters/email isn't actually who submitted, but the name/email associated w/ the submission's student
    # (that is, if I upload for a student, the email is still the student's email)
    my $email = $md_yaml{$submission_id}->{':submitters'}->[0]->{':email'};
    my $uniqname = Email::Address::XS->new(address => $email)->user();
    my $submission_dir = File::Spec->catdir($assignment_export, $submission_id);
    my ($submission) = capture_stdout {
        system(@{$options{fun}}, $submission_dir)
    };
    $? >> 8 && carp "[error] problem with $submission_id; skipping…";
    $output{$uniqname} = $submission;
}
# dump %output to csv
my @aoa;
@aoa = (['token', 'submission']);
for my $k (sort keys %output){
    @aoa = (@aoa, [$k, $output{$k}]);
}
Gradescope::Translate::print_csv(\@aoa, *STDOUT);
if(defined $options{token2uniqname}){
    $options{token2uniqname} = abs_path($options{token2uniqname});
    # generate trivial token2uniqname
    @aoa = ([$Gradescope::Translate::token2uniqname_key_header, $Gradescope::Translate::token2uniqname_value_header]);
    for my $k (sort keys %output){
        @aoa = (@aoa, [$k, $k]);
    }
    Gradescope::Translate::print_csv(\@aoa, $options{token2uniqname});
}

=pod

=encoding utf8

=head1 NAME

join.pl - Gradescope submission script component

=head1 SYNOPSIS

join.pl [options] gradescope_export_submissions_zip

=head1 DESCRIPTION

prints csv of all submissions to stdout

does B<not> support -

=head1 OPTIONS

=head2 help|h|?

=head2 fun|lambda|f|λ

defaults to F<cat.pl>

=head2 token2uniqname|t=s

=cut
