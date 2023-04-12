library ieee;
use ieee.std_logic_1164.all;
entity hello_tb is
end hello_tb;

architecture test of hello_tb is
    component hello is
        port (
        A: in std_logic;
        B: in std_logic;
        C: out std_logic);
    end component;

    signal TB_A: std_logic;
    signal TB_B: std_logic;
    signal TB_C: std_logic;

begin
    dut: hello port map (TB_A, TB_B, TB_C);
    process
    begin
        TB_A <= '1';
        TB_B <= '1';
        wait for 25 ns;
        TB_B <= '0';
        wait for 5 ns;
        wait;
    end process;
end;
