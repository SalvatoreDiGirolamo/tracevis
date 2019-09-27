
if ($#ARGV != 1) {
    print "Usage: $0 <trace_file> <bin_file>\n";
    exit;
}

my $file="$ARGV[0]";
my $binfile="$ARGV[1]";

open my $info, $file or die "Could not open $file: $!";

my $last_time = 0;
print "{\"traceEvents\": [";
while(my $line = <$info>) {
    if  ($line =~ /\s+([0-9]+)\s+([0-9]+)\s+([0-9a-f]+)\s+([^ ]+)\s+(.+?(?=  )).*/) {
        my $duration = $2 - $last_time;
        my $funcname = `addr2line -e $binfile -f -i $3 | grep -v "/" | tail -n 1`;
        chomp $funcname;
        print "{\"name\": \"$4\", \"cat\": \"$4\", \"ph\": \"X\", \"ts\": $last_time, \"dur\": $duration, \"pid\": \"cluster0_core0\", \"tid\": \"$funcname\", \"args\":{}},\n";
        $last_time = $2;
    }
}

print "{\"name\": \"end\", \"cat\": \"end\", \"ph\": \"X\", \"ts\": $last_time, \"dur\": 1, \"pid\": \"cluster0_core0\", \"tid\": \"end\", \"args\":{}}\n";
print "]}";

close $info;
