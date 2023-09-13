library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.palette.all;

entity z80system_ram is
  port (
        -- Global control --
        clk_i       : in std_logic; -- global clock, rising edge
        mreqn_i     : in std_logic;
        rd_i        : in std_logic;
        wr_i        : in std_logic;
        addr_i      : in std_logic_vector(15 downto 0);
        data_i      : in std_logic_vector(7 downto 0);
        data_o      : out std_logic_vector(7 downto 0);
        -- screen part
        zx_scr_rd_i     : in std_logic;
        zx_scr_x_i      : in std_logic_vector(7 downto 0);
        zx_scr_y_i      : in std_logic_vector(7 downto 0);
        zx_scr_rgb_r_o  : out std_logic_vector(7 downto 0);
        zx_scr_rgb_g_o  : out std_logic_vector(7 downto 0);
        zx_scr_rgb_b_o  : out std_logic_vector(7 downto 0)
  );
end entity;

architecture basic of z80system_ram is
type video_mem8_ram_t  is array (natural range 6911 downto 0) of std_logic_vector(07 downto 0);
signal video_ram_data : video_mem8_ram_t := (others => (others => '0'));
type mem8_ram_t  is array (natural range 42238 downto 0) of std_logic_vector(07 downto 0);
signal ram_data : mem8_ram_t := (others => (others => '0'));
signal data_tmp: std_logic_vector(7 downto 0);
begin
  process (clk_i)
    variable addr: std_logic_vector(15 downto 0);
  begin
    if (falling_edge(clk_i)) then
      if (mreqn_i = '0') then
        addr := addr_i;
        if (unsigned(addr) > 16383) and (unsigned(addr) < 65536) then
          --report "latch addr to tmp " & to_hstring(addr);
          end if;
        end if;
        if (rd_i = '0')  then
          --report "read from addr " & to_hstring(addr);
          if (unsigned(addr) > 16383) and (unsigned(addr) < 65536) then
            if (unsigned(addr) > 16383) and (unsigned(addr) < 23296) then
                report "reading from video ram[" & to_hstring(addr) & "]=" &
                to_hstring(ram_data(to_integer(unsigned(addr))-23296));
                data_o <= video_ram_data(to_integer(unsigned(addr))-16384);
            else
                -- assume rest of video
                report "reading from ram[" & to_hstring(addr) & "]=" &
                to_hstring(ram_data(to_integer(unsigned(addr))-23296));
                data_o <= ram_data(to_integer(unsigned(addr))-23296);
            end if;
          else
            data_o <= "ZZZZZZZZ";
          end if;
        end if;
        if rd_i = '1' or mreqn_i = '1' then
          data_o <= "ZZZZZZZZ";
        end if;
        if wr_i = '0' then
          if (unsigned(addr) > 16383) and (unsigned(addr) < 65536) then
            if (unsigned(addr) > 16383) and (unsigned(addr) < 23296) then
                report "writing to video ram[" & to_hstring(addr) & "]=" & to_hstring(data_i) ;
                video_ram_data(to_integer(unsigned(addr))-16384) <= data_i;
            else
                ram_data(to_integer(unsigned(addr))-23296) <= data_i;
                report "writing to ram[" & to_hstring(addr) & "]=" & to_hstring(data_i) ;
            end if;

          end if;
        end if;
      end if;
    end process;

    process (clk_i)
      variable addr_scr: std_logic_vector(15 downto 0);
      variable data: std_logic_vector(7 downto 0);
      variable col_addr_scr: std_logic_vector(15 downto 0);
      variable col: std_logic_vector(7 downto 0);
      variable ink: std_logic_vector(2 downto 0);
      variable paper: std_logic_vector(2 downto 0);
      variable tmp_bit: std_logic;
    begin
      if (falling_edge(clk_i)) then
        if (zx_scr_rd_i = '0')  then
          addr_scr := "000" & zx_scr_y_i(7) &
          zx_scr_y_i(6) &
          zx_scr_y_i(2) &
          zx_scr_y_i(1) &
          zx_scr_y_i(0) &
          zx_scr_y_i(5) &
          zx_scr_y_i(4) &
          zx_scr_y_i(3) &
          zx_scr_x_i(7 downto 3);
          if (unsigned(addr_scr) >= 0) and (unsigned(addr_scr) < 6912) then
            data := video_ram_data(to_integer(unsigned(addr_scr)));
            tmp_bit := data(7-to_integer(unsigned(zx_scr_x_i(2 downto 0))));
            col_addr_scr := x"1800" or ("000000" & zx_scr_y_i(7 downto 3) & zx_scr_x_i(7 downto 3));
            -- add color handling
            col := video_ram_data(to_integer(unsigned(col_addr_scr)));
            if (tmp_bit = '1') then
              ink := col(2 downto 0);
              if (col(6) = '0') then -- check bright - col(6)
                zx_scr_rgb_r_o <= palette_0(to_integer(unsigned(ink)))(7 downto 0);
                zx_scr_rgb_g_o <= palette_0(to_integer(unsigned(ink)))(15 downto 8);
                zx_scr_rgb_b_o <= palette_0(to_integer(unsigned(ink)))(23 downto 16);
              else
                zx_scr_rgb_r_o <= palette_1(to_integer(unsigned(ink)))(7 downto 0);
                zx_scr_rgb_g_o <= palette_1(to_integer(unsigned(ink)))(15 downto 8);
                zx_scr_rgb_b_o <= palette_1(to_integer(unsigned(ink)))(23 downto 16);
              end if;
            else
              paper := col(5 downto 3);
              if (col(6) = '0') then -- check bright - col(6)
                zx_scr_rgb_r_o <= palette_0(to_integer(unsigned(paper)))(7 downto 0);
                zx_scr_rgb_g_o <= palette_0(to_integer(unsigned(paper)))(15 downto 8);
                zx_scr_rgb_b_o <= palette_0(to_integer(unsigned(paper)))(23 downto 16);
              else
                zx_scr_rgb_r_o <= palette_1(to_integer(unsigned(paper)))(7 downto 0);
                zx_scr_rgb_g_o <= palette_1(to_integer(unsigned(paper)))(15 downto 8);
                zx_scr_rgb_b_o <= palette_1(to_integer(unsigned(paper)))(23 downto 16);
              end if;
            end if;
          else
            zx_scr_rgb_r_o <= "ZZZZZZZZ";
            zx_scr_rgb_g_o <= "ZZZZZZZZ";
            zx_scr_rgb_b_o <= "ZZZZZZZZ";
          end if;
        end if;
      end if;
    end process;

end architecture;
