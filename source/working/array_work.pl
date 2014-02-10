#!/usr/bin/perl

@array = ("test", "test2", "test'3");

foreach my $item (@array) {
	$item =~ s/\'/\'\'/g;
	#print "item =$item\n";
	
}

print "array = @array\n";
