----------------------------------------------------------------------------------
-- Engineer: Volkan Oez
-- 
-- Module Name: tGPI
-- Project Name: Reg
-- Target Devices: Arty
-- Description: GPI for reading back a register which can be configured via switch
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity tGPI is
    port (
        clk         : in std_logic;
        reset       : in std_logic;
        -- slot interface
        cs          : in std_logic;
        addr        : in std_logic_vector (7 downto 0);
        wr_data     : in std_logic_vector (7 downto 0);
        wr          : in std_logic;
        rd_data     : out std_logic_vector (7 downto 0);
        rd          : in std_logic;
        -- external signals
        sw          : in std_logic_vector (3 downto 0)
    );
end tGPI;

architecture rtl of tGPI is
    signal rd_data_reg : std_logic_vector(3 downto 0);
begin

    -- input register
    process(clk, reset)
    begin
        if (reset = '1') then
            rd_data_reg <= (others => '0');
        elsif (clk'event and clk = '1') then
            rd_data_reg <= sw;
        end if;
    end process;
    -- slot read interface
    rd_data <= "0000" & rd_data_reg;
    
end rtl;
