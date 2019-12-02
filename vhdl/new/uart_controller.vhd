----------------------------------------------------------------------------------
-- Engineer: Volkan Oez
-- 
-- Module Name: uart_controller
-- Project Name: Reg
-- Target Devices: Arty
-- Description: uart controller to process read and write commands from host terminal
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

entity uart_controller is
    port ( 
        clk             : in std_logic;
        reset           : in std_logic;
        -- slot interface
        cs              : out std_logic_vector (15 downto 0);
        wr              : out std_logic;
        rd              : out std_logic;
        rd_data         : in std_logic_vector (7 downto 0);
        wr_data         : out std_logic_vector (7 downto 0);
        addr            : out std_logic_vector (7 downto 0);
        --external signals
        rx_data         : in std_logic_vector (7 downto 0);
        rx_done_tick    : in std_logic;
        tx_data         : out std_logic_vector (7 downto 0);
        tx_done_tick    : in std_logic;
        tx_start        : out std_logic := '0'
   );
end uart_controller;

architecture rtl of uart_controller is

    type state_type is (idle, wait_data, get_read_data, send_read_data);
    signal state_reg    : state_type;
    signal state_next   : state_type;
    signal addr_temp    : std_logic_vector (7 downto 0);

begin

    -- FSMD state & data registers
    process(clk, reset)
    begin
        if reset = '1' then
            state_reg <= idle;
        elsif (rising_edge(clk)) then
            state_reg <= state_next;
        end if;
    end process;

    -- next-state logic & data path 
    process(state_reg, rx_done_tick, tx_done_tick, rx_data)
    begin
        state_next <= state_reg;
        wr <= '0';
        rd <= '0';
        tx_start <= '0';
        case state_reg is
            when idle =>
                -- check rx_done_tick if true check r/w bit (MSB) and place adress on bus
                if rx_done_tick = '1' then
                    if rx_data(7) = '1' then
                        state_next <= wait_data;
                        addr_temp <= '0' & rx_data(6 downto 0);
                    elsif rx_data(7) = '0' then
                        state_next <= get_read_data;
                        rd <= '1';
                        addr_temp <= '0' & rx_data(6 downto 0);
                    end if;
                else
                    state_next <= idle;
                end if;
            when wait_data =>
                -- check rx_done_tick if true place write data on bus
                if rx_done_tick = '1' then
                    wr_data <= rx_data;
                    wr <= '1';    
                    state_next <= idle;
                else
                    state_next <= wait_data;
                end if;
            when get_read_data =>
                -- get register value
                tx_data <= rd_data;
                state_next <= send_read_data;
            when send_read_data =>
                tx_start <= '1';
                if(tx_done_tick = '1') then
                    state_next <= idle;
                else
                    state_next <= send_read_data;
                end if;
        end case;
    end process;

addr <= addr_temp;

--comparator logic for cs
    process(addr_temp)
        begin
            cs <= (others => '0');
            cs(to_integer(unsigned(addr_temp(3 downto 0)))) <= '1';
    end process;
end rtl;
