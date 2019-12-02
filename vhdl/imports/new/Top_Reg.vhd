----------------------------------------------------------------------------------
-- Engineer: Volkan Oez
-- 
-- Module Name: Top_Reg
-- Project Name: Reg
-- Target Devices: Arty
-- Description: Top Level
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

library xil_defaultlib;
use xil_defaultlib.pkg.all;

entity TopReg is
    port( 
        clk                                 : in std_logic;                         --system clock / 100MHz
        --LCD interface
        t_rw_out, t_rs_out, t_enable_out    : out std_logic;                        --read/write, register select (instruction register or data register), enable for LCD
        t_data_out                          : out std_logic_vector(7 downto 0);     --data signals output for LCD
        --register interface
        LED                                 : out std_logic_vector(3 downto 0);     --LED (GPO)
        ext_sw                              : in std_logic_vector(3 downto 0);      --SW (GPI)
        btn                                 : in std_logic_vector(0 downto 0);      --BTN (button)
        --UART_HOST
        uart_txd_in                         : in std_logic;                         --uart input
        uart_rxd_out                        : out std_logic;                        --uart output
        --XADC power monitoring
        vsnsvu_n                            : in std_logic;                         -- Auxiliary Channel 1 (external supply voltage monitor)           
        vsnsvu_p                            : in std_logic;
        vsns5v0_n                           : in std_logic;                         -- Auxiliary Channel 2 (5V supply current monitor)
        vsns5v0_p                           : in std_logic;
        isns5v0_n                           : in std_logic;                         -- Auxiliary Channel 9 (5V supply voltage monitor)          
        isns5v0_p                           : in std_logic;
        isns0v95_n                          : in std_logic;                         -- Auxiliary Channel 10 (FPGA core supply monitor)           
        isns0v95_p                          : in std_logic
    );
end TopReg;

architecture rtl of TopReg is

---------------------Component Declaration---------------------
--LCD Controller
--drives the inputs of the lcd controller within the correct timings 
component lcd_controller 
    port( 
        clk             : in std_logic;                     --system clock
        enable_in       : in std_logic;                     --latches data into lcd controller  
        data_in         : in std_logic_vector(9 downto 0);  --data signals input for LCD
        rw_out          : out std_logic;                    --read/write
        rs_out          : out std_logic;                    --register select (instruction register or data register)
        enable_out      : out std_logic;                    --enable for LCD
        busy_out        : out std_logic;                    --busy signal
        data_out        : out std_logic_vector(7 downto 0); --data signals output for LCD
        init_done_out   : out std_logic                     --LCD init done signal
    );
end component;        

--XADC XILINX IP CORE
--xadc module from xilinx (currently only reads the 0.95V rail)
component xadc_wiz_0 is
	port(
        daddr_in        : in  STD_LOGIC_VECTOR (6 downto 0);     -- Address bus for the dynamic reconfiguration port
        den_in          : in  STD_LOGIC;                         -- Enable Signal for the dynamic reconfiguration port
        di_in           : in  STD_LOGIC_VECTOR (15 downto 0);    -- Input data bus for the dynamic reconfiguration port
        dwe_in          : in  STD_LOGIC;                         -- Write Enable for the dynamic reconfiguration port
        do_out          : out  STD_LOGIC_VECTOR (15 downto 0);   -- Output data bus for dynamic reconfiguration port
        drdy_out        : out  STD_LOGIC;                        -- Data ready signal for the dynamic reconfiguration port
        dclk_in         : in  STD_LOGIC;                         -- Clock input for the dynamic reconfiguration port
        reset_in        : in  STD_LOGIC;                         -- Reset signal for the System Monitor control logic
        convst_in       : in  STD_LOGIC;                         -- Convert Start Input 
        vauxp1          : in  STD_LOGIC;                         -- Auxiliary Channel 1 (external supply voltage monitor)
        vauxn1          : in  STD_LOGIC;
        vauxp2          : in  STD_LOGIC;                         -- Auxiliary Channel 2 (5V supply current monitor)      
        vauxn2          : in  STD_LOGIC;
        vauxp9          : in  STD_LOGIC;                         -- Auxiliary Channel 9 (5V supply voltage monitor)      
        vauxn9          : in  STD_LOGIC;
        vauxp10         : in  STD_LOGIC;                         -- Auxiliary Channel 10 (FPGA core supply monitor)      
        vauxn10         : in  STD_LOGIC;
        busy_out        : out  STD_LOGIC;                        -- ADC Busy signal
        channel_out     : out  STD_LOGIC_VECTOR (4 downto 0);    -- Channel Selection Outputs
        eoc_out         : out  STD_LOGIC;                        -- End of Conversion Signal
        eos_out         : out  STD_LOGIC;                        -- End of Sequence Signal
        alarm_out       : out STD_LOGIC;                         -- OR'ed output of all the Alarms
        vp_in           : in  STD_LOGIC;                         -- Dedicated Analog Input Pair
        vn_in           : in  STD_LOGIC
    );
