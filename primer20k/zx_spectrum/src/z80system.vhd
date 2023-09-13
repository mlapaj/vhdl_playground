library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library t80lib;
use t80lib.all;

use STD.textio.all;
use ieee.std_logic_textio.all;


entity z80system is
    port (
             -- Global control --
             clk_i       : in  std_logic; -- global clock, rising edge
             rstn_i      : in  std_logic; -- global reset, low-active, async
             O_tmds_clk_p: out std_logic;
             O_tmds_clk_n: out std_logic;
             O_tmds_data_p: out std_logic_vector(2 downto 0);
             O_tmds_data_n: out std_logic_vector(2 downto 0)

         );
end entity;

architecture basic of z80system is
    component T80s is
        generic(
                   Mode    : integer := 0; -- 0 => Z80, 1 => Fast Z80, 2 => 8080, 3 => GB
                   T2Write : integer := 1; -- 0 => WR_n active in T3, /=0 => WR_n active in T2
                   IOWait  : integer := 1  -- 0 => Single cycle I/O, 1 => Std I/O cycle
               );
        port(
                RESET_n : in std_logic;
                CLK     : in std_logic;
                CEN     : in std_logic := '1';
                WAIT_n  : in std_logic := '1';
                INT_n     : in std_logic := '1';
                NMI_n     : in std_logic := '1';
                BUSRQ_n : in std_logic := '1';
                M1_n    : out std_logic;
                MREQ_n  : out std_logic;
                IORQ_n  : out std_logic;
                RD_n    : out std_logic;
                WR_n    : out std_logic;
                RFSH_n  : out std_logic;
                HALT_n  : out std_logic;
                BUSAK_n : out std_logic;
                OUT0    : in  std_logic := '0';  -- 0 => OUT(C),0, 1 => OUT(C),255
                A       : out std_logic_vector(15 downto 0);
                DI      : in std_logic_vector(7 downto 0);
                DO      : out std_logic_vector(7 downto 0)
            );
    end component;

    component z80system_rom is
        port (
         -- Global control --
                 clk_i       : in  std_logic; -- global clock, rising edge
                 mreqn_i     : in std_logic;
                 rd_i        : in std_logic;
                 addr_i      : in std_logic_vector(15 downto 0);
                 data_o        : out std_logic_vector(7 downto 0)
             );
    end component;
    component z80system_ram is
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
    end component;

    component Gowin_rPLL
        port (
                 clkout: out std_logic;
                 clkoutd: out std_logic;
                 clkin: in std_logic
             );
    end component;

    component hdmi is
        port (
        -- Global control --
                 clk_i       : in  std_logic; -- global clock, rising edge
                 rdy_i       : in  std_logic; -- global clock, rising edge
                 rstn_i      : in  std_logic; -- global reset, low-active, async
                 tmds_clk_p_o: out std_logic;
                 tmds_clk_n_o: out std_logic;
                 tmds_data_p_o: out std_logic_vector(2 downto 0);
                 tmds_data_n_o: out std_logic_vector(2 downto 0);
                 -- screen part
                 zx_scr_rd_o     : out std_logic;
                 zx_scr_x_o      : out std_logic_vector(7 downto 0);
                 zx_scr_y_o      : out std_logic_vector(7 downto 0);
                 zx_scr_rgb_r_i  : in std_logic_vector(7 downto 0);
                 zx_scr_rgb_g_i  : in std_logic_vector(7 downto 0);
                 zx_scr_rgb_b_i  : in std_logic_vector(7 downto 0)
             );
    end component;

    -- clock
    signal pll_out: std_logic;
    signal plld_out: std_logic;
    -- z80 stuff
    signal wait_n : std_logic := '1';
    signal int_n : std_logic := '1';
    signal nmi_n : std_logic := '1';
    signal busrq_n : std_logic := '1';
    signal addr : std_logic_vector(15 downto 0);
    signal mreq_n : std_logic;
    signal rfsh_n : std_logic;
    signal rd_n : std_logic;
    signal wr_n : std_logic;
    signal d_i : std_logic_vector(7 downto 0);
    signal d_o : std_logic_vector(7 downto 0);

    -- screen signals
    signal zx_scr_rd     : std_logic;
    signal zx_scr_x      : std_logic_vector(7 downto 0);
    signal zx_scr_y      : std_logic_vector(7 downto 0);
    signal zx_scr_rgb_r  : std_logic_vector(7 downto 0);
    signal zx_scr_rgb_g  : std_logic_vector(7 downto 0);
    signal zx_scr_rgb_b  : std_logic_vector(7 downto 0);





begin

    pll: Gowin_rPLL
    port map (
                 clkout => pll_out,
                 clkoutd => plld_out,
                 clkin => clk_i
             );
    hdmi0: hdmi
    port map (
                 clk_i  => pll_out,
                 rdy_i => '1',
                 rstn_i => rstn_i,
                 tmds_clk_p_o => O_tmds_clk_p,
                 tmds_clk_n_o => O_tmds_clk_n,
                 tmds_data_p_o => O_tmds_data_p,
                 tmds_data_n_o => O_tmds_data_n,
                 zx_scr_rd_o => zx_scr_rd,
                 zx_scr_x_o => zx_scr_x,
                 zx_scr_y_o => zx_scr_y,
                 zx_scr_rgb_r_i => zx_scr_rgb_r,
                 zx_scr_rgb_g_i => zx_scr_rgb_g,
                 zx_scr_rgb_b_i => zx_scr_rgb_b
             );


    cpu: T80s port map (
                           CLK => plld_out, 
                           RESET_n => rstn_i,
                           WAIT_n => wait_n, 
                           INT_n => int_n,
                           NMI_n => nmi_n, 
                           BUSRQ_n => busrq_n,
                           A => addr, 
                           MREQ_n => mreq_n,
                           DI => d_i, 
                           DO => d_o, 
                           RFSH_n => rfsh_n,
                           RD_n => rd_n, 
                           WR_n => wr_n
                       );
    rom: z80system_rom port map (
                                    clk_i => plld_out,
                                    addr_i => addr,
                                    mreqn_i => mreq_n, 
                                    data_o => d_i,
                                    rd_i => rd_n
                                );
    ram: z80system_ram port map ( 
                                    clk_i => plld_out, 
                                    addr_i => addr,
                                    mreqn_i => mreq_n, 
                                    data_i => d_o,
                                    data_o => d_i, 
                                    rd_i => rd_n, 
                                    wr_i => wr_n, 
                                    zx_scr_rd_i => zx_scr_rd,
                                    zx_scr_x_i => zx_scr_x,
                                    zx_scr_y_i => zx_scr_y,
                                    zx_scr_rgb_r_o => zx_scr_rgb_r,
                                    zx_scr_rgb_g_o => zx_scr_rgb_g,
                                    zx_scr_rgb_b_o => zx_scr_rgb_b
                                );
end architecture;
