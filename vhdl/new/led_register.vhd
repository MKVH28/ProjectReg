----------------------------------------------------------------------------------
-- Engineer: Volkan Oez
-- 
-- Module Name: led_register
-- Project Name: Reg
-- Target Devices: Arty
-- Description: module for controlling the leds on the arty board
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

entity led_register is
    generic(
        B: in positive; --number of bits
        W: in positive  --number of address bits
    );
    port(
        clk, reset      : in std_logic;                      --system clock and reset
        r_data_0        : in std_logic_vector(B-1 downto 0); --read data from LED register
        
        r_addr_0        : out std_logic_vector(W-1 downto 0) := "0";--read address from register
        led_register    : out std_logic_vector(3 downto 0)   --controls all 4 LEDs on the Arty Board
    );    
end led_register;

architecture rtl of led_register is

signal counter : integer := 0;

begin

    process(clk, reset)
    
    begin
        --reset all LEDs are off
        if(reset='1') then
            led_register <= (others=>'0');
        elsif(rising_edge(clk)) then
            --register is 0 all LEDs are off 
            if(r_data_0="0000") then
                led_register <= (others=>'0');
            --register is 1 all LEDs are on 
            elsif(r_data_0="0001") then
                led_register <= "1111";
            --register is 2 all LEDs are blinking with 1s on time and 1s off time
            elsif(r_data_0="0010") then
                counter <= counter + 1;
                if(counter <= 100000000) then
                    led_register <= "0000";
                elsif(counter <= 200000000) then 
                    led_register <= "1111";
                else
                    counter <= 0;
                end if;
            --register is 4 all LEDs are chagning from right to left on time 1s
            elsif(r_data_0="0100") then 
                counter <= counter + 1;
                if(counter <= 100000000) then
                    led_register <= "0001";
                elsif(counter <= 200000000) then 
                    led_register <= "0010";
                elsif(counter <= 300000000) then 
                    led_register <= "0100";
                elsif(counter <= 400000000) then 
                    led_register <= "1000";
                else 
                    counter <= 0;
                end if;
            --register is 8 all LEDs are chagning from left to right on time 1s
            elsif(r_data_0="1000") then 
                counter <= counter + 1;
                if(counter <= 100000000) then
                    led_register <= "1000";
                elsif(counter <= 200000000) then 
                    led_register <= "0100";
                elsif(counter <= 300000000) then 
                    led_register <= "0010";
                elsif(counter <= 400000000) then 
                    led_register <= "0001";
                else 
                    counter <= 0;
                end if;
            --any other combination has all LEDs off
            else
                led_register <= "0000";
            end if;
        end if;
    end process;
    
end rtl;
