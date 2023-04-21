library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.z80system_rom_image.all;

entity z80system_rom is
  port (
    -- Global control --
    clk_i       : in std_logic; -- global clock, rising edge
    mreqn_i     : in std_logic;
    rd_i        : in std_logic;
    addr_i      : in std_logic_vector(15 downto 0);
    data_io      : inout std_logic_vector(7 downto 0)
  );
end entity;

architecture basic of z80system_rom is
signal data_tmp: std_logic_vector(7 downto 0);
begin
	process (mreqn_i, rd_i)
		variable addr : std_logic_vector(15 downto 0);
	begin
		if (falling_edge(mreqn_i)) then
			addr := addr_i; 
			--report "latch addr to tmp " & to_hstring(addr);
		end if;
		if (falling_edge(rd_i)) and ((mreqn_i = '0') or (falling_edge(mreqn_i))) then
			if (unsigned(addr) < 16384) then
				data_io <= rom_image(to_integer(unsigned(addr)));
				-- report "read rom[ " & to_hstring(addr) & "] =" & 
				--        to_hstring(rom_image(to_integer(unsigned(addr))));
			else
				data_io <= "ZZZZZZZZ";
			end if;
		elsif (rising_edge(rd_i) or rising_edge(mreqn_i)) then
			data_io <= "ZZZZZZZZ";
		end if;
	end process;
end;
