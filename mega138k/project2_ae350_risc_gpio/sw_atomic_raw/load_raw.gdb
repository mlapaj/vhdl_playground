set logging file mylog.txt
set logging on
set pagination off
set disassemble-next-line on
target remote localhost:2331
file hello_world
monitor reset
restore hello_world
set $pc = _start
b amoswapw_func
c
