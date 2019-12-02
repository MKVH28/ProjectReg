library ieee;
use ieee.std_logic_1164.all;
use IEEE.NUMERIC_STD.ALL;
 
entity tb_bcd is
end tb_bcd;
 
architecture rtl of tb_bcd is
 
    -- Component Declaration for the Unit Under Test (UUT)
    -- define input width and decimal digits
 
    component Binary_to_BCD
    generic(
        g_INPUT_WIDTH    : in positive;
        g_DECIMAL_DIGITS : in positive
        );    
    port(
        i_Clock  : in std_logic;
        i_Start  : in std_logic;
        i_Binary : in std_logic_vector(g_INPUT_WIDTH-1 downto 0);
         
        o_BCD : out std_logic_vector(g_DECIMAL_DIGITS*4-1 downto 0);
        o_DV  : out std_logic
        );
    end component;
 
    --Constant 
    constant g_INPUT_WIDTH : positive := 16;  
    constant g_DECIMAL_DIGITS : positive := 4;
   
    --Inputs
    signal start : std_logic := '0';
    signal binary : std_logic_vector(g_INPUT_WIDTH-1 downto 0) := (others => '0');
 
    --Outputs
    signal BCD : std_logic_vector(g_DECIMAL_DIGITS*4-1 downto 0);
    signal DV : std_logic;
    signal test : integer;
 
    -- Clock period definitions
    constant clk_period : time := 10 ns;
    signal clock : std_logic := '0' ;
 
begin

    -- Clock process definitions
    clock<=NOT clock AFTER clk_period/2;
 
    -- Instantiate the Unit Under Test (UUT)
    uut: Binary_to_BCD 
    generic map(
        g_INPUT_WIDTH => g_INPUT_WIDTH,
        g_DECIMAL_DIGITS => g_DECIMAL_DIGITS
        )   
    port map(
        i_Clock => clock,
        i_Binary => binary,
        i_Start => start,
        o_BCD => BCD,
        o_DV => DV
    );
 
    
 
    -- Stimulus process
    stim_proc: process
    
    procedure check_BIN2BCD(in1 : in std_logic_vector(g_INPUT_WIDTH-1 downto 0)) is
            begin 
                binary <= in1;
                wait for 20ns;
                start <= '1';
                wait for 20ns;
                start <= '0';
                wait until DV = '1';
                
        end procedure check_BIN2BCD;   
    
    begin
                
        check_BIN2BCD("0000000000001111");
        test <= to_integer(signed(BCD));
        assert (BCD = std_logic_vector(to_unsigned(21,16)))
        report "Wrong Result"
        severity error;
               
        wait for 100 ns;
        
        check_BIN2BCD(x"0513");
        assert (BCD = std_logic_vector(to_unsigned(4761,16)))
        report "Wrong Result"
        severity error;
        
        wait;
                                   
--        binary_in <= "000001111111";
--        wait for 2000 ns;
        
--        binary_in <= "111101001111";
--        wait for 2000 ns;
    
    end process;
 
end;