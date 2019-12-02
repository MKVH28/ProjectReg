----------------------------------------------------------------------------------
-- Engineer: Volkan Oez
-- 
-- Module Name: uart_mmio_ctrl
-- Project Name: Reg
-- Target Devices: Arty
-- Description: UART MMIO controller connects all peripherals to the host
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
use xil_defaultlib.pkg.all;

entity uart_mmio_ctrl is
    Port ( 
        clk         : in std_logic;
        btn         : in std_logic_vector(1 downto 0);  --SW?
        uart_rxd_out: out std_logic;
        uart_txd_in : in std_logic
    );
end uart_mmio_ctrl;


architecture rtl of uart_mmio_ctrl is

    type state_type is (idle, send_string, tx_start, wait_tx_done);--(idle, send_hello, select_reply, tx_start_1, wait_tx_done_1, tx_start_2, wait_tx_done_2);
    signal state_reg     : state_type;
    signal state_next    : state_type;
    
    signal button_debounce_in   : std_logic;
    signal counter_string_next  : integer := 0;
    signal counter_string_reg   : integer := 0;
    signal tick_help            : std_logic;
    signal counter_string_rst   : std_logic;
    signal tx_start_help        : std_logic;
    signal tx_done_tick_help    : std_logic;
    signal rx_done_tick_help    : std_logic := '0';
    signal uart_tx_data         : std_logic_vector(7 downto 0) := (others => '0');
    signal uart_rx_data         : std_logic_vector(7 downto 0) := (others => '0');
    
    constant hello_string : hello_array := (std_logic_vector(to_unsigned(character'pos('H'),8)),
                                            std_logic_vector(to_unsigned(character'pos('a'),8)),
                                            std_logic_vector(to_unsigned(character'pos('l'),8)),
                                            std_logic_vector(to_unsigned(character'pos('l'),8)),
                                            std_logic_vector(to_unsigned(character'pos('o'),8)),
                                            x"0D",
                                            x"0A");
                                              
    constant hey_string : hello_array :=   (std_logic_vector(to_unsigned(character'pos('H'),8)),
                                            std_logic_vector(to_unsigned(character'pos('e'),8)),
                                            std_logic_vector(to_unsigned(character'pos('y'),8)),
                                            x"0D",
                                            x"0A",
                                            x"00",
                                            x"00");  
    
--    constant text_1 : std_logic_vector := std_logic_vector(to_unsigned(character'pos('a'),8));
--    constant text_2 : std_logic_vector := std_logic_vector(to_unsigned(character'pos('b'),8));

    --debouncer for push button
    --for now only relevant for UART TX testing purposes SW?
    component debounce is
        port(   
            clk         : in std_logic; --Input Clock            
            rst         : in std_logic; --Input Reset            
            button_in   : in std_logic; --Input signal (button)  
                                        
            pulse_out   : out std_logic --Output debounced signal
        );
    end component;
    
    --UART TX
    --testing purposes
    component uart_tx is
        port(   
            clk, reset   : in  std_logic;
            tx_start     : in  std_logic;
            s_tick       : in  std_logic;
            din          : in  std_logic_vector(7 downto 0);
            tx_done_tick : out std_logic;
            tx           : out std_logic
        );
    end component;
         
    --UART RX
    --testing purposes
    component uart_rx is
        port(   
            clk, reset   : in  std_logic;                  
            rx           : in  std_logic;                  
            s_tick       : in  std_logic;                  
            rx_done_tick : out std_logic;                  
            dout         : out std_logic_vector(7 downto 0)
        );
    end component;    
    
    --Baud Generator
    --testing purposes
    component baud_gen is
        port(   
            clk   : in std_logic;
            reset : in std_logic;
            dvsr  : in std_logic_vector(10 downto 0);
            tick  : out std_logic
        );
    end component;    

begin

---------------------debounce Port Mapping---------------------    
    tdebounce : debounce
        port map(
            clk => clk,                     --Input Clock            
            rst => btn(1),                  --Input Reset            
            button_in => btn(0),            --Input signal (button)  
            pulse_out => button_debounce_in --Output debounced signal
        );
        
---------------------UART RX Port Mapping---------------------    
    tUART_RX : uart_rx
        port map(
            clk => clk,
            reset => btn(1),
            s_tick => tick_help,     
            dout => uart_rx_data,        
            rx_done_tick => rx_done_tick_help,
            rx => uart_txd_in            
        );
                
---------------------UART TX Port Mapping---------------------    
    tUART_TX : uart_tx
        port map(
            clk => clk,
            reset => btn(1),  
            tx_start => tx_start_help,
            s_tick => tick_help,     
            din => uart_tx_data,        
            tx_done_tick => tx_done_tick_help,
            tx => uart_rxd_out             
        );
                
---------------------Baud Generator Port Mapping---------------------    
    tBAUD_GEN : baud_gen
        port map(
            clk => clk,  
            reset => btn(1),
            dvsr => "01010001010", --9600
            tick => tick_help                 
        );
    
--register for state
    process(clk, btn(1))
    begin
      if btn(1) = '1' then
         state_reg <= idle;
         counter_string_reg <= 0;
      elsif (rising_edge(clk)) then
         state_reg <= state_next;
         counter_string_reg <= counter_string_next;
      end if;
    end process;
    
--state machine for UART 
    process(state_reg, button_debounce_in, tx_done_tick_help, uart_rx_data, counter_string_reg) 
    begin
        state_next <= state_reg;
        counter_string_next <= counter_string_reg;
        case state_reg is
            
            when idle =>
                tx_start_help <= '0';
                if (button_debounce_in = '1') then
                    state_next <= send_string;
                elsif (unsigned(uart_rx_data) = (to_unsigned(character'pos('a'),8))) then
                    state_next <= send_string;
                end if;
                
            when send_string =>  
                uart_tx_data <= hello_string(counter_string_reg);
                state_next <= tx_start;
                
            when tx_start => 
                tx_start_help <= '1';
                state_next <= wait_tx_done;
                
            when wait_tx_done =>
                tx_start_help <= '0';
                if(tx_done_tick_help = '1') then
                    state_next <= idle;
                    counter_string_next <= counter_string_reg + 1;
                    if counter_string_reg > 6 then
                        counter_string_next <= 0;
                    end if;
                end if;
            
--            when idle =>
--                tx_start_help <= '0';
--                if (button_debounce_in = '1') then
--                    state_next <= send_hello;
--                elsif (rx_done_tick_help = '1') then
--                    state_next <= select_reply;
--                end if;
                
--            when send_hello => 
--                uart_tx_data <= hello_string(counter_string);
--                state_next <= tx_start_1;        
                                            
--            when tx_start_1 => 
--                tx_start_help <= '1';
--                state_next <= wait_tx_done_1;
                
--            when wait_tx_done_1 =>
--                tx_start_help <= '0';
--                if(tx_done_tick_help = '1') then
--                    state_next <= send_hello;
--                end if;
                
--            when select_reply =>
--                if (unsigned(uart_rx_data) = (to_unsigned(character'pos('a'),8))) then
--                    uart_tx_data <= hey_string(counter_string);
--                    state_next <= tx_start_2;    
--                end if;
                                            
--            when tx_start_2 =>
--                tx_start_help <= '1';
--                state_next <= wait_tx_done_2;
            
--            when wait_tx_done_2 =>
--                tx_start_help <= '0';
--                if(tx_done_tick_help = '1') then
--                    state_next <= select_reply;
--                end if;        
            
        end case;    
    end process;    

--rising_edge_counter : process (tx_done_tick_help, btn(1))
--    begin
--        if(btn(1) = '1') then
--            counter_string_reg <= 0;
--        elsif(tx_done_tick_help = '1') then
--            counter_string_next <= counter_string_reg + 1;
--            if counter_string_reg > 6 then
--                counter_string_next <= 0;
--             end if;
--        end if;
--    end process rising_edge_counter;

end rtl;