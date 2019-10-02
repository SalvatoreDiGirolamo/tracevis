sub flush_buffer {
    my $key = $_[0];
    my $buffer = $_[1];
    my $pcs = $_[2];
    my $binfile = $_[3];
    my $last_time = $_[4];
    my $inline = $_[5];
    #print $buffer;
    my $funcnames = `addr2line -e $binfile -f -a -i $pcs`;

    $funcnames = "$funcnames\n0x0"; # to let it process the last address in the below loop

    #print "$funcnames";

    #remove first line
    $funcnames =~ s/^[^\n]*\n//s;

    my @a2l_first_last_lines = {};
    $a2l_first_last_lines[0] = "";
    $a2l_first_last_lines[1] = "";  

    my $a2l_line_index = 1;
    if (!$inline) { $a2l_line_index = 0;}

    for (split /\n/, $funcnames) {
        my $a2l_line = $_;
        #print "$_\n";
        if ($a2l_line =~ /^(0x[0-9a-f]+)(.*)/ and $buffer =~ /.*\n.*\n.*/) {
            #print "ADDR: $1 $2\n";

            my ($time, $cycles, $pc, $instr, $args, $next_cycles) = $buffer =~ /^\s+([0-9]+)\s+([0-9]+)\s+([0-9a-f]+)\s+[0-9a-f]+\s+([^ ]+)\s+(.+?(?=  )).*\n\s+[0-9]+\s+([0-9]+).*/;
    
            #remove current line from the buffer
            $buffer =~ s/^[^\n]*\n//s;

            #print "$time - $cycles - $pc - $instr - $args\n";
            my $funcname = $a2l_first_last_lines[$a2l_line_index];
            my $duration = ($next_cycles - $cycles);
            my $start_time = $cycles;
            
            print "{\"name\": \"$instr\", \"cat\": \"$instr\", \"ph\": \"X\", \"ts\": $start_time, \"dur\": $duration, \"pid\": \"$key\", \"tid\": \"$funcname\", \"args\":{}},\n";

        
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

sub convert_file {
    my $file = $_[0];
    my $binfile = $_[1];
    my $inline = $_[2];

    open my $info, $file or die "Could not open $file: $!";
    my $last_time = 0;
    my $buffer = "";
    my $pcs="";
    my $count = 0;

    while(my $line = <$info>) {

        if  ($line =~ /^\s+([0-9]+)\s+([0-9]+)\s+([0-9a-f]+)\s+[0-9a-f]+\s+([^ ]+)\s+(.+?(?=  )).*/) {
            $buffer = "$buffer$line"; 
            $pcs = "$pcs $3";
            $count++;

            if ($count==1000){
                #print "flushing buffer";
                #print "$buffer";
                $last_time = flush_buffer($file, $buffer, $pcs, $binfile, $last_time, $inline);
                $buffer="$line";
                $pcs="";
                $count=0;
            }
        }
    }

    #in case we didn't reach the flushing threshold
    $last_time = flush_buffer($file, $buffer, $pcs, $binfile, $last_time, $inline);

    close $info;
    return $last_time;
}

if ($#ARGV < 1) {
    print "Usage: $0 [-i] <bin_file> <trace_file_1> .. <trace_file_n>\n";
    exit;
}

my $arg_index = 0;

my $inline = 0;
if ($ARGV[$arg_index] eq "-i") {
    $inline = 1;
    $arg_index++;
    shift;
}
my $binfile=shift; #$ARGV[$arg_index++];

#print "$arg_index $inline $binfile\n";

print "{\"traceEvents\": [\n";

my $last_time=0;
foreach my $file (@ARGV) {
    $last_time = convert_file($file, $binfile, $inline);
}


#print "{\"name\": \"end\", \"cat\": \"end\", \"ph\": \"X\", \"ts\": $last_time, \"dur\": 0, \"pid\": \"$file\", \"tid\": \"end\", \"args\":{}}\n";

print "{}]}\n";


