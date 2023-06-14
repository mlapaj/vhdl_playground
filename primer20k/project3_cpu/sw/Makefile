# vhdl files
CC = riscv32-unknown-elf-gcc
CFLAGS = -nostdlib
GHDL_SIM_OPT = --stop-time=$(STOP_TIME)


.PHONY: clean

all: clean compile

compile: hello
	$(CC) $(CFLAGS) hello.c -o hello
clean:
	rm -rf $(SIMDIR)
