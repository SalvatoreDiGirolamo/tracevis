# tracevis

**Usage:**
```perl ./parse.pl [-i] [-p] <binary> <trace file 1> ... <trace file n>```

**Output:** JSON that can be loaded into chrome tracing (about://tracing from chrome or chromium)

**Options:**
  - ```-i```: inlines instructions. Even if a function is inlined, it is still possible to see the inlined function. By default we show
 the origin function name, even if it inline. This option flatten this out. 
  - ```-p```: labels the instruction with the PC instead of the instruction type. 
 
