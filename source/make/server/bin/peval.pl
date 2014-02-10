#!/usr/bin/perl

use vadmin::vconfig;
use vadmin::data1;
use Win32::ODBC;

#my $host = Win32::NodeName;

my ( $datasession, $key, %srvmgrvars );
my %hup;    #hash of user preferneces


if ( checkerror( %hup = vadmin::vconfig::openlog() ) ) {  
    die;  # create user preference hash or die
} 

my $debug = $hup{DEBUG};

my $reactionid = $ARGV[0] || die "Arguments incorrect.  Try peval.exe reactionid type";
my $type = $ARGV[1] || die "Arguments incorrect.  Try peval.exe reactionid type";

 
#print("RUNNING PEVAL WITH ARGS: @ARGV");
$datasession = custodbcsess($debug, $hup{VODBC}, $hup{USERNAME}, $hup{PASSWORD} );


my $ruledeff = vadmin::data1::getruledef($datasession,$debug,$reactionid) || print "no reaction deffinition found for rule $reactionid\n";

print "rule deff = $ruledeff";

if ($type == 2) {

	eval $ruledeff;
	print $@;
	exit;
	
}
elsif ($type == 4) {

	open(BATFILE, ">./tempbat.bat") || die "coulden't open tempbat";
	print BATFILE $ruledeff;
	close BATFILE;

	exec "tempbat.bat";

} 
else {
	print "Reaction Type not accepted.... dying....";
}



################################
# Moudule specific global vars #
################################


sub custodbcsess{ #odbcsess($DNS,$UID,$PWD)
	my $db;
	my $rethash;
	my ($debug,$DNS,$UID,$PWD) = @_;
	#print  "@_ \n";
	if (!($db=new Win32::ODBC("DSN=$DNS;UID=$UID;PWD=$PWD;"))) {
    print("Error connecting to $DNS");
	print("Error: " . Win32::ODBC::Error());
	}
    else {
     return $db;
  }
}#end odbcsess


#########################################################################
sub checkerror {
    my %ehash = @_;
    if ( $ehash{ERROR} ) {
        print( $ehash{ERROR} );
        return 1;
    }
}
