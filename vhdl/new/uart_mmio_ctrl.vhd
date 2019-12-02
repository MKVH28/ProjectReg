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
        clk          : in std_logic;
        uart_txd_in  : in std_logic;
        uart_rxd_out : out std_logic;
        LED          : out std_logic_vector(3 downto 0);
        ext_sw       : in std_logic_vector(3 downto 0);
        btn          : in std_logic_vector(0 downto 0)
    );
end uart_mmio_ctrl;


architecture rtl of uart_mmio_ctrl is

    --UART RX
    component uart_rx is
        port(   
            clk, reset   : in  std_logic;                  
            rx           : in  std_logic;                  
            s_tick       : in  std_logic;                  
            rx_done_tick : out std_logic;                  
            dout         : out std_logic_vector(7 downto 0)
        );
    end component;  
    
    signal uart_dout : std_logic_vector(7 downto 0);  
    signal rx_done_tick_help : std_logic; 
    
    --UART TX
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
    
    signal uart_din : std_logic_vector(7 downto 0);
    signal tx_start_help : std_logic;
    signal tx_done_tick_help : std_logic;
    
    --Baud Generator
    component baud_gen is
        port(   
            clk   : in std_logic;
            reset : in std_logic;
            dvsr  : in std_logic_vector(10 downto 0);
            tick  : out std_logic
        );
    end component; 
    
    signal tick_help : std_logic;
    
    --GPO for LED
    component GPO_LED is
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
    end component;
        
    --GPO for LED
    component tGPO_LED_CONTROLLER is
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
    end component;
    
    --Uart Controller
    component uart_controller
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
            tx_start        : out std_logic  
       );
    end component;
        
    --debouncer for switch button
    --reset button
    component debounce is
        port(   
            clk         : in std_logic; --Input Clock            
            rst         : in std_logic; --Input Reset            
            button_in   : in std_logic; --Input signal (button)  
                                        
            pulse_out   : out std_logic --Output debounced signal
        );
    end component;
    
    --GPI for reading back switch values
    component tGPI is
        port(   
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
    end component;
        
    signal rst : std_logic;
    
    signal bus_wr : std_logic;
    signal bus_rd : std_logic;
    signal bus_wr_data : std_logic_vector (7 downto 0);
    signal bus_rd_data : std_logic_vector (7 downto 0);
    signal bus_addr : std_logic_vector (7 downto 0);
    signal bus_cs : std_logic_vector (15 downto 0);
    
    type rd_file_type is array (15 downto 0) of 
         std_logic_vector(7 downto 0);
         
    signal rd_data_array : rd_file_type := (others => (others => '0' ));

    
begin

---------------------UART RX Port Mapping---------------------    
    tUART_RX : uart_rx
        port map(
            clk             => clk,
            reset           => rst,
            s_tick          => tick_help,     
            dout            => uart_dout,        
            rx_done_tick    => rx_done_tick_help,
            rx              => uart_txd_in            
        );
 
---------------------UART TX Port Mapping---------------------    
    tUART_TX : uart_tx
        port map(
            clk             => clk,
            reset           => rst,
            tx_start        => tx_start_help,
            s_tick          => tick_help,    
            din             => uart_din,
            tx_done_tick    => tx_done_tick_help,
            tx              => uart_rxd_out      
        );
                
---------------------Baud Generator Port Mapping---------------------    
    tBAUD_GEN : baud_gen
        port map(
            clk     => clk,  
            reset   => rst,
            dvsr    => "01010001010", --9600
            tick    => tick_help                 
        );
        
---------------------UART Controller Mapping---------------------    
    tUART_CONTROLLER : uart_controller
        port map(
            clk             => clk,
            reset           => rst,
            -- slot interface
            cs              => bus_cs,
            wr              => bus_wr,
            rd              => bus_rd,
            rd_data         => bus_rd_data,
            wr_data         => bus_wr_data,
            addr            => bus_addr,
            --external signals
            rx_data         => uart_dout,
            rx_done_tick    => rx_done_tick_help,
            tx_data         => uart_din,
            tx_start        => tx_start_help,
            tx_done_tick    => tx_done_tick_help                
        );
                
---------------------GPO LED Port Mapping---------------------    
    tGPO_LED : GPO_LED
        port map(
            clk             => clk,
            reset           => rst,
            -- slot interface
            cs              => bus_cs(S0_GPO),
            wr              => bus_wr,
            rd              => bus_rd,
            rd_data         => rd_data_array(S0_GPO),
            wr_data         => bus_wr_data,
            addr            => bus_addr,
            --external signals
            led             => open                
        );
                        
---------------------GPO LED CONTROLLER Port Mapping---------------------    
    tGPO_CONTROLLER : tGPO_LED_CONTROLLER
        port map(
            clk             => clk,
            reset           => rst,
            -- slot interface
            cs              => bus_cs(S1_GPO_CTRL),
            wr              => bus_wr,
            rd              => bus_rd,
            rd_data         => rd_data_array(S1_GPO_CTRL),
            wr_data         => bus_wr_data,
            addr            => bus_addr,
            --external signals
            led             => LED                
        );
                                
---------------------GPI reading back Port Mapping---------------------    
    GPI : tGPI
        port map(
            clk         => clk,
            reset       => rst,
            -- slot interface
            cs          => bus_cs(S2_GPI),
            wr          => bus_wr,
            rd          => bus_rd,
            rd_data     => rd_data_array(S2_GPI),
            wr_data     => bus_wr_data,
            addr        => bus_addr,
            -- external signals
            sw          => ext_sw   
        );
        
---------------------debounce Port Mapping---------------------    
    tdebounce : debounce
        port map(
            clk => clk,             --Input Clock            
            rst => '0',             --Input Reset            
            button_in => btn(0),    --Input signal (button)  
            pulse_out => rst        --Output debounced signal
        );

bus_rd_data <= rd_data_array(to_integer(unsigned(bus_addr)));
        
end rtl;