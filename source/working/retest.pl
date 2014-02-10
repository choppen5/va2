
$line = "GenericLog	GenericError	1	0	2007-07-16 22:23:04	(sasess.cpp (597)";

if ($line =~ /GenericError/) {
	print "matched GenericError!\n";
}

if ($line =~ /this|sasess/) {
	print "matched this or sasess!\n";
}

if ($line =~ /GenericError.*sasess/) {
	print "matched this AND sasess!\n";
}

if ($line =~ /\w+.\w+\s/) {
	print "matched a word (\w+) AND a period (.)  AND another word (\w+), AND a single space (\s). Like so: sasess.cpp \n";
}