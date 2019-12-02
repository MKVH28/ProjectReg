----------------------------------------------------------------------------------
-- Engineer: Volkan Oez
-- 
-- Module Name: tb_XADC2LCD
-- Project Name: Reg
-- Target Devices: Arty
-- Description: Testbench for XAD2LCD
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
--use xil_defaultlib.pkg.all;

entity tb_XADC2LCD is
end tb_XADC2LCD;

architecture rtl of tb_XADC2LCD is

    component XADC2LCD
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
    
    --input
    signal tb_lcd_enable_out    : std_logic := '0';
    signal tb_lcd_data_out      : std_logic_vector(9 downto 0) := (others => '0');
    signal tb_xadc_den_out      : std_logic := '0';
    signal tb_xadc_convst_out      : std_logic := '0';
    signal tb_xadc_daddr_out       : std_logic_vector(6 downto 0) := (others => '0');
    
    --output
    signal tb_lcd_ready_in      : std_logic := '0';
    signal tb_xadc_drdy_in      : std_logic := '0';
    signal tb_xadc_do_in        : std_logic_vector(15 downto 0) := (others => '0');
    signal tb_xadc_busy_in      : std_logic := '0';
    signal tb_xadc_eos_in       : std_logic := '0';
    signal tb_xadc_eoc_in       : std_logic := '0';
    
    -- Clock period definitions
    constant clk_period : time := 10 ns;
    signal clock : std_logic := '0' ;
    signal clock_counter : integer := 81;
    signal clock_counter_2 : integer := 9400;
    
        
begin

    clock<=NOT clock AFTER clk_period/2;
    
    lcd_ready_pulse : process(clock)
    begin
        clock_counter <= clock_counter + 1;
        if(clock_counter = 99) then
            tb_lcd_ready_in <= '1';
        elsif(clock_counter = 100) then
            clock_counter <= 0;
        else
            tb_lcd_ready_in <= '0';
        end if;
    end process;
    
    -- xadc_dry_pulse : process(clock)
    -- begin
        -- clock_counter_2 <= clock_counter_2 + 1;
        -- if(clock_counter_2 = 9999) then
            -- tb_xadc_drdy_in <= '1';
        -- elsif(clock_counter_2 = 10000) then
            -- clock_counter_2 <= 0;
        -- else
            -- tb_xadc_drdy_in <= '0';
        -- end if;
    -- end process;

-- Instantiate the Unit Under Test (UUT)
    uut : XADC2LCD
    port map( 
        clk             => clock,          
        lcd_ready_in    => tb_lcd_ready_in,
        xadc_drdy_in    => tb_xadc_drdy_in,
        xadc_do_in      => tb_xadc_do_in,
        xadc_busy_in    => tb_xadc_busy_in,
        xadc_eos_in     => tb_xadc_eos_in,
        xadc_eoc_in     => tb_xadc_eoc_in,
        
        lcd_enable_out  => tb_lcd_enable_out,
        lcd_data_out    => tb_lcd_data_out,
        xadc_den_out    => tb_xadc_den_out,
        xadc_convst_out => tb_xadc_convst_out,
        xadc_daddr_out  => tb_xadc_daddr_out 
    );

---------------------XADC Port Mapping---------------------  
tXADC : xadc_wiz_0
    port map(
        daddr_in    => tb_xadc_daddr_out,      -- Address bus for the dynamic reconfiguration port         
        den_in      => tb_xadc_den_out,		-- Enable Signal for the dynamic reconfiguration port             
        di_in       => (others => '0'),	-- Input data bus for the dynamic reconfiguration port      
        dwe_in      => '0',				-- Write Enable for the dynamic reconfiguration port                 
        do_out      => tb_xadc_do_in,		-- Output data bus for dynamic reconfiguration port               
        drdy_out    => tb_xadc_drdy_in,		-- Data ready signal for the dynamic reconfiguration port       
        dclk_in     => clock,				-- Clock input for the dynamic reconfiguration port / 100MHz         
        reset_in    => '0',				-- Reset signal for the System Monitor control logic
        convst_in   => tb_xadc_convst_out,     -- Convert Start Input                      
        vauxp1      => '0',  	    -- Auxiliary Channel 1 (FPGA core supply monitorexternal supply voltage monitor)                                    
        vauxn1      => '0',   		                                                                                              
        vauxp2      => '0', 		-- Auxiliary Channel 2 (external supply voltage monitor)                                         
        vauxn2      => '0',  		                                                                                              
        vauxp9      => '0',   	-- Auxiliary Channel 9 (5V supply voltage monitor)                                        
        vauxn9      => '0', 		                                                                                               
        vauxp10     => '0',      -- Auxiliary Channel 10 (5V supply current monitor)                                                                  
        vauxn10     => '0',
        busy_out    => tb_xadc_busy_in,	-- ADC Busy signal                         
        channel_out => open, 			-- Channel Selection Outputs             
        eoc_out     => tb_xadc_eoc_in,			-- End of Conversion Signal               
        eos_out     => tb_xadc_eos_in,   	-- End of Sequence Signal                
        alarm_out   => open, 			-- OR'ed output of all the Alarms        
        vp_in       => '0',				-- Dedicated Analog Input Pair            
        vn_in       => '0'
    );
    
    stim_proc: process
        
        procedure check_XADC2LCD(in1 : in std_logic_vector(15 downto 0)) is
                variable res : std_logic_vector(9 downto 0);
                variable i : natural := 1;
            begin 
                -- wait for 95ns;
                -- --condition to leave "wait_display_ready" state
                -- tb_xadc_busy_in <= '0';           
                -- --condition to leave "xadc_trigger" state
                -- --models xadc sampling convst and setting busy flag 
                -- wait for 10ns; 
                -- tb_xadc_busy_in <= '1';
                -- --condition to leave "wait_xadc_EOS"
                -- --models waiting time until xadc is finished sampling and setting end of sequence flag
                -- wait for 260ns; --xilinx datasheet xadc p.73/75
                -- tb_xadc_eos_in <= '1';
                -- tb_xadc_busy_in <= '0';
                -- wait for 10ns;
                -- tb_xadc_eos_in <= '0';
                -- --waiting time until "xadc_addr" and "den_pulse" are over before modelling reading back is successful
                -- wait until tb_xadc_den_out = '1';
                -- wait until tb_xadc_den_out = '0';
                -- wait for 40ns; --xilinx datasheet xadc p.73/75                
                -- --tb_xadc_drdy_in <= '1';                
                -- wait for 10ns;
                -- --tb_xadc_drdy_in <= '0';
            end procedure check_XADC2LCD;
        
        begin
            -- tb_xadc_do_in <= x"0722";
            -- check_XADC2LCD(tb_xadc_do_in);
            wait;               
        end process;
        
end rtl;
