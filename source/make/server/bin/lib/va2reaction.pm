package va2reaction;

use vadmin::data1;

sub sendsiebelcommand {
		
		my $reactionid = shift;
		my $siebserver = shift;

		sendsysmsg($main::datasession,$main::debug,$main::lh,3,$reactionid,$siebserver,$siebserver);

}


sub createreaction {

	my $name=shift;
	my $host= shift;
	my $siebelserver_name = shift;
	my $reactionstring = shift;


	my $reactionid = insert_reaction($main::datasession,$main::debug,$main::lh,3,$name,$host,$siebelserver_name,$reactionstring);

	
	return $reactionid;

}

1;