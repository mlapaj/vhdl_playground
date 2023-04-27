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
    tmds_clk_p_o: out std_logic;
    tmds_clk_n_o: out std_logic;
    tmds_data_p_o: out std_logic_vector(2 downto 0);
    tmds_data_n_o: out std_logic_vector(2 downto 0)

  );
end entity;

architecture basic of z80system is
	constant PX_WIDTH                : integer := 1280;
	constant PX_FRONT_PORCH          : integer := 110;
	constant PX_SYNC_PULSE           : integer := 40;
	constant PX_BACK_PORCH           : integer := 220;
	constant LINE_HEIGHT             : integer := 720;
	constant LINE_FRONT_PORCH : integer := 5;
	constant LINE_SYNC_PULSE : integer := 5;
	constant LINE_BACK_PORCH : integer := 20;

    signal blank_n: std_logic;
	signal counterX : integer range 0 to (PX_WIDTH + PX_FRONT_PORCH + PX_SYNC_PULSE + PX_BACK_PORCH + 1);
	signal counterY : integer range 0 to (LINE_HEIGHT + LINE_FRONT_PORCH + LINE_SYNC_PULSE + LINE_BACK_PORCH + 1);


    signal pll_out: std_logic;
    signal rgb_vs_i: std_logic;
    signal rgb_hs_i: std_logic;
    signal rgb_de_i: std_logic;
    signal rgb_r_i: std_logic_vector(7 downto 0);
    signal rgb_g_i: std_logic_vector(7 downto 0);
    signal rgb_b_i: std_logic_vector(7 downto 0);





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
    -- component T80s is
	-- generic(
	-- 	Mode    : integer := 0; -- 0 => Z80, 1 => Fast Z80, 2 => 8080, 3 => GB
	-- 	T2Write : integer := 1; -- 0 => WR_n active in T3, /=0 => WR_n active in T2
	-- 	IOWait  : integer := 1  -- 0 => Single cycle I/O, 1 => Std I/O cycle
	-- );
	-- port(
	-- 	RESET_n : in std_logic;
	-- 	CLK     : in std_logic;
	-- 	CEN     : in std_logic := '1';
	-- 	WAIT_n  : in std_logic := '1';
	-- 	INT_n	  : in std_logic := '1';
	-- 	NMI_n	  : in std_logic := '1';
	-- 	BUSRQ_n : in std_logic := '1';
	-- 	M1_n    : out std_logic;
	-- 	MREQ_n  : out std_logic;
	-- 	IORQ_n  : out std_logic;
	-- 	RD_n    : out std_logic;
	-- 	WR_n    : out std_logic;
	-- 	RFSH_n  : out std_logic;
	-- 	HALT_n  : out std_logic;
	-- 	BUSAK_n : out std_logic;
	-- 	OUT0    : in  std_logic := '0';  -- 0 => OUT(C),0, 1 => OUT(C),255
	-- 	A       : out std_logic_vector(15 downto 0);
	-- 	DI      : in std_logic_vector(7 downto 0);
	-- 	DO      : out std_logic_vector(7 downto 0)
	-- );
    -- end component;
    --
    -- component z80system_rom is
    --   port (
    --     -- Global control --
    --     clk_i       : in  std_logic; -- global clock, rising edge
    --     mreqn_i     : in std_logic;
    --     rd_i        : in std_logic;
    --     addr_i      : in std_logic_vector(15 downto 0);
    --     data_o        : out std_logic_vector(7 downto 0)
    --   );
    -- end component;
    -- component z80system_ram is
    --   port (
    --     -- Global control --
    --     clk_i       : in  std_logic; -- global clock, rising edge
    --     mreqn_i     : in std_logic;
    --     rd_i     : in std_logic;
    --     wr_i     : in std_logic;
    --     addr_i      : in std_logic_vector(15 downto 0);
    --     data_i      : in std_logic_vector(7 downto 0);
    --     data_o      : out std_logic_vector(7 downto 0)
    --   );
    -- end component;

    component Gowin_rPLL
        port (
            clkout: out std_logic;
            clkin: in std_logic
        );
    end component;

    component DVI_TX_Top
        port (
            I_rst_n: in std_logic;
            I_rgb_clk: in std_logic;
            I_rgb_vs: in std_logic;
            I_rgb_hs: in std_logic;
            I_rgb_de: in std_logic;
            I_rgb_r: in std_logic_vector(7 downto 0);
            I_rgb_g: in std_logic_vector(7 downto 0);
            I_rgb_b: in std_logic_vector(7 downto 0);
            O_tmds_clk_p: out std_logic;
            O_tmds_clk_n: out std_logic;
            O_tmds_data_p: out std_logic_vector(2 downto 0);
            O_tmds_data_n: out std_logic_vector(2 downto 0)
        );
    end component;

