
library IEEE;
use ieee.std_logic_1164.all;

entity wishbone_mem is
    port (
             clk_i          : in std_logic;
             rstn_i         : in std_logic;
             -- pll lock
             pll_clk        : in std_logic;
             pll_lock        : in std_logic;
             -- Wishbone bus interface (available if MEM_EXT_EN = true) --
             wb_tag_i       : in std_ulogic_vector(02 downto 0);
             wb_adr_i       : in std_ulogic_vector(31 downto 0);
             wb_dat_o       : out  std_ulogic_vector(31 downto 0);
             wb_dat_i       : in std_ulogic_vector(31 downto 0);
             wb_we_i        : in std_ulogic;
             wb_sel_i       : in std_ulogic_vector(03 downto 0);
             wb_stb_i       : in std_ulogic;
             wb_cyc_i       : in std_ulogic;
             wb_ack_o       : out  std_ulogic;
             wb_err_o       : out  std_ulogic;
             -- ddr3 mem
             -- ddr_rst_o: out std_logic;
             O_ddr_addr_o: out std_logic_vector(13 downto 0);
             O_ddr_ba_o: out std_logic_vector(2 downto 0);
             O_ddr_cs_n_o: out std_logic;
             O_ddr_ras_n_o: out std_logic;
             O_ddr_cas_n_o: out std_logic;
             O_ddr_we_n_o: out std_logic;
             O_ddr_clk_o: out std_logic;
             O_ddr_clk_n_o: out std_logic;
             O_ddr_cke_o: out std_logic;
             O_ddr_odt_o: out std_logic;
             O_ddr_reset_n_o: out std_logic;
             O_ddr_dqm_o: out std_logic_vector(1 downto 0);
             IO_ddr_dq_io: inout std_logic_vector(15 downto 0);
             IO_ddr_dqs_io: inout std_logic_vector(1 downto 0);
             IO_ddr_dqs_n_io: inout std_logic_vector(1 downto 0);
             -- debug
             dbg_led : out std_logic
         );
end entity;


architecture basic of wishbone_mem is
    component DDR3_Memory_Interface_Top
        port (
                 clk: in std_logic;
                 memory_clk: in std_logic;
                 pll_lock: in std_logic;
                 rst_n: in std_logic;
                 cmd_ready: out std_logic;
                 cmd: in std_logic_vector(2 downto 0);
                 cmd_en: in std_logic;
                 addr: in std_logic_vector(27 downto 0);
                 wr_data_rdy: out std_logic;
                 wr_data: in std_logic_vector(127 downto 0);
                 wr_data_en: in std_logic;
                 wr_data_end: in std_logic;
                 wr_data_mask: in std_logic_vector(15 downto 0);
                 rd_data: out std_logic_vector(127 downto 0);
                 rd_data_valid: out std_logic;
                 rd_data_end: out std_logic;
                 sr_req: in std_logic;
                 ref_req: in std_logic;
                 sr_ack: out std_logic;
                 ref_ack: out std_logic;
                 init_calib_complete: out std_logic;
                 clk_out: out std_logic;
                 ddr_rst: out std_logic;
                 burst: in std_logic;
        --- ddr output
                 O_ddr_addr: out std_logic_vector(13 downto 0);
                 O_ddr_ba: out std_logic_vector(2 downto 0);
                 O_ddr_cs_n: out std_logic;
                 O_ddr_ras_n: out std_logic;
                 O_ddr_cas_n: out std_logic;
                 O_ddr_we_n: out std_logic;
                 O_ddr_clk: out std_logic;
                 O_ddr_clk_n: out std_logic;
                 O_ddr_cke: out std_logic;
                 O_ddr_odt: out std_logic;
                 O_ddr_reset_n: out std_logic;
                 O_ddr_dqm: out std_logic_vector(1 downto 0);
                 IO_ddr_dq: inout std_logic_vector(15 downto 0);
                 IO_ddr_dqs: inout std_logic_vector(1 downto 0);
                 IO_ddr_dqs_n: inout std_logic_vector(1 downto 0)
             );

    end component;

    -- ddr misc signals
    signal cmd_ready_o: std_logic;
    signal cmd_i: std_logic_vector(2 downto 0);
    signal cmd_en_i: std_logic;
    signal addr_i: std_logic_vector(27 downto 0);
    signal wr_data_rdy_o: std_logic;
    signal wr_data_i: std_logic_vector(127 downto 0);
    signal wr_data_en_i: std_logic;
    signal wr_data_end_i: std_logic;
    signal rd_data_o: std_logic_vector(127 downto 0);
    signal rd_data_valid_o: std_logic;
    signal rd_data_end_o: std_logic;
    -- signal sr_req_i: std_logic;
    -- signal ref_req_i: std_logic;
    -- signal sr_ack_o: std_logic;
    -- signal ref_ack_o: std_logic;
    signal init_calib_complete_o: std_logic;
    signal clk_x1_o: std_logic;


    type t_WBState is (WB_Init, WB_Ready, WB_Read, WB_Read2, WB_Write, WB_Write2 );
    signal WBState : t_WBState := WB_Init;
    signal read_req : std_logic;
    signal read_ack : std_logic;
    signal read_data: std_logic_vector(127 downto 0);
    signal write_req : std_logic;
    signal write_ack : std_logic;
    signal write_data: std_ulogic_vector(127 downto 0);
    type t_DDRState is (DDR_Init, DDR_Ready, DDR_ReadWait, DDR_WriteWait);
    signal DDRState : t_DDRState := DDR_Init;

