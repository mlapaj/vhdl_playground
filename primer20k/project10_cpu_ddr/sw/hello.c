#include <neorv32.h>


/**********************************************************************//**
 * @name User configuration
 **************************************************************************/
/**@{*/
/** UART BAUD rate */
#define BAUD_RATE 19200
/**@}*/



/**********************************************************************//**
 * Main function; prints some fancy stuff via UART.
 *
 * @note This program requires the UART interface to be synthesized.
 *
 * @return 0 if execution was successful
 **************************************************************************/
int main() {

  // capture all exceptions and give debug info via UART
  // this is not required, but keeps us safe
  neorv32_rte_setup();

  // setup UART at default baud rate, no interrupts
  neorv32_uart0_setup(BAUD_RATE, 0);

  // check available hardware extensions and compare with compiler flags
  neorv32_rte_check_isa(0); // silent = 0 -> show message if isa mismatch

  // print project logo via UART
  neorv32_rte_print_logo();

  // say hello
  neorv32_uart0_puts("Hello world! :)\n");
  int j = 0;
  while (1){
      neorv32_uart_getc(NEORV32_UART0);
      neorv32_uart_puts(NEORV32_UART0,"Pressed a key! :)\n");
      neorv32_gpio_port_set(0x0);
      neorv32_uart_getc(NEORV32_UART0);
      int i = 0;
      void *x  = (void *) 0xC000;
      for (i = 0; i < 20; i=i+2){
          ((unsigned int *) x)[i] = i+j;
      }

      neorv32_uart_printf(NEORV32_UART0,"dump:\n");
      for (i = 0; i < 20; i=i+2){
      neorv32_uart_printf(NEORV32_UART0,"%x ", ((unsigned int *) x)[i]);
      }
      neorv32_uart_printf(NEORV32_UART0,"\n");
      neorv32_gpio_port_set(0xF);
      j=j+1;
  }
  return 0;
}
