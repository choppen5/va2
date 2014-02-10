
open(SEARCHFILE, "<proctimer.pl") || print "Could not open file $searchfile : $!";
open(OUTFILE, ">proctimer2.pl") || print "Could not open file $searchfile : $!";
		while (<SEARCHFILE>) {
			
			s/^\>//; # remove 
			print OUTFILE $_;

		}