begin
    --dbg_led <= '1';
    my_ddr : DDR3_Memory_Interface_Top
    port map (
                 clk => clk_i,
                 memory_clk => pll_clk,
                 pll_lock => pll_lock,
                 rst_n => rstn_i,
                 cmd_ready => cmd_ready_o,
                 cmd => cmd_i,
                 cmd_en => cmd_en_i,
                 addr => addr_i,
                 wr_data_rdy => wr_data_rdy_o,
                 wr_data => wr_data_i,
                 wr_data_en => wr_data_en_i,
                 wr_data_end => wr_data_end_i,
                 wr_data_mask => "0000000000000000",
                 rd_data => rd_data_o,
                 rd_data_valid => rd_data_valid_o,
                 rd_data_end => rd_data_end_o,
                 sr_req => '0',
                 ref_req => '0',
        --sr_ack => sr_ack_o,
        --ref_ack => ref_ack_o,
                 init_calib_complete => init_calib_complete_o,
                 clk_out => clk_x1_o,
        -- ddr_rst => ddr_rst_o,
                 burst => '0',

                 O_ddr_addr => O_ddr_addr_o,
                 O_ddr_ba => O_ddr_ba_o,
                 O_ddr_cs_n => O_ddr_cs_n_o,
                 O_ddr_ras_n => O_ddr_ras_n_o,
                 O_ddr_cas_n => O_ddr_cas_n_o,
                 O_ddr_we_n => O_ddr_we_n_o,
                 O_ddr_clk => O_ddr_clk_o,
                 O_ddr_clk_n => O_ddr_clk_n_o,
                 O_ddr_cke => O_ddr_cke_o,
                 O_ddr_odt => O_ddr_odt_o,
                 O_ddr_reset_n => O_ddr_reset_n_o,
                 O_ddr_dqm => O_ddr_dqm_o,
                 IO_ddr_dq => IO_ddr_dq_io,
                 IO_ddr_dqs => IO_ddr_dqs_io,
                 IO_ddr_dqs_n => IO_ddr_dqs_n_io
             );



    process (clk_i)
    begin
        if rising_edge(clk_i) then
            -- add reset handling later
            if WBState = WB_Init then
                wb_err_o <= '0';
                wb_ack_o <= '0';
                wb_dat_o <= (others => '0');
                WBState <= WB_Ready;
                read_req <= '0';
                write_req <= '0';
            elsif WBState = WB_Ready then
                if (wb_stb_i = '1') and (wb_cyc_i = '1') and (wb_we_i = '0') then
                    read_req <= '1';
                    WBState <= WB_Read2;
                elsif (wb_stb_i = '1') and (wb_cyc_i = '1') and (wb_we_i = '1') then
                    write_req <= '1';
                    write_data <=  (31 downto 0 => wb_dat_i, others => '0');
                    --write_data <=  "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000" & to_stdlogicvector(wb_dat_i);
                    WBState <= WB_Write2;
                end if;
                if (wb_stb_i = '0') then
                    wb_ack_o <= '0';
                end if;
            elsif WBState = WB_Read then
                WBState <= WB_Read2;
            elsif WBState = WB_Read2 then
                if (read_ack = '1') then
                    read_req <= '0';
                    wb_ack_o <= '1';
                    wb_dat_o <= to_stdulogicvector(read_data(31 downto 0));
                    WBState <= WB_Ready;
                end if;
            elsif WBState = WB_Write then
                WBState <= WB_Write2;
            elsif WBState = WB_Write2 then
                if (write_ack = '1') then
                    write_req <= '0';
                    wb_ack_o <= '1';
                    WBState <= WB_Ready;
                end if;
            end if;
        end if;
    end process;



    process (clk_x1_o)
    begin
        if rising_edge(clk_x1_o) then
            if DDRState = DDR_Init then
                cmd_en_i <= '0';
                wr_data_end_i <= '0';
                wr_data_en_i <= '0';
                read_ack <= '0';
                write_ack <= '0';
                DDRState <= DDR_Ready;
            elsif DDRState = DDR_Ready then
                if read_req = '1' and cmd_ready_o = '1' and read_ack = '0' then
                    cmd_i <= "001";
                    addr_i <= to_stdlogicvector(wb_adr_i(27 downto 0));
                    cmd_en_i <= '1';
                    DDRState <= DDR_ReadWait;
                elsif write_req = '1' and cmd_ready_o = '1' and write_ack = '0' and wr_data_rdy_o = '1' then
                    cmd_i <= "000";
                    cmd_en_i <= '1';
                    addr_i <= to_stdlogicvector(wb_adr_i(27 downto 0));
                    wr_data_i <= to_stdlogicvector(write_data);
                    wr_data_en_i <= '1';
                    wr_data_end_i <= '1';
                    DDRState <= DDR_WriteWait;
                elsif read_ack = '1' and read_req = '0' then
                    read_ack <= '0';
                elsif write_ack = '1' and write_req = '0' then
                    write_ack <= '0';
                end if;
            elsif DDRState = DDR_ReadWait then
                cmd_en_i <= '0';
                if (rd_data_valid_o = '1') then
                    read_ack  <= '1';
                    read_data <= rd_data_o;
                    DDRState <= DDR_Ready;
                end if;
            elsif DDRState = DDR_WriteWait then
                cmd_en_i <= '0';
                wr_data_en_i <= '0';
                wr_data_end_i <= '0';
                write_ack  <= '1';
                DDRState <= DDR_Ready;
            end if;
        end if;
end process;
end architecture;

