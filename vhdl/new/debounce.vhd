----------------------------------------------------------------------------------
-- Engineer: Volkan Oez
-- 
-- Module Name: debounce
-- Project Name: Reg
-- Target Devices: Arty
-- Description: debouncer circuit for push button
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

entity debounce is
    port(   
        clk         : in std_logic; --Input Clock
        rst         : in std_logic; --Input Reset
        button_in   : in std_logic; --Input signal (button)
        pulse_out   : out std_logic --Output debounced signal
    );
end debounce;

architecture rtl of debounce is

    --the below constants decide the working parameters.
    --the higher this is, the more longer time the user has to press the button.
    constant COUNT_MAX : integer := 100000; 
    --set it '1' if the button creates a high pulse when its pressed, otherwise '0'.
    constant BTN_ACTIVE : std_logic := '1';
    
    signal count : integer := 0;
    type state_type is (idle,wait_time); --state machine
    signal state : state_type := idle;

begin

process(rst,clk)
begin
    if(rst = '1') then
        state <= idle;
        pulse_out <= '0';
   elsif(rising_edge(clk)) then
        case (state) is
            when idle =>
                if(button_in = BTN_ACTIVE) then  
                    state <= wait_time;
                else
                    state <= idle; --wait until button is pressed.
                end if;
                pulse_out <= '0';
            when wait_time =>
                if(count = COUNT_MAX) then
                    count <= 0;
                    if(button_in = BTN_ACTIVE) then
                        pulse_out <= '1';
                    end if;
                    state <= idle;  
                else
                    count <= count + 1;
                end if; 
        end case;       
    end if;        
end process;

end rtl;
