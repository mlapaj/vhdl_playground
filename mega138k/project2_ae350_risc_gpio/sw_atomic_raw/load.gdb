set logging file mylog.txt
set logging on
set pagination off
set disassemble-next-line on
target extended-remote :2331

file hello_world
monitor reset
restore hello_world
set $pc = _start
b hello_world.c:59
c
 x /1xb 0x40000
 set $i = 10
while $i <= 17
    eval "set $x%d = 0", $i
    set $i = $i + 1
end
set $pc=0

file fw_jump.elf
restore fw_jump.elf
restore u-boot.dtb binary 0x200000
#hartId is in a0
#dtb addres in a1
set $a1=0x200000
b generic_early_init
stepi

