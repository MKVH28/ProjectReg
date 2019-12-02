----------------------------------------------------------------------------------
-- Engineer: Volkan Oez
-- 
-- Module Name: tb_debouncer
-- Project Name: Reg
-- Target Devices: Arty
-- Description: testbench - debouncer circuit for push button
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity tb_debouncer is
end tb_debouncer;

architecture rtl of tb_debouncer is

    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT DeBounce
    PORT(
         Clock : IN  std_logic;
         Reset : IN  std_logic;
         button_in : IN  std_logic;
         pulse_out : OUT  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal Reset : std_logic := '0';
   signal button_in : std_logic := '0';

    --Outputs
   signal pulse_out : std_logic;

   -- Clock period definitions
   constant clk_period : time := 10 ns;
   signal Clock : std_logic := '0';
   
begin

    -- Instantiate the Unit Under Test (UUT)
   uut: debounce PORT MAP (
          Clock => Clock,
          Reset => Reset,
          button_in => button_in,
          pulse_out => pulse_out
        );

   clock<=NOT clock AFTER clk_period/2; 

   -- Stimulus process
   stim_proc: process
   begin        
        button_in <= '0';
        reset <= '1';
      -- hold reset state for 100 ns.
      wait for 100 ns;
        reset <= '0';
      wait for clk_period*10;
        --first activity
        button_in <= '1';   wait for clk_period*2;
        button_in <= '0';   wait for clk_period*1;
        button_in <= '1';   wait for clk_period*1;
        button_in <= '0';   wait for clk_period*20;
        --second activity            
        button_in <= '1';   wait for clk_period*1;
        button_in <= '0';   wait for clk_period*1;
        button_in <= '1';   wait for clk_period*1;
        button_in <= '0';   wait for clk_period*2;
        button_in <= '1';   wait for clk_period*20;
        button_in <= '0';   
      wait;
   end process;

end rtl;