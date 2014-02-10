package va2analysisrules;

use vadmin::data1;

sub deactivate {
		
		my $arulename = shift;

		my $sql = "update analysis_rule set active = 'N' where name = '$arulename '";
		
		vadmin::data1::execsql($main::datasession,$main::debug,$main::lh,$sql);

}


1;

