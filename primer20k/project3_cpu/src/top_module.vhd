library IEEE;
use ieee.std_logic_1164.all;

entity top_module is
port (
    CLK: in std_logic;
    UART_TXD: out std_logic;
    UART_RXD: in std_logic;
    GPIO: out std_logic;
    RSTN: in std_logic
     );
end top_module;

architecture basic of top_module is
component neorv32_test_setup_bootloader is
  generic (
    -- adapt these for your setup --
    CLOCK_FREQUENCY   : natural := 27000000; -- clock frequency of clk_i in Hz
    MEM_INT_IMEM_SIZE : natural := 16*1024;   -- size of processor-internal instruction memory in bytes
    MEM_INT_DMEM_SIZE : natural := 8*1024     -- size of processor-internal data memory in bytes
  );
  port (
    -- Global control --
    clk_i       : in  std_ulogic; -- global clock, rising edge
    rstn_i      : in  std_ulogic; -- global reset, low-active, async
    -- GPIO --
    gpio_o      : out std_ulogic_vector(7 downto 0); -- parallel output
    -- UART0 --
    uart0_txd_o : out std_ulogic; -- UART0 send data
    uart0_rxd_i : in  std_ulogic  -- UART0 receive data
  );
end component;

begin

neorv32: neorv32_test_setup_bootloader port map(
        clk_i => CLK,
        rstn_i => RSTN,
        uart0_rxd_i => UART_RXD,
        uart0_txd_o => UART_TXD,
        gpio_o(0) => GPIO
        );


end basic;