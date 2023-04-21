library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity z80system_ram is
  port (
    -- Global control --
    clk_i       : in std_logic; -- global clock, rising edge
    mreqn_i     : in std_logic;
    rd_i        : in std_logic;
    wr_i        : in std_logic;
    addr_i      : in std_logic_vector(15 downto 0);
    data_io      : inout std_logic_vector(7 downto 0)
  );
end entity;

architecture basic of z80system_ram is
type mem8_ram_t  is array (natural range 49151 downto 0) of std_logic_vector(07 downto 0);
signal ram_data : mem8_ram_t;
signal data_tmp: std_logic_vector(7 downto 0);
type std_logic_vector_file is file of mem8_ram_t;
file file_ram : std_logic_vector_file;
begin
	process (mreqn_i, rd_i, wr_i)
		variable addr: std_logic_vector(15 downto 0);
	begin
		if (falling_edge(mreqn_i)) then
			addr := addr_i;
			if (unsigned(addr) > 16383) and (unsigned(addr) < 65536) then
				--report "latch addr to tmp " & to_hstring(addr);
			end if;
		end if;
		if (falling_edge(rd_i) and (mreqn_i = '0')) then
				--report "read from addr " & to_hstring(addr);
			if (unsigned(addr) > 16383) and (unsigned(addr) < 65536) then
				report "reading from ram[" & to_hstring(addr) & "]=" &
				       to_hstring(ram_data(to_integer(unsigned(addr))-16384));
				data_io <= ram_data(to_integer(unsigned(addr))-16384);
			else
				data_io <= "ZZZZZZZZ";
			end if;
		elsif (rising_edge(rd_i) or rising_edge(mreqn_i)) then
			data_io <= "ZZZZZZZZ";
		end if;
		if ((falling_edge(wr_i)) and (mreqn_i = '0')) then
			if (unsigned(addr) > 16383) and (unsigned(addr) < 65536) then
				ram_data(to_integer(unsigned(addr))-16384) <= data_io;
				report "writing to ram[" & to_hstring(addr) & "]=" & to_hstring(data_io) ;
			end if;
		end if;
    end process;
    process
    begin
        wait for 800 ms;
        file_open(file_ram, "out_ram.txt",  write_mode);
        report "writing ram to file";
        write(file_ram, ram_data);
        file_close(file_ram);
    end process;
end;
