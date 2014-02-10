
$line = "BASTGT_eConsumerSectorObjMgr_F.log";

#my @fl = split /\_/, $obj->{'FileName'};  #parse the type of component from log file name
my @fl = split /\./, $line;

print "my fl = @fl\n";