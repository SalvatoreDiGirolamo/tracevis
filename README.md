# tracevis

**Requires:**  perl >= v5.26; addr2line >= 2.30. Could work with lower versions too, but it is not tested.

**Usage:**
```perl ./parse.pl [-i] [-p] <binary> <trace file 1> ... <trace file n>```

The trace files are expected to be the ones produced by RI5CY cores.

**Output:** JSON that can be loaded into chrome tracing (about://tracing from chrome or chromium)

**Options:**
  - ```-i```: inlines instructions. Even if a function is inlined, it is still possible to see the inlined function. By default we show
 the origin function name, even if it inlined. If this option is specified the instructions are shown as belonging to the inlining function.
  - ```-p```: labels the instruction with the PC instead of the instruction type. 

**Example:**
The example/ folder contains: 
 - bin/pulp_api_example: a sample binary;
 - traces/trace*.log: the per-core RI5CY traces produced by the RTL simulation of the above binary file;
 - chrome.json: the output file produced by the script when the above binary and traces are given as input.

The chrome.json can be produced by running the following command:
```
perl parse.pl example/bin/pulp_api_example example/traces/trace_core_0*.log > chrome.json
```
