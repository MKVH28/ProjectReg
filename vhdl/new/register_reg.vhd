----------------------------------------------------------------------------------
-- Engineer: Volkan Oez
-- 
-- Module Name: register
-- Project Name: Reg
-- Target Devices: Arty
-- Description: register file for project reg
----------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity register_reg is
    generic(
        B: in positive; --number of bits
        W: in positive  --number of address bits
    );
    port(
        clk             : in std_logic;                      --system clock
        rst             : in std_logic;                      --rst
        wr_en           : in std_logic;                      --write enable
        w_addr          : in std_logic_vector(W-1 downto 0); --write address
        w_data          : in std_logic_vector(B-1 downto 0); --write data
        r_addr_0        : in std_logic_vector(W-1 downto 0); --read address
        r_addr_1        : in std_logic_vector(W-1 downto 0); --read address
        r_data_0        : out std_logic_vector(B-1 downto 0);--read data
        r_data_1        : out std_logic_vector(B-1 downto 0) --read data
    );
end register_reg;

architecture rtl of register_reg is

    type reg_file_type is array (2**W-1 downto 0) of std_logic_vector(B-1 downto 0);
    signal array_reg: reg_file_type;

begin
    
    --write into B bit register
    process(clk, rst)
    begin
        if(rst='1') then
            array_reg <= (others=>(others=>'0'));
        elsif(rising_edge(clk)) then 
            if(wr_en='1') then
                array_reg(to_integer(unsigned(w_addr))) <= w_data;
            end if;
        end if;
    end process;
    
    --read from B bit register
    r_data_0 <= array_reg(to_integer(unsigned(r_addr_0)));
    r_data_1 <= array_reg(to_integer(unsigned(r_addr_1)));

end rtl;
