set pagination off
set disassemble-next-line on
target remote localhost:2331
file hello_world
monitor reset
restore hello_world
set $pc = _start
stepi
b amoswapw_func
c
