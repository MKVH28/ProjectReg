----------------------------------------------------------------------------------
-- Engineer: Volkan Oez
-- 
-- Module Name: baud_gen
-- Project Name: Reg
-- Target Devices: Arty
-- Description: Baud Rate Generator for UART from FPGA Prototyping by Chu
--              Creates sampling signal whose frequency is exactly 16 times the 
--              UART's baud rate. 
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity baud_gen is
   port(
      clk   : in std_logic;
      reset : in std_logic;
      dvsr  : in std_logic_vector(10 downto 0);
      tick  : out std_logic
   );
end baud_gen;

architecture arch of baud_gen is
   constant N    : integer := 11;
   signal r_reg  : unsigned(N - 1 downto 0);
   signal r_next : unsigned(N - 1 downto 0);
begin
   -- register
   process(clk, reset)
   begin
      if (reset = '1') then
         r_reg <= (others => '0');
      elsif (clk'event and clk = '1') then
         r_reg <= r_next;
      end if;
   end process;
   -- next-state logic
   -- counter, resets when counter=divisor for 100MHz, dvsr=f/(16*b)-1
   r_next <= (others=>'0') when r_reg=unsigned(dvsr) else r_reg + 1;
   -- output logic
   tick <= '1' when r_reg=1 else '0'; -- not use 0 because of reset
end arch;