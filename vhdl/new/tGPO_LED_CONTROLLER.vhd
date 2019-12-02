----------------------------------------------------------------------------------
-- Engineer: Volkan Oez
-- 
-- Module Name: tGPO_LED_CONTROLLER
-- Project Name: Reg
-- Target Devices: Arty
-- Description: LED controller with different configurations
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

entity tGPO_LED_CONTROLLER is
    generic(
        W : integer := 4;   -- width of output port
        R : integer := 3    -- # bits of PWM resolution (2^R levels)
    );
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
end tGPO_LED_CONTROLLER;

architecture rtl of tGPO_LED_CONTROLLER is

    type reg_file_type is array (W - 1 downto 0) of 
         std_logic_vector(R downto 0);
    signal duty_2d_reg    : reg_file_type;
    signal duty_2d_reg_bot: reg_file_type;
    signal wr_en          : std_logic;
    signal dvsr_sel_en    : std_logic;    
    signal duty_array_en  : std_logic;
    signal q_reg, q_next  : unsigned(23 downto 0);
    signal d_reg, d_next  : unsigned(R - 1 downto 0);
    signal d_ext          : unsigned(R - 1 downto 0);
    signal dvsr           : unsigned(23 downto 0);
    signal pwm_next       : std_logic_vector(W - 1 downto 0);
    signal pwm_reg        : std_logic_vector(W - 1 downto 0);
    signal tick           : std_logic;
    signal dvsr_sel_reg   : std_logic_vector(7 downto 0);

begin

-- wrapping circuit
    -- decoding logic
    wr_en         <= '1' when wr = '1' and cs = '1' else '0';
    duty_array_en <= '1' when wr_en = '1' and addr(6) = '1' else '0';
    dvsr_sel_en   <= '1' when wr_en = '1' and addr(6 downto 4) = "000" else '0';

-- register for divisor
    process(clk, reset)
    begin
        if (reset = '1') then
            dvsr_sel_reg <= (others => '0');
        elsif (clk'event and clk = '1') then
            if dvsr_sel_en = '1' then
                dvsr_sel_reg <= wr_data;
            end if;
        end if;
    end process;

-- register file for duty cycles 
    process(clk, reset)
    begin
        if (reset = '1') then
            duty_2d_reg <= (others => (others => '0'));
            duty_2d_reg_bot <= (others => (others => '0'));
        elsif (clk'event and clk = '1') then
            if duty_array_en = '1' then
                duty_2d_reg(to_integer(unsigned(addr(5 downto 4))))<=wr_data(R downto 0);
                duty_2d_reg_bot(to_integer(unsigned(addr(5 downto 4))))<=wr_data(2*R+1 downto R+1);  
            end if;
        end if;
    end process;

--multi-bit PWM
    process(clk, reset)
    begin
        if reset = '1' then
            q_reg   <= (others => '0');
            d_reg   <= (others => '0');
            pwm_reg <= (others => '0');
        elsif (clk'event and clk = '1') then
            q_reg   <= q_next;
            d_reg   <= d_next;
            pwm_reg <= pwm_next;
        end if;
    end process;

    -- counter selecter
    dvsr <= to_unsigned(1000,24) when dvsr_sel_reg(1 downto 0) = "11" else --800Hz125000
            to_unsigned(2500000,24) when dvsr_sel_reg(1 downto 0) = "10" else --40Hz
            to_unsigned(5000000,24) when dvsr_sel_reg(1 downto 0) = "01" else --20Hz
            to_unsigned(10000000,24);                                         --10Hz    
    -- "prescale" counter
    q_next <= (others=>'0') when q_reg=dvsr else q_reg + 1;
    tick   <= '1' when q_reg = 0 else '0';
    -- duty cycle counter
    d_next <= d_reg + 1 when tick = '1' else d_reg;
    d_ext  <= d_reg;
    -- comparison circuit
    gen_comp_cell : for i in 0 to W - 1 generate
    pwm_next(i) <= '1' when d_ext<unsigned(duty_2d_reg(i)) and unsigned(duty_2d_reg_bot(i))<=d_ext else '0';
    end generate;
    led <= pwm_reg;
    -- read data not used 
    rd_data <= (others => '0');

end rtl;
