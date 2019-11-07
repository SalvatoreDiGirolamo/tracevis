# tracevis

**Usage:**
```perl ./parse.pl [-i] [-p] <binary> <trace file 1> ... <trace file n>```

The trace files are expected to be the ones produced by RI5CY cores.

**Output:** JSON that can be loaded into chrome tracing (about://tracing from chrome or chromium)

**Options:**
  - ```-i```: inlines instructions. Even if a function is inlined, it is still possible to see the inlined function. By default we show
 the origin function name, even if it inlined. If this option is specified the instructions are shown as belonging to the inlining function.
  - ```-p```: labels the instruction with the PC instead of the instruction type. 
 