end component;

--Interface between XADC and LCD Controller
--XADC results go through this module and are converted into the correct format for the LCD Controller 
component XADC2LCD is
    port(
        clk             : in std_logic;                     --system clock
        lcd_ready_in    : in std_logic;                     --lcdcontroller ready signal (init_done and busy)
        xadc_drdy_in    : in std_logic;                     --xadc drdy
        xadc_do_in      : in std_logic_vector(15 downto 0); --xadc do_out
        xadc_busy_in    : in std_logic;                     --xadc busy flag     
        xadc_eos_in     : in std_logic;                     --xadc end of sequence flag
        xadc_eoc_in     : in std_logic;                     --xadc end of sequence flag
        
        lcd_enable_out  : out std_logic := '0';             --lcdcontroller enable_in
        lcd_data_out    : out std_logic_vector(9 downto 0); --lcdcontroller data_in 
        xadc_den_out    : out std_logic;                    --xadc den_in
        xadc_convst_out : out std_logic;                    --xadc convst_in
        xadc_daddr_out  : out std_logic_vector(6 downto 0)  --xadc daddr_in      
    );
end component;

--Interface to host 
--UART interface with state machine for read and write commands for internal mmio bus
component tUART_HOST
    Port (
        clk             : in std_logic;
        rst             : in std_logic;
        uart_txd_in     : in std_logic;
        uart_rxd_out    : out std_logic;
        -- slot interface
        bus_cs          : out std_logic_vector (15 downto 0);
        bus_wr          : out std_logic;
        bus_rd          : out std_logic;
        bus_rd_data     : in std_logic_vector (7 downto 0);
        bus_wr_data     : out std_logic_vector (7 downto 0);
        bus_addr        : out std_logic_vector (7 downto 0)
    );
end component;

--Interface to register 
--S0 GPO (direct LED control - wr)
--S1 GPO CTRL (some LED control schemes - wr)
--S2 GPI (read switch status - rd)
component register_interface
    Port (
        clk         : in std_logic;
        rst         : in std_logic;
        -- slot interface
        bus_cs      : in std_logic_vector (15 downto 0);
        bus_wr      : in std_logic;
        bus_rd      : in std_logic;
        bus_rd_data : out std_logic_vector (7 downto 0);
        bus_wr_data : in std_logic_vector (7 downto 0);
        bus_addr    : in std_logic_vector (7 downto 0);
        -- external signals
        LED         : out std_logic_vector(3 downto 0);
        ext_sw      : in std_logic_vector(3 downto 0)
    );
end component;
    
--debouncer for button
--reset button
component debounce is
    port(   
        clk         : in std_logic; --Input Clock            
        rst         : in std_logic; --Input Reset            
        button_in   : in std_logic; --Input signal (button)  
                                    
        pulse_out   : out std_logic --Output debounced signal
    );
end component;    

---------------------Signal Declaration---------------------
--LCD
signal t_lcd_busy_out   : std_logic;
signal t_init_done_out  : std_logic;
signal t_enable_in      : std_logic := '0';
signal t_data_in        : std_logic_vector(9 downto 0);
signal lcd_ready_in     : std_logic := '0';
constant freq           : integer := 100;
signal counter          : integer range 0 to 15 := 0;

