#!/usr/bin/perl -w
use strict;

use FindBin qw( $RealBin );
use File::Spec::Functions qw( catfile catdir );
use File::Slurp qw( read_file );
use File::Path qw( mkpath );

my $history = catdir($RealBin, 'history');
my @urlFiles = glob catfile($history, '*.url');

foreach my $urlFile (@urlFiles) {
	my ($tag) = ($urlFile =~ m! /([^/]+)\.url$ !ix) or die "invalid filename, contains no tag: $urlFile (the glob was supposed to make this never happen)\n";
	
	my $url = read_file($urlFile) or (warn "$urlFile could not be slurped\n" and next);
	$url =~ s/^\s+//;
	$url =~ s/\s+$//;
	
	warn "$urlFile is empty\n" and next if $url eq '';
	
	mkpath(catdir($history, $tag));
	
	print "$urlFile: $url ($tag)\n";
}
