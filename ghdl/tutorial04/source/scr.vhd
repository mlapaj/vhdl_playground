library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use STD.textio.all;
use ieee.std_logic_textio.all;

entity scr is
	port (
			 -- Global control --
			 clk_i       : in  std_logic; -- global clock, rising edge
			 rstn_i      : in  std_logic; -- global reset, low-active, async
			 -- Memory access
			 mreqn_o     : out std_logic;
			 rd_o        : out std_logic;
			 addr_o      : out std_logic_vector(15 downto 0);
			 data_i      : in std_logic_vector(7 downto 0);
			 -- Screen info
			 pos_x      : in std_logic_vector(7 downto 0);
			 pos_y      : in std_logic_vector(7 downto 0)
		 );
end entity;

architecture basic of scr is
begin
	process (clk_i)
	begin
		if (rising_edge(clk_i)) then
			report "This is a test";
		end if;
	end process;
end architecture;
