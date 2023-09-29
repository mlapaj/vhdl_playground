library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity ula is
  port (
    -- Reset --
    rstn_i: in std_logic;
    -- Input clock --
    clk_i: in std_logic;

    -- Output Z80 clock --
    clk_cpu_o: out std_logic;

	-- access to ram
	mem_mreqn_o: out std_logic;
	mem_rd_o:    out std_logic;
	mem_wr_o:    out std_logic;
	mem_addr_o:  out std_logic_vector(15 downto 0);
	mem_data_o:  out std_logic_vector(7 downto 0);
	mem_data_i:  in std_logic_vector(7 downto 0);

    -- cpu to ram
    cpu_mreqn_i: in std_logic;
    cpu_rd_i:    in std_logic;
    cpu_wr_i:    in std_logic;
    cpu_addr_i:  in std_logic_vector(15 downto 0);
    cpu_data_i:  in std_logic_vector(7 downto 0);
    cpu_data_o:  out std_logic_vector(7 downto 0);

    -- cpu to video
    vid_mreqn_i: in std_logic;
    vid_rd_i:    in std_logic;
    vid_wr_i:    in std_logic;
    vid_addr_i:  in std_logic_vector(15 downto 0);
    vid_data_i:  in std_logic_vector(7 downto 0);
    vid_data_o:  out std_logic_vector(7 downto 0)

  );
end entity;

architecture basic of ula is
begin
	process (clk_i)
		variable cnt : integer range  0 to 3;
		variable video_process : std_logic := '0';
	begin
		-- rising or falling
		if (rstn_i = '0') then
			cnt := 0;
			clk_cpu_o <= '0';
		else
			if (vid_mreqn_i = '0') then
				video_process := '1';
				mem_mreqn_o <= vid_mreqn_i;
				mem_rd_o    <= vid_rd_i;
				mem_wr_o    <= vid_wr_i;
				mem_addr_o  <= vid_addr_i;
				mem_data_o  <= vid_data_i;
				vid_data_o  <= mem_data_i ;
			else
				video_process := '0';
				mem_mreqn_o <= cpu_mreqn_i;
				mem_rd_o    <= cpu_rd_i;
				mem_wr_o    <= cpu_wr_i;
				mem_addr_o  <= cpu_addr_i;
				mem_data_o  <= cpu_data_i;
				cpu_data_o  <= mem_data_i ;
			end if;
			if ((rising_edge(clk_i)) and (video_process = '0')) then
				if (cnt < 3) then
					cnt := cnt + 1;
				else
					cnt := 0;
					clk_cpu_o <= not clk_cpu_o;
				end if;
			end if;
		end if;
	end process;
end;
