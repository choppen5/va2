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
	my $servertaskcommand = shift;

	my $foundlabels = 0;
	while (<passedfile>) {

		#print "parsing passed file $_\n";

		next unless (!m/^srvrmgr|^\n|\d+ row/);

		if (/ADM-02088/){
			%hoa = (ERROR => 1,ERRORSTRING => $_);  # siebel server not running /recognized
			return %hoa;
		 }

        if (/ADM-02044/){
			%hoa = (ERROR => 10,ERRORSTRING => $_);  # database login problem
			return %hoa;
		 }

		if (/ADM-02047/) {
			
			%hoa = (ERROR => 12,ERRORSTRING => $_);  # database login problem
			return %hoa;
		}

		if (/ADM-02049/) {
			
			%hoa = (ERROR => 15,ERRORSTRING => $_);  # server disconnected
			return %hoa;
		}

		if (/unexpected keyword/){
			%hoa = (ERROR => 30,ERRORSTRING => $_);  # srvrmgr syntax error
			return %hoa;
		 }


		#if we are at a line that starts with -- and spaces, get the length of the columns.
		if ($_ =~  /^-+\s+/) {
			$templatestring = &parselengths($_);
			$foundlabels = 1;
			next; #don't add the labels to the array of parsable columns
		}
		
		if ($foundlabels) {
			push @newvals, $_;
		}
		
	}#end while

	#@labels =  &parse_labels(shift @newvals);
	#$templatestring = &parselengths(shift @newvals);

	my $num = @newvals;
	#print "number of newvals = $num\n";
	foreach $item (@newvals) {
		
		#print "LINE =: $item\n";
		
		#we are only looking server task lines, so look for those starting with w+
		#next unless (/^w+/);
		
		eval {
			#if it is a task command, use the regex instead of unpack thing
			if ($servertaskcommand) {
				#print "evaluating a server task line\n";
				my @returnarray = &gettaskline($item);

				my $arraycount = @returnarray;
				#print "array count = $arraycount\n";
				
				if ( $arraycount == 10) {
					push @newcols, [@returnarray];
				}
				
			} else {
				#print "template string = $templatestring\n";
				#print "UNPACKING A COMPONENT line = $item\n";
				push @newcols,	[unpack("$templatestring",$item)];
			}
		};

		if ($@) {
			print "ERROR UNPACK PATERN template  =$templatestring\n item = $item\n";
			%hoa = (ERROR => 40,ERRORSTRING => $@);  # not a valid file format
			#return %hoa;
		 }


	}

	%hoa = (ROWS => [@newcols],
		LABELS => [@labels]);

	return %hoa;

#}  #end parse_command_result


}  #end parse_command_result


sub gettaskline {
	my $line = shift;
	#print $line;
	my @taskarray;
	my $match;
	if ($line =~ /([a-zA-Z_0-9-]+)\s+(\w+)\s+(\d+)\s+(\d+|\s+)\s+(.*?)\s\s(\w+)\s+(\d+\D\d+\D\d+\s\d+\D\d+\D\d+)\s{2,}(\d+\D\d+\D\d+\s\d+\D\d+\D\d+|\s+)\s+(.*?)\s{2,}(\w+)/) {

						my $svname = $1;
						my $cc_alias =$2;
						my $tk_taskid = $3;
						my $tk_pid = $4;
						my $tk_disp_runstate = $5;
						my $cc_runmode = $6;
						my $tk_start_time = $7;
						my $tk_end_time = $8;
						my $tk_status = $9;
						my $cg_alias = $10;

						@taskarray = ($svname,$cc_alias,$tk_taskid,$tk_pid,$tk_disp_runstate,$cc_runmode,$tk_start_time,$tk_end_time,$tk_status,$cg_alias);
						#print "matched server task!!!!!!!!";
						$match = 1;
	}

	if ($match) {
		return @taskarray;
	} else {
		return 0;
    }
	


}


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

			print "TEMPLATE STRING TO PARSE = $string\n";
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