--XADC
signal t_den_in : std_logic := '0';
signal display_flag : std_logic := '0';
signal den_in_flag : std_logic := '0';
signal t_do_out : std_logic_vector(15 downto 0);
signal test_out : std_logic_vector(15 downto 0);
signal t_drdy_out : std_logic;
signal t_delay : std_logic;
signal t_convst_in : std_logic := '0';
signal t_xadc_busy_out : std_logic;
signal t_eos_out : std_logic;
signal t_eoc_out : std_logic;
signal t_daddr_in : std_logic_vector(6 downto 0) := (others => '0');

--UART_HOST
signal bus_wr : std_logic;
signal bus_rd : std_logic;
signal bus_wr_data : std_logic_vector (7 downto 0);
signal bus_rd_data : std_logic_vector (7 downto 0);
signal bus_addr : std_logic_vector (7 downto 0);
signal bus_cs : std_logic_vector (15 downto 0);

--register_interface

--debounce reset
signal rst : std_logic;

begin

---------------------LCD controller Port Mapping---------------------  
tlcd_controller: lcd_controller
    port map(
        clk           => clk,                                             
        enable_in     => t_enable_in,
        --rst_in      => t_rst_in,                               
        data_in       => t_data_in,                           
        rw_out        => t_rw_out,
        rs_out        => t_rs_out,
        enable_out    => t_enable_out,
        busy_out      => t_lcd_busy_out,
        data_out      => t_data_out,
        init_done_out => t_init_done_out                              
    );

--LCD ready signal is used to signal that lcd init is done and signals with busy if it is currently driving data to the LCD 
--currently delayed with 10s for clarity
lcd_ready_in <= '1' when t_init_done_out = '1' and t_lcd_busy_out = '0' and t_delay = '1' else '0' ;

process(clk)
    variable t_counter : integer := 0;
begin
    if (rising_edge(clk)) then
        if (t_counter > 1000000 * freq) then 
            t_delay <= '1';
            t_counter := 0;
        else
            t_delay <= '0';
            t_counter := t_counter + 1;
        end if;
    end if;
end process; 

---------------------XADC Port Mapping---------------------  
tXADC : xadc_wiz_0
    port map(
        daddr_in    => t_daddr_in,      -- Address bus for the dynamic reconfiguration port         
        den_in      => t_den_in,		-- Enable Signal for the dynamic reconfiguration port             
        di_in       => (others => '0'),	-- Input data bus for the dynamic reconfiguration port      
        dwe_in      => '0',				-- Write Enable for the dynamic reconfiguration port                 
        do_out      => t_do_out,		-- Output data bus for dynamic reconfiguration port               
        drdy_out    => t_drdy_out,		-- Data ready signal for the dynamic reconfiguration port       
        dclk_in     => clk,				-- Clock input for the dynamic reconfiguration port / 100MHz         
        reset_in    => '0',				-- Reset signal for the System Monitor control logic
        convst_in   => t_convst_in,     -- Convert Start Input                      
        vauxp1      => vsns5v0_p,  	    -- Auxiliary Channel 1 (FPGA core supply monitorexternal supply voltage monitor)                                    
        vauxn1      => vsns5v0_n,   		                                                                                              
        vauxp2      => vsnsvu_p, 		-- Auxiliary Channel 2 (external supply voltage monitor)                                         
        vauxn2      => vsnsvu_n,  		                                                                                              
        vauxp9      => isns5v0_p,   	-- Auxiliary Channel 9 (5V supply voltage monitor)                                        
        vauxn9      => isns5v0_n, 		                                                                                               
        vauxp10     => isns0v95_p,      -- Auxiliary Channel 10 (5V supply current monitor)                                                                  
        vauxn10     => isns0v95_n,
        busy_out    => t_xadc_busy_out,	-- ADC Busy signal                         
        channel_out => open, 			-- Channel Selection Outputs             
        eoc_out     => t_eoc_out,			-- End of Conversion Signal               
        eos_out     => t_eos_out,   	-- End of Sequence Signal                
        alarm_out   => open, 			-- OR'ed output of all the Alarms        
        vp_in       => '0',				-- Dedicated Analog Input Pair            
        vn_in       => '0'
    );

