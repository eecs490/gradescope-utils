#!/usr/bin/env perl

use v5.32;
use utf8;
use strict;
use warnings FATAL => 'all';
use open qw(:utf8) ;
BEGIN{$diagnostics::PRETTY = 1}
use diagnostics -verbose;

use Cwd qw(abs_path);
use File::Basename qw(dirname);
use File::Spec;
use lib (
    dirname(abs_path($0)),
    abs_path(File::Spec->rel2abs('../lib/', dirname(abs_path($0)))),
    ); # https://stackoverflow.com/a/46550384
use Carp;
use Carp::Assert;
use Pod::Usage;
use File::Slurp;
use Text::CSV;
use JSON;

use Translate qw(token2uniqname);

pod2usage(0) if @ARGV;
# force user to fill out config
my %config = (
    'submissions path' => undef,
    'output dir path' => undef,
    'key header(s)' => undef, # in Text::CSV::csv key encoding
    'value header(s)' => undef, # ditto
    'submission filter for student' => sub :prototype(\%$){
            confess 'need to set this later!';
            # see bottom for return type$
        },
    'sort filtered submission keys' => sub :prototype(@){
            confess 'need to set this later';
            # see bottom for return type$
        },
    'filtered submission to csv' => sub :prototype(\%){
            # in Text::CSV::csv in encoding
            confess 'need to set this later!';
            # see bottom for return type$
        },
);
my @required_fields = keys %config;
# NOTE: actually set fields
$config{'submissions path'} = '../quiz.csv';
$config{'output dir path'} = 'mcq';
$config{'key header(s)'} = [':', 'token', 'question_id'];
$config{'value header(s)'} = 'answer';
$config{'submission filter for student'} = sub :prototype(\%$){
    (my $submissions, my $token) = @_;
    my %filtered;
    #assert(!defined $$submissions{$token}); # why is the following line there? Just leftover from times gone by? But I feel like I remember it doing something weird
    #$filtered{$token} = $$submissions{$token};
    # I suppose this is ONE way to check that the k/v transform worked correctly
    my @interested = grep {m/$token:(\d+)/ && 0 <= $1 && $1 <= 5} keys %$submissions;
    @filtered{@interested} = @$submissions{@interested};
    delete @filtered{grep {!defined $filtered{$_}} keys %filtered};
    return %filtered;
};
$config{'sort filtered submission keys'} = sub :prototype(@){
    sort {
        $a =~ m/(\S+):(\S+)/ or confess "Failed to match. $!";
        my $a_question_id = $2;
        $b =~ m/(\S+):(\S+)/ or confess "Failed to match. $!";
        my $b_question_id = $2;
        $a_question_id <=> $b_question_id; # ascending sort
    } @_;
};
$config{'filtered submission to csv'} = sub :prototype(\%){
    my %filtered = %{$_[0]};
    my @rows;
    foreach my $k ($config{'sort filtered submission keys'}(keys %filtered)){
        @rows = (@rows, [$k, $filtered{$k}]);
    }
    #my @temp = %filtered;
    #while(@temp){
    #    @rows = (@rows, [shift @temp, shift @temp]);
    #}
    # the header prepended should correspond to $config{'key header(s)'} and $config{'value header(s)'}
    return [['token:question_id', 'answer'], @rows];
};

grep {!defined} @config{@required_fields} and confess 'Fill out %config!';

if(-e $config{'output dir path'}){
    if(-d _){
        confess 'nonempty dir!' if @{File::Slurp::read_dir($config{'output dir path'})};
    }
    else{
        confess 'something else already there!';
    }
}
else{
    mkdir $config{'output dir path'} or confess "couldn't create output dir!";
}

my %submissions = %{Text::CSV::csv({
    # attributes (OO interface)
    binary => 0,
    decode_utf8 => 0,
    strict => 1,
    # `csv` arguments
    in => $config{'submissions path'},
    encoding => 'UTF-8',
    key => $config{'key header(s)'},
    value => $config{'value header(s)'},
}) or confess Text::CSV->error_diag};

my %token2uniqname = token2uniqname();
for my $t (keys %token2uniqname){
    my %filtered = $config{'submission filter for student'}(\%submissions, $t);
    next if keys %filtered == 0;
    Text::CSV::csv(
        # attributes (OO interface)
        binary => 0,
        decode_utf8 => 0,
        strict => 1,
        # `csv` arguments
        in => $config{'filtered submission to csv'}(\%filtered),
        out => "$config{'output dir path'}/$t.csv",
        encoding => 'UTF-8',
    );
}

=pod

=encoding utf8

=head1 NAME

gen_submissions - Gradescope submission script component

=head1 SYNOPSIS

gen_submissions.pl

Does not take arguments

=head1 DESCRIPTION

=head2 config

'submissions path' := csv of (raw) submission data; all student data in one file

'output dir path' := directory to put generated submissions

'key header(s)' := turn submission data into key/value by aggregating these headers as a key, joined with first delimiter

'value header(s)' := turn submission data into key/value. But not sure the semantics of aggregating value headers, so just use a single header

'submission filter for student' := function that takes reference to k/v submission data and student token, returns k/v pairs relevant to that student

'sort filtered submission keys' := function that takes list of student submission keys and sorts them in some nice order

'filtered submission to csv' := function that takes reference to k/v filtered submissions, returns list of csv rows

=head1 SEE ALSO

./Translate.pm

./upload.pl

=cut