begin

rgb_r_i <= "00000000";
rgb_g_i <= "11111111" and blank_n;
rgb_b_i <= "00000000";
rgb_de_i <= '0';


pll: Gowin_rPLL
    port map (
        clkout => pll_out,
        clkin => clk_i
    );


process (pll_out)
begin
    if (falling_edge(pll_out)) then
		if counterX = (PX_WIDTH + PX_FRONT_PORCH + PX_SYNC_PULSE + PX_BACK_PORCH - 1) then
			counterX <= 0;
			if counterY = (LINE_HEIGHT + LINE_FRONT_PORCH + LINE_SYNC_PULSE + LINE_BACK_PORCH - 1) then
				counterY <= 0;
			else
				counterY <= counterY + 1;
			end if; 
		else
			counterX <= counterX + 1;
		end if; 

		if counterX < PX_WIDTH AND counterY < LINE_HEIGHT then
			blank_n <= '1';
		else
			blank_n <= '0';
		end if;

		if counterX >= (PX_WIDTH + PX_FRONT_PORCH) AND counterX < (PX_WIDTH + PX_FRONT_PORCH + PX_SYNC_PULSE) then
			rgb_hs_i <= '1';
		else
			rgb_hs_i <= '0';
		end if;

		if counterY >= (LINE_HEIGHT + LINE_FRONT_PORCH) AND counterY < (LINE_HEIGHT + LINE_FRONT_PORCH + LINE_SYNC_PULSE) then
			rgb_vs_i <= '1';
		else
			rgb_vs_i <= '0';
		end if;
    end if;
end process;



your_instance_name: DVI_TX_Top
	port map (
		I_rst_n => rstn_i,
		I_rgb_clk => pll_out,
		I_rgb_vs => rgb_vs_i,
		I_rgb_hs => rgb_hs_i,
		I_rgb_de => blank_n,
		I_rgb_r => rgb_r_i,
		I_rgb_g => rgb_g_i,
		I_rgb_b => rgb_b_i,
		O_tmds_clk_p => tmds_clk_p_o,
		O_tmds_clk_n => tmds_clk_n_o,
		O_tmds_data_p => tmds_data_p_o,
		O_tmds_data_n => tmds_data_n_o
	);

-- cpu: T80s port map (CLK => clk_i, RESET_n => rstn_i,
--                    WAIT_n => wait_n, INT_n => int_n,
--                    NMI_n => nmi_n, BUSRQ_n => busrq_n,
--                    A => addr, MREQ_n => mreq_n,
--                    DI => d_i, DO => d_o, RFSH_n => rfsh_n,
-- 				   RD_n => rd_n, WR_n => wr_n
--                    );
-- rom: z80system_rom port map (clk_i => clk_i, addr_i => addr,
--                              mreqn_i => mreq_n, data_o => d_i,
--                              rd_i => rd_n);
-- ram: z80system_ram port map (clk_i => clk_i, addr_i => addr,
--                               mreqn_i => mreq_n, data_i => d_o,
-- 							  data_o => d_i, rd_i => rd_n, wr_i => wr_n);
end architecture;
