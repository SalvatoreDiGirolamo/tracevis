sub flush_buffer {
    my $buffer = $_[0];
    my $pcs = $_[1];
    my $binfile = $_[2];
    my $last_time = $_[3];
    my $inline = $_[4];
    #print $buffer;
    my $funcnames = `addr2line -e $binfile -f -a -i $pcs`;

    $funcnames = "$funcnames\n0x0"; # to let it process the last address in the below loop

    #print "$funcnames";

    #remove first line
    $funcnames =~ s/^[^\n]*\n//s;

    my @a2l_first_last_lines = {};
    $a2l_first_last_lines[0] = "";
    $a2l_first_last_lines[1] = "";  

    my $a2l_line_index = 0;
    if (!$inline) { $a2l_line_index = 1;}

    for (split /\n/, $funcnames) {
        my $a2l_line = $_;
        #print "$_\n";
        if ($a2l_line =~ /^(0x[0-9a-f]+)(.*)/) {
            #print "ADDR: $1 $2\n";

            my ($time, $cycles, $pc, $instr, $args) = $buffer =~ /\s+([0-9]+)\s+([0-9]+)\s+([0-9a-f]+)\s+([^ ]+)\s+(.+?(?=  )).*/;
    
            my $funcname = $a2l_first_last_lines[$a2l_line_index];
            my $duration = $cycles - $last_time;
            
            print "{\"name\": \"$instr\", \"cat\": \"$instr\", \"ph\": \"X\", \"ts\": $last_time, \"dur\": $duration, \"pid\": \"cluster0_core0\", \"tid\": \"$funcname\", \"args\":{}},\n";

            #remove current line from the buffer
            $buffer =~ s/^[^\n]*\n//s;
        
            $a2l_first_last_lines[0] = "";
            $a2l_first_last_lines[1] = "";
            $last_time = $cycles;

        } elsif ($a2l_line =~ /^[^\/].*/) {
            if ($a2l_first_last_lines[0] eq "") { $a2l_first_last_lines[0] = $a2l_line; }
            $a2l_first_last_lines[1] = $a2l_line;
        }   
    }
    #print "\n\nend flush\n\n";
    return $last_time;
}

if ($#ARGV != 1 && $#ARGV != 2) {
    print "Usage: $0 [-i] <trace_file> <bin_file>\n";
    exit;
}

my $arg_index = 0;

my $inline = 0;
if ($ARGV[$arg_index] eq "-i") {
    $inline = 1;
    $arg_index++;
}
my $file=$ARGV[$arg_index++];
my $binfile=$ARGV[$arg_index++];

#print "$arg_index $inline $file $binfile\n";


open my $info, $file or die "Could not open $file: $!";

my $last_time = 0;
print "{\"traceEvents\": [";


my $buffer = "";
my $pcs="";
my $count = 0;

while(my $line = <$info>) {

    if  ($line =~ /\s+([0-9]+)\s+([0-9]+)\s+([0-9a-f]+)\s+([^ ]+)\s+(.+?(?=  )).*/) {

        $buffer = "$buffer$line"; 
        $pcs = "$pcs $3";
        $count++;

        if ($count==1000){
            #print "flushing buffer";
            #print "$buffer";
            $last_time = flush_buffer($buffer, $pcs, $binfile, $last_time, $inline);
            $buffer="";
            $pcs="";
            $count=0;
        }
    }
}

#in case we didn't reach the flushing threshold
$last_time = flush_buffer($buffer, $pcs, $binfile, $last_time, $inline);

print "{\"name\": \"end\", \"cat\": \"end\", \"ph\": \"X\", \"ts\": $last_time, \"dur\": 1, \"pid\": \"cluster0_core0\", \"tid\": \"end\", \"args\":{}}\n";
print "]}";

close $info;
