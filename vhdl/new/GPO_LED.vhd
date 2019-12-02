----------------------------------------------------------------------------------
-- Engineer: Volkan Oez
-- 
-- Module Name: gpo_led
-- Project Name: Reg
-- Target Devices: Arty
-- Description: general purpose out register with bus interface
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

entity gpo_led is
    generic(W : integer := 4);  -- width of output port
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
        led         : out std_logic_vector (3 downto 0)
    );
end gpo_led;

architecture rtl of gpo_led is
    signal buf_reg : std_logic_vector(W - 1 downto 0);
    signal wr_en   : std_logic;
begin
    -- output buffer register
   process(clk, reset)
   begin
      if (reset = '1') then
         buf_reg <= (others => '0');
      elsif (clk'event and clk = '1') then
         if wr_en = '1' then
            buf_reg <= wr_data(W - 1 downto 0);
         end if;
      end if;
   end process;
   -- decoding logic
   wr_en   <= '1' when wr = '1' and cs = '1' else '0';
   -- slot read interface
   rd_data <= (others => '0');          -- not used
   -- external output  
   led    <= buf_reg;
end rtl;
