entity nand_gate is
port (
   CLK: in bit;
   CLKOUT: out bit
     );
end nand_gate;

architecture basic of nand_gate is
begin
    CLKOUT <= CLK;
end basic;