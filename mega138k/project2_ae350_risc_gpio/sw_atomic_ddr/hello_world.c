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
#include <stdio.h>
#include <nds_intrinsic.h>


// Definitions ------------------------------------------------------------------------------

// Declarations
void amoswapw_func(void);


// Main function entry
int main(void)
{
    uart_init(9600);
    printf("\r\nIt's an Atomic Instruction demo.\r\n\r\n");

	amoswapw_func();	// amoswap.w
    printf("\r\ndone.\r\n\r\n");
    while (1)
    {
    }

	return 0;
}

// amoswap.w
void amoswapw_func(void)
{
	// We want to perform an atomic swap operation.
	signed int data, newv, oldv;
	newv = 10;

	// new value: 10
	oldv = __nds__amoswapw(newv, &data, UNORDER);

}

