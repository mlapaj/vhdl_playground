
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
    signal read_triggered : std_ulogic;
    signal write_triggered : std_ulogic;
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

    -- aux DDR Controller signals
    signal cmd_sent : std_logic;
    signal temp_mc_reset : std_logic;
    signal temp_mc_reset_done : std_logic;
    type t_DDRState is (DDR_Init, DDR_Ready, DDR_Read, DDR_Write, DDR_ReadWait, DDR_WriteDone, DDR_Failure );
    signal DDRState : t_DDRState;
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
    signal sr_req_i: std_logic;
    signal ref_req_i: std_logic;
    signal sr_ack_o: std_logic;
    signal ref_ack_o: std_logic;
    signal init_calib_complete_o: std_logic;
    signal clk_x1_o: std_logic;


    signal read_addr:  std_logic_vector(27 downto 0);
    signal read_req:   std_logic;
    signal read_data:  std_ulogic_vector(127 downto 0);
    signal read_done:  std_logic;
    signal write_req:  std_logic;
    signal write_addr: std_logic_vector(27 downto 0);
    signal write_data: std_logic_vector(127 downto 0);
    signal write_done: std_logic;

    type t_WBState is (WB_Init, WB_Ready, WB_Read, WB_Write, WB_ReadWait, WB_WriteWait, WB_Failure );
    signal WBState : t_WBState;
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


    -- handle wishbone bus
    process (clk_i)
    begin
        if rising_edge(clk_i) then
            report "clk";
            if (rstn_i = '0') then
                report "reset";
                wb_dat_o <= (others => '0');
                temp_mc_reset <= '1';
                WBState <= WB_Ready;
                read_triggered <= '0';
                write_triggered <= '0';
                read_req <= '0';
                write_req <= '0';
            elsif (WBState = WB_Ready) then
                report "WB State Ready";
                wb_ack_o <= '0';
                if (temp_mc_reset_done = '1') then
                    temp_mc_reset <= '0';
                end if;
                if wb_stb_i = '1' and wb_cyc_i = '1' and wb_we_i = '0' and read_triggered = '0'  then
                    read_req <= '1';
                    read_addr <= to_stdlogicvector(wb_adr_i (27 downto 0));
                    read_triggered <= '1';
                    WBState <= WB_ReadWait;
                elsif wb_stb_i = '1' and wb_cyc_i = '1' and wb_we_i = '1' and write_triggered = '0'  then
                    write_req <= '1';
                    write_addr <= to_stdlogicvector(wb_adr_i (27 downto 0));
                    write_triggered <= '1';
                    -- check if is there any better way of doing it
                    write_data <= "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000" & to_stdlogicvector(wb_dat_i);
                    -- TODO: add data and other stuff
                    WBState <= WB_WriteWait;
                elsif wb_stb_i = '0' and wb_cyc_i = '0' and read_triggered = '1'  then
                    wb_dat_o <= (others => '0');
                    read_addr <= (others => '0');
                    read_triggered <= '0';
                elsif wb_stb_i = '0' and wb_cyc_i = '0' and write_triggered = '1'  then
                    write_triggered <= '0';
                    write_addr <= (others => '0');
                end if;
            elsif (WBState = WB_ReadWait) then
                report "WB State ReadWait";
                if (read_done = '1') then
                    wb_ack_o <= '1';
                    wb_dat_o <=  read_data(31 downto 0);
                    WBState <= WB_Ready;
                    read_req <= '0';
                end if;
            elsif (WBState = WB_WriteWait) then
                report "WB State WriteWait";
                if (write_done = '1') then
                    wb_ack_o <= '1';
                    write_req <= '0';
                    WBState <= WB_Ready;
                end if;
            end if;
        end if;
    end process;


    -- handle memory controller
    -- TODO: important add calib complete
    process (clk_x1_o)
    begin
        if rising_edge(clk_x1_o) then
            --report("tick clk_x1_o");
            if temp_mc_reset = '1'  then
                report "mem reset";
                DDRState <= DDR_Ready;
                temp_mc_reset_done <= '1';
                read_done <= '0';
                write_done <= '0';
            -- our test will be done here
            -- i assume this will be done without error
            elsif (init_calib_complete_o = '1') then
                if (temp_mc_reset = '0') then
                    temp_mc_reset_done <= '0';
                end if;
                if (DDRState = DDR_Ready) then
                    report "mem state Init";
                    addr_i <= (others => '0');
                    cmd_en_i <= '0';
                    wr_data_en_i <= '0';
                    wr_data_end_i <= '0';
                    cmd_sent <= '0';
                    if read_done = '0' and write_done = '0' then
                        if (read_req = '1') then
                            DDRState <= DDR_Read;
                        elsif (write_req = '1') then
                            DDRState <= DDR_Write;
                        end if;
                    else
                        if read_done = '1' and read_req = '0' then
                            read_done <= '0';
                        elsif write_done = '1' and write_req = '0' then
                            write_done <= '0';
                        end if;
                    end if;
                elsif (DDRState = DDR_Write) then
                    report "mem state write";
                    if cmd_ready_o = '1' and cmd_sent = '0' then
                        cmd_i <= "000";
                        cmd_en_i <= '1';
                    -- main thing
                        addr_i <= write_addr;
                        cmd_sent <= '1';
                    else
                        cmd_en_i <= '0';
                    end if;
                    if wr_data_rdy_o = '1' then
                        wr_data_i <= write_data;
                        wr_data_en_i <= '1';
                        wr_data_end_i <= '1';
                        -- if we wrote earlier data (cmd ready was not high,
                        -- we need to do additnioal loop)
                        if cmd_ready_o = '1' or cmd_sent = '1' then
                            DDRState <= DDR_WriteDone;
                        end if;
                    end if;
                elsif (DDRState = DDR_WriteDone) then
                    report "mem state write done";
                    cmd_en_i <= '0';
                    cmd_sent <= '0';
                    wr_data_en_i <= '0';
                    wr_data_end_i <= '0';
                    DDRState <= DDR_Ready;
                    write_done <= '1';
                elsif (DDRState = DDR_Read) then
                    report "mem state read";
                    if cmd_ready_o = '1' then
                        cmd_i <= "001";
                        cmd_en_i <= '1';
                    -- main thing
                        addr_i <= read_addr;
                        DDRState <= DDR_ReadWait;
                    end if;
                elsif (DDRState = DDR_ReadWait) then
                    report "mem state read wait";
                    cmd_en_i <= '0';
                    cmd_sent <= '0';
                    if (rd_data_valid_o = '1') then
                    -- todo: add stuff here
                        read_data <= to_stdulogicvector(rd_data_o);
                        DDRState <= DDR_Ready;
                        read_done <= '1';
                    end if;
                elsif (DDRState = DDR_Failure) then
                    report "mem state failure";
                -- todo: maybe not needed
                end if;
            end if;
        end if;
    end process;




end architecture;

