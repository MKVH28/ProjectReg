----------------------------------------------------------------------------------
-- Engineer: Volkan Oez
-- 
-- Module Name: CnM
-- Project Name: Reg
-- Target Devices: Arty
-- Description: BCD values will be compared and a matrix for display will created 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library xil_defaultlib;
use xil_defaultlib.pkg.all;

entity CnM is
    generic (
        g_INPUT_WIDTH       : in positive; --BCD input width 
        g_DECIMAL_DIGITS    : in positive; --BCD vector width
        g_DISPLAY_CONSTANT  : in positive; --first x bit of the LCD display output
        g_DISPLAY_WIDTH     : in positive  --Width of LCD display constant 
    );
    port ( 
        CnM_BCD_in              : in std_logic_vector(g_INPUT_WIDTH-1 downto 0);    --BCD input vector converted XADC output
        CnM_start_in            : in std_logic;                                     --Latch new matrix
        
        CnM_display_matrix_out  : out send_array(0 to 3)                            --BCD converted to an array for the display
    );
end CnM;

architecture rtl of CnM is
    
begin

    --breaks down the input into 4bit width vector and creates an array for the display output with adding the 4bit vector to the end of the outputvector     
    CnM : process
    begin
        wait until rising_edge(CnM_start_in);
            for i in g_DECIMAL_DIGITS downto 1 loop
                CnM_display_matrix_out(i-1) <= std_logic_vector(to_unsigned(g_DISPLAY_CONSTANT, g_DISPLAY_WIDTH)) & CnM_BCD_in(g_DECIMAL_DIGITS*i-1 downto g_DECIMAL_DIGITS*(i-1));
            end loop;
    end process;

end rtl;
