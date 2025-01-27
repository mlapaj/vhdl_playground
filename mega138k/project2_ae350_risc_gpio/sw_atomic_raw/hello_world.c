/*
 * ******************************************************************************************
 * File		: main.c
 * Author 	: GowinSemicoductor
 * Chip		: AE350_SOC
 * Function	: Main functions
 * ******************************************************************************************
 */

// Includes ---------------------------------------------------------------------------------
#include "uart.h"
#include <nds_intrinsic.h>


// Definitions ------------------------------------------------------------------------------

// Declarations
void amoswapw_func(void);

#define set_csr(reg, bit)   __nds__csrrs(bit, reg)
#define clear_csr(reg, bit) __nds__csrrc(bit, reg)
#define read_fcsr()         __nds__frcsr()
#define read_csr(reg)       __nds__csrr(reg)    

void enable_l1_cache()
{
	/* Do your platform low-level initial */

	/*
	 * Enable I/D cache with HW pre-fetcher,
	 * D-cache write-around (threshold: 4 cache lines),
	 * and CM (Coherence Manager).
	 */
	/* CSR: control and status register */
	clear_csr(NDS_MCACHE_CTL, (3 << 13));
	set_csr(NDS_MCACHE_CTL, (1 << 19) | (1 << 13) | (1 << 10) | (1 << 9) | (1 << 1) | (1 << 0));

	/* Check if CPU support CM or not. */
	if (read_csr(NDS_MCACHE_CTL) & (1 << 19))
	{
		/* Wait for cache coherence enabling completed */
		while((read_csr(NDS_MCACHE_CTL) & (1 << 20)) == 0);
	}

}

void flush_cache() {
    int *ptr = (void *) 0x40000;
    *ptr = 24;
//    asm volatile("fence");
}


// Main function entry
int main(void)
{
    uart_init(9600);
    enable_l1_cache();
	amoswapw_func();	// amoswap.w
	return 0;
}

// amoswap.w
void amoswapw_func(void)
{
    uart_puts("Before amoswapw\n");
	// We want to perform an atomic swap operation.
	signed int data, newv, oldv;
    int x;
    int *ptr = (void *) 0x40000;
    x = *ptr;
    //flush_cache();
    //void *ptr = &data;
    // hooray - to dziala 
    //asm ("li t0, 0x40000");
    //asm("li t1, 0x10");
    //asm("sw t1, 0(t0)");
	//newv = 10;

	// new value: 10
	oldv = __nds__amoswapw(newv, ptr, UNORDER);

    uart_puts("Done\n"); 
    /* asm("mv a6, a4"); */
    /* asm("amoswap.w a6, a7, (a6)"); */
    asm("j .");

}

