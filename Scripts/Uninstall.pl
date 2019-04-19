#!/usr/bin/perl

use strict;
use warnings;

use autodie;

open(my $out, ">", "/tmp/path.txt") or die "Can't open for output path.txt: $!";
open(my $in, "<", "/tmp/path.txt") or die "Can't open for input path.txt: $!";

my @files_name=("prometheus", "alertmanager", "node_exporter", "prometheus-files");

foreach my $line ( @files_name ){
	print $out `sudo find / -name $line`;
  my @list = `find /etc/systemd/system/ -name $line.service | grep $line.service`;
	foreach my $file ( @list ){
		print $file;
		system "sudo systemctl disable $line.service && sudo systemctl stop $line.service && sudo rm -rf /etc/systemd/system/$line.service";
	} 
}

foreach my $line ( <$in> ) {
	system "sudo rm -rf $line";
}



close $out or die "$out: $!";
close $in or die "$in: $!";