---------------------XADC2LCD Port Mapping---------------------      
tXADC2LCD : XADC2LCD
    port map(
        clk             => clk,             --system clock
        lcd_ready_in    => lcd_ready_in,    --lcdcontroller ready signal (init_done and busy)
        xadc_drdy_in    => t_drdy_out,      --xadc drdy
        xadc_do_in      => t_do_out,        --xadc do_out
        xadc_busy_in    => t_xadc_busy_out, --xadc busy flag
        xadc_eos_in     => t_eos_out,       --xadc end of sequence flag 
        xadc_eoc_in     => t_eoc_out,       --xadc end of sequence flag   
    
        lcd_enable_out  => t_enable_in,     --lcdcontroller enable_in
        lcd_data_out    => t_data_in,       --lcdcontroller data_in 
        xadc_den_out    => t_den_in,        --xadc den_in
        xadc_convst_out => t_convst_in,     --xadc convst_in
        xadc_daddr_out  => t_daddr_in       --xadc daddr_in 
    );
    
---------------------UART_HOST Port Mapping---------------------      
UART_HOST : tUART_HOST
    port map(
        clk             => clk,             --system clock
        rst             => rst,             --system reset
        uart_txd_in     => uart_txd_in,     --uart input
        uart_rxd_out    => uart_rxd_out,    --uart output
        
        bus_cs          => bus_cs,          --bus module select     
        bus_wr          => bus_wr,          --bus write    
        bus_rd          => bus_rd,          --bus read     
        bus_rd_data     => bus_rd_data,     --bus read data
        bus_wr_data     => bus_wr_data,     --bus write data
        bus_addr        => bus_addr         --bus adress   
    );
     
---------------------UART_HOST Port Mapping---------------------      
tregister_interace : register_interface
    port map(
        clk             => clk,             --system clock
        rst             => rst,             --system reset
        --slot interface
        bus_cs          => bus_cs,          --bus module select     
        bus_wr          => bus_wr,          --bus write    
        bus_rd          => bus_rd,          --bus read     
        bus_rd_data     => bus_rd_data,     --bus read data
        bus_wr_data     => bus_wr_data,     --bus write data
        bus_addr        => bus_addr,         --bus adress
        --external signal
        LED             => LED,
        ext_sw          => ext_sw
    );
    
---------------------debounce Port Mapping---------------------    
reset_debounce : debounce
    port map(
        clk => clk,             --Input Clock            
        rst => '0',             --Input Reset            
        button_in => btn(0),    --Input signal (button)  
        pulse_out => rst        --Output debounced signal
    );

end rtl;

----Test for LCD init and busy lcd pins
--process(clk)
--begin 
--    if (falling_edge(clk)) then
--        if(counter < 12 and display_ready = '1') then 
--            t_enable_in <= '1';
--            t_data_in <= hakan(counter);
--            counter <= counter + 1; 
--        else         
--            t_enable_in <= '0';
--        end if;
--    end if;    
--end process;

--ADC Enable only active for one clock (old code)
--display_ready goes high -> display_flag will be set high -> t_den_in and den_in_flag goes high -> reset display_flag until next rising edge of display_ready
--process(clk)
--begin 
--    if (rising_edge(clk)) then
--        t_den_in <= '0';
--        den_in_flag <= '0'; 
--        if (display_flag = '1') then
--            t_den_in <= '1';  
--            den_in_flag <= '1';                  
--        end if;
--    end if;    
--end process;

--process(display_ready, den_in_flag)
--begin 
--    display_flag <= '0';
--    if (rising_edge(display_ready) and den_in_flag = '0') then
--        display_flag <= '1';
--    end if;    
--end process;