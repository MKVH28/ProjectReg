----------------------------------------------------------------------------------
-- Engineer: Volkan Oez
-- 
-- Module Name: tb_CnM
-- Project Name: Reg
-- Target Devices: Arty
-- Description: testbench for CnM / procedure checks that the correct four bits (depends on the number that is desired to show on display) were added to the vector and checks automatically that the correct matrix was built 
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

library xil_defaultlib;
use xil_defaultlib.all;
use xil_defaultlib.pkg.all;

entity tb_CnM is
end entity tb_CnM;
 
architecture rtl of tb_CnM is
 
    component CnM
        generic (
            g_INPUT_WIDTH       : in positive; --BCD input width
            g_DECIMAL_DIGITS    : in positive; --BCD vector width
            g_DISPLAY_CONSTANT  : in positive;  --first x bit of the LCD display output
            g_DISPLAY_WIDTH     : in positive  --Width of LCD display constant  
            );
        port ( 
            CnM_BCD_in              : in std_logic_vector(g_INPUT_WIDTH-1 downto 0);    --BCD input vector converted XADC output
            CnM_start_in            : in std_logic; 
            
            CnM_display_matrix_out  : out send_array(0 to 3)                            --BCD converted to an array for the 
            );
    end component;
 
    --Constant 
    constant g_INPUT_WIDTH : positive := 16;  
    constant g_DECIMAL_DIGITS : positive := 4;
    constant g_DISPLAY_CONSTANT : positive := 35;
    constant g_DISPLAY_WIDTH : positive := 6;
   
    --Inputs
    signal tb_CnM_start_in : std_logic := '0';
    signal tb_CnM_BCD_in   : std_logic_vector(g_INPUT_WIDTH-1 downto 0) := (others => '0');
    
    --Output
    signal tb_CnM_display_matrix_out : send_array(0 to 3);
    
    -- Clock period definitions
    constant clk_period : time := 10 ns;
    signal clock : std_logic := '0' ;
 
begin

    -- Clock process definitions
    clock<=NOT clock AFTER clk_period/2;
 
    -- Stimulus process
    stim_proc: process
    
    procedure check_CnM(in1 : in std_logic_vector(g_INPUT_WIDTH-1 downto 0)) is
            variable res : std_logic_vector(9 downto 0);
            variable i : natural := 1;
        begin 
            tb_CnM_start_in <= '1';
            wait for 40ns;
            tb_CnM_start_in <= '0';    
            
            res := std_logic_vector(to_unsigned(g_DISPLAY_CONSTANT, g_DISPLAY_WIDTH)) & tb_CnM_BCD_in(g_DECIMAL_DIGITS*i-1 downto g_DECIMAL_DIGITS*(i-1));
            assert (tb_CnM_display_matrix_out(i-1) = res)
            report "Wrong Result/Order First Vector"
            severity error;
            i := i + 1;
            
            wait for 20ns;             
            res := std_logic_vector(to_unsigned(g_DISPLAY_CONSTANT, g_DISPLAY_WIDTH)) & tb_CnM_BCD_in(g_DECIMAL_DIGITS*i-1 downto g_DECIMAL_DIGITS*(i-1));
            assert (tb_CnM_display_matrix_out(i-1) = res)
            report "Wrong Result/Order Second Vector"
            severity error;
            i := i + 1;
                        
            wait for 20ns; 
            res := std_logic_vector(to_unsigned(g_DISPLAY_CONSTANT, g_DISPLAY_WIDTH)) & tb_CnM_BCD_in(g_DECIMAL_DIGITS*i-1 downto g_DECIMAL_DIGITS*(i-1));
            assert (tb_CnM_display_matrix_out(i-1) = res)
            report "Wrong Result/Order Third Vector"
            severity error;
            i := i + 1;
                        
            wait for 20ns; 
            res := std_logic_vector(to_unsigned(g_DISPLAY_CONSTANT, g_DISPLAY_WIDTH)) & tb_CnM_BCD_in(g_DECIMAL_DIGITS*i-1 downto g_DECIMAL_DIGITS*(i-1));
            assert (tb_CnM_display_matrix_out(i-1) = res)
            report "Wrong Result/Order Fourth Vector"
            severity error;
            
    end procedure check_CnM;
    
    begin
        
        wait for 40ns;        
        tb_CnM_BCD_in <= "0001" & "0010" & "0011" & "0100";
        check_CnM(tb_CnM_BCD_in);
        wait for 40ns;
        tb_CnM_BCD_in <= "0101" & "0110" & "1011" & "0101";
        check_CnM(tb_CnM_BCD_in);
        wait;
            
    end process stim_proc;
    
    -- Instantiate the Unit Under Test (UUT)
    uut : CnM 
    generic map(
        g_INPUT_WIDTH => g_INPUT_WIDTH,
        g_DECIMAL_DIGITS => g_DECIMAL_DIGITS,
        g_DISPLAY_CONSTANT => g_DISPLAY_CONSTANT,
        g_DISPLAY_WIDTH => g_DISPLAY_WIDTH
        )   
    port map(
        CnM_start_in => tb_CnM_start_in,
        CnM_BCD_in => tb_CnM_BCD_in,
        CnM_display_matrix_out => tb_CnM_display_matrix_out
        );   
        
end rtl;