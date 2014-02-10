package vadmin::siebparse;
require Exporter;

our @ISA = qw(Exporter);
our @EXPORT = qw(parse_command_result);  # retuns a hash of arrays from parsed file

# %hoa { LABELS=> @arrayofscalarlabels,
#		 ROWS=>   @arrayofarraysofscalars		
#		 ERROR=>  $scalar # (1-20 are fatal)	
#		 ERRORSTRING=> $scalar - error message
#		}
#The hash will be returned immediately on hitting a error.
# 
#


$VERSION = 1.00;

use strict;

sub parse_command_result
{
	my %hoa;
	my (@newvals,$item,@newcols,$templatestring,@labels,$i);

    local *passedfile = shift;					#localize the filehandle passed
 
	while (<passedfile>) {

		#print "$_\n";

		next unless (!m/^srvrmgr|^\n|\d+ row/);

		if (/ADM-02088/){
			%hoa = (ERROR => 1,ERRORSTRING => $_);  # siebel server not running /recognized
			return %hoa;
		 }

        if (/ADM-02044/){
			%hoa = (ERROR => 10,ERRORSTRING => $_);  # database login problem
			return %hoa;
		 }

		if (/unexpected keyword/){
			%hoa = (ERROR => 30,ERRORSTRING => $_);  # srvrmgr syntax error
			return %hoa;
		 }

		push @newvals, $_;
	}#end while

	@labels =  &parse_labels(shift @newvals);
	$templatestring = &parselengths(shift @newvals);

	my $num = @newvals;
	foreach $item (@newvals) {
		
		#print "LINE =: $item\n";
		eval {
		push @newcols,	[unpack("$templatestring",$item)];	
		};

		if ($@) {
			print "template  =$templatestring\n item = $item\n";
			%hoa = (ERROR => 40,ERRORSTRING => $@);  # not a valid file format
			return %hoa;
		 }


	}

	%hoa = (ROWS => [@newcols],
		LABELS => [@labels]);

return %hoa;

#}  #end parse_command_result


		#################################################################################
			#SUB PARSE_LABELS - a sub routine of parsefile - looks for labels by mask
			#################################################################################

				sub parse_labels
				{ 
					my @labels;
					my $text = shift;
					$text =~ s/\s+/removeme/g; #replaces whitespace and adds removeme

					@labels =  split /removeme/,$text; 
					return @labels;
			
				}




			#################################################################################
			#SUB PARSELENGTHS -- a sub routine of parsefile - parses length of --- strings
			#################################################################################

			sub parselengths { #sub will grab a string,  return a $templatestring that can be used in a unpack statement

			my $var =0;
			my $count = 0;
			my $lval = "";
			my $ival =0;
			my (@template, @identifiers) = ();
			my $templatestring = "";

			my $string = shift;
			$string =~ s/\s+/removeme/g;				#replaces whitespace and adds removeme

			@identifiers =  split /removeme/,$string;	#split on removeme
				
			foreach $var (@identifiers) {
				 $lval = length($var)+1;				#get length, add 1 for the unpack function (which counts from 0)
				 push @template, "A" . $lval;	
				 }
										#foreach  (@template) { print "length = $_\n";}
			$count = @template;			#get number of template lengths          
										#print "Count =$count\n";

			foreach (@template) {		#this function formats a string from template lengths.
				$ival++;				#It must not add an x after the last lenth, that will mess up unpack
										
				if ($ival < $count) {
				$templatestring = $templatestring . $_ . " x ";}
				else { 
				$templatestring = $templatestring . $_ ;}
								
				}
				return $templatestring;
			} # end parselengths

}  #end parse_command_result
