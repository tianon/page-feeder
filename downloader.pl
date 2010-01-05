#!/usr/bin/perl -w
use strict;

# this script was meant to run on an hourly cron job or similar

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
	
	my $tagDir = catdir($history, $tag);
	
	mkpath($tagDir);
	
	# glob the current files in tagDir, so that we can check if the file we are about to download is the same as the most recent one (and delete the new one if it is)
	my @oldFiles = reverse sort glob catfile($tagDir, '????-??-??--??-??-??');
	my $oldest = '';
	$oldest = shift @oldFiles if @oldFiles;
	
	# poor man's solution, for now
	my $curDate = qx'echo -n "`date +"%Y-%m-%d--%H-%M-%S"`"';
	my $newFile = catfile($tagDir, $curDate);
	system('wget', '-q', '-O', $newFile, $url) == 0 or die "system failed: $?\n";
	
	if ($oldest ne '') {
		my $oldContents = read_file($oldest);
		my $newContents = read_file($newFile);
		
		# this could be done better, like with md5 hashes or something...
		if ($oldContents eq $newContents) {
			unlink $newFile; # if the new one is exactly the same as the one just previous, we want to completely ignore the bugger
		}
		else {
			my $feedCache = catfile($tagDir, 'feed_cache.xml');
			unlink $feedCache if -e $feedCache;
		}
	}
}
