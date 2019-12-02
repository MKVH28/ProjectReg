----------------------------------------------------------------------------------
-- Engineer: Volkan Oez
-- 
-- Module Name: XADC2LCD
-- Project Name: Reg
-- Target Devices: Arty
-- Description: state machine for conversion from XADC result to LCD format
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

entity XADC2LCD is
    port(
        clk             : in std_logic;                     --system clock
        lcd_ready_in    : in std_logic;                     --lcdcontroller ready signal (init_done and busy)
        xadc_drdy_in    : in std_logic;                     --xadc drdy
        xadc_do_in      : in std_logic_vector(15 downto 0); --xadc do_out   
        xadc_busy_in    : in std_logic;                     --xadc busy flag     
        xadc_eos_in     : in std_logic := '0';                     --xadc end of sequence flag 
        xadc_eoc_in     : in std_logic := '0';                     --xadc end of sequence flag 
        
        lcd_enable_out  : out std_logic := '0';             --lcdcontroller enable_in
        lcd_data_out    : out std_logic_vector(9 downto 0); --lcdcontroller data_in 
        xadc_den_out    : out std_logic;                    --xadc den_in
        xadc_convst_out : out std_logic;                    --xadc convst_in       
        xadc_daddr_out  : out std_logic_vector(6 downto 0)  --xadc daddr_in 
    );
end XADC2LCD;

architecture rtl of XADC2LCD is
    
    --state machine cases
    type xadc2lcd_status is(
        wait_display_ready,
        xadc_trigger,
        wait_xadc_busy,
        wait_xadc_EOS,
        xadc_addr, 
        den_pulse,
        wait_drdy,
        wait_DV,
        create_matrix,
        display_nxt_line,
        clear_display,
        wait_display,
        next_line_display,
        clk_count_value,
        send_string,
        space_display,
        send_number,
        exit_condition
    ); 
                                
    signal state : xadc2lcd_status := wait_display_ready;
    constant freq : integer := 100;
    
    --Component to convert xadc binary result to binary coded decimal
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
    constant g_INPUT_WIDTH_2 : positive := 12;  
    constant g_DECIMAL_DIGITS : positive := 4;
    
    --Inputs
    signal XADC2LCD_BCD_start : std_logic := '0';
    signal xadc_do_shift : std_logic_vector(15 downto 0) := (others => '0');
    
    --Outputs
    signal XADC2LCD_BCD_BCD : std_logic_vector(g_DECIMAL_DIGITS*4-1 downto 0);
    signal XADC2LCD_BCD_DV : std_logic;
    
    component CnM
        generic (
            g_INPUT_WIDTH       : in positive; --CnM input width 
            g_DECIMAL_DIGITS    : in positive; --CnM vector width
            g_DISPLAY_CONSTANT  : in positive; --first x bit of the LCD display output
            g_DISPLAY_WIDTH     : in positive  --Width of LCD display constant 
        );
        port ( 
            CnM_BCD_in              : in std_logic_vector(g_INPUT_WIDTH-1 downto 0);    --BCD input vector converted XADC output
            CnM_start_in            : in std_logic;                                     --Latch new matrix
            
            CnM_display_matrix_out  : out send_array(0 to 3)                            --BCD converted to an array for the display
        );
    end component;

    type xadc_daddr is array (natural range <>) of std_logic_vector(6 downto 0);

    --Constant 
    constant g_DISPLAY_CONSTANT : positive := 35;  
    constant g_DISPLAY_WIDTH : positive := 6;
    constant daddr_const : xadc_daddr := ("0000000", "0000001", "0000010", "0000110", "0010001", "0010010", "0011001", "0011010"); -- x00, x01, x02, x06, x11, x12, x19, x1A
    
    --Inputs
    signal XADC2LCD_CnM_start : std_logic := '0';
    
    --Outputs
    signal XADC2LCD_CnM_display_matrix : send_array(0 to 3);
    signal XADC2LCD_string_display_matrix : send_array(0 to 7) := (others => (others => '0'));
        
begin

    process(clk)
        variable clk_count : integer  := 0; -- event counter for timing
        variable daddr_counter : integer := 0; -- counter for selecting the correct xadc register addr
        variable first_line_flag : std_logic := '1'; -- flag for detecting if first row or second of the display will be used
        variable string_flag : std_logic := '1'; -- flag for detecting if string or number will be used
    begin
        if (rising_edge(clk)) then
            case state is
            
                --idle state wait_display_ready
                --condition: waiting for display ready signal (not busy and init done) and trigger conversion
                --assignment: start xadc conversion
                when wait_display_ready =>
                    lcd_enable_out <= '0';
                    xadc_convst_out <= '0';
                    if(lcd_ready_in = '1' and xadc_busy_in = '0') then                       
                        state <= xadc_trigger;                        
                        xadc_convst_out <= '1';
                    else
                        state <= wait_display_ready;
                    end if;
                
                --xadc_trigger
                --condition: wait until xadc busy flag is asserted
                --assignment: since xadc is now busy xadc conversion start bit is deasserted
                when xadc_trigger =>
                    if(xadc_busy_in = '1') then                         
                        state <= wait_xadc_EOS;
                        xadc_convst_out <= '0';
                    else
                        state <= xadc_trigger;
                    end if; 
                
                --wait_xadc_busy    
                --condition: wait until xadc busy flag is deasserted
                --assignment: nothing - xadc is finished  
                when wait_xadc_busy =>
                    if(xadc_busy_in = '0') then                         
                        state <= wait_xadc_EOS;
                    else
                        state <= wait_xadc_busy;
                    end if;
                                    
                --wait_xadc_eos                    
                --condition: either end of sequence or conversion is asserted
                --assignment: if end of conversion go to wait_display_ready and if end of sequence go xadc_addr    
                when wait_xadc_EOS =>
                    if(xadc_eos_in = '1') then                         
                        state <= xadc_addr;
                    elsif(xadc_eoc_in = '1') then
                        state <= wait_display_ready;
                    else
                        state <= wait_xadc_EOS;
                    end if;
                
                --xadc_addr
                --no condition and assignment
                --at this point the state machine will loop 8 times - reading the register value, set up format for LCD and show on LCD                                    
                --select next addr for register read command   
                when xadc_addr =>
                    xadc_daddr_out <= daddr_const(daddr_counter);
                    state <= den_pulse;
                    
                --den_pulse
                --no condition and assignment 
                --this pulse will sample xadc daddr for reading register on the next rising edge of the clock    
                when den_pulse =>
                    xadc_den_out <= '1';
                    state <= wait_drdy;
                
                --wait_drdy
                --condition: wait until xadc drdy is asserted
                --assignment: deassert xadc den and once read is completed and asserted via xadc drdy start BCD on the sampled value
                when wait_drdy =>
                    xadc_den_out <= '0';
                    if(xadc_drdy_in = '1') then                         
                        state <= wait_DV;
                        XADC2LCD_BCD_start <= '1';
                    else
                        state <= wait_drdy;
                    end if;
                    
                --wait_DV
                --condition: wait until BCD is finished and asserted via DV signal
                --assignement: reset clk_counter and assert CnM start 
                when wait_DV =>
                    XADC2LCD_BCD_start <= '0';
                    if(XADC2LCD_BCD_DV = '1') then                         
                        state <= create_matrix;
                        clk_count := 0;
                        XADC2LCD_CnM_start <= '1';
                    else
                        state <= wait_DV;
                    end if;
                
                --create_matrix
                --condition: wait 100ns
                --assignement: reset clk_counter and deassert CnM start
                when create_matrix =>
                    clk_count := clk_count + 1;
                    if(clk_count > 9) then                         
                        state <= display_nxt_line;
                        XADC2LCD_CnM_start <= '0';
                        clk_count := 0;
                    else
                        state <= create_matrix;
                    end if;                
                
                --display_nxt_line
                --no condition and assignment
                --if first line flag is 1 it will clear display before writing new values
                --if first line flag is 0 it will jump to the next row before writing new values     
                when display_nxt_line =>                    
                    if(first_line_flag = '1') then
                        state <= clear_display;
                    elsif(first_line_flag = '0') then
                        state <= next_line_display;
                    end if;
                    
                --clear_display
                --condition: check if lcd is ready
                --assignment: enable output
                when clear_display =>
                    if(lcd_ready_in = '1') then
                        lcd_data_out <= clear_display_cmd;
                        lcd_enable_out <= '1';
                        state <= wait_display;
                    else
                        state <= clear_display;
                    end if;
                    
                --next line command 
                --condition: check if lcd is ready
                --assignment: enable output    
                when next_line_display =>
                    if(lcd_ready_in = '1') then
                        lcd_data_out <= next_line_cmd;
                        lcd_enable_out <= '1';
                        state <= wait_display;
                    else
                        state <= next_line_display;
                    end if;
                
                --display_wait
                --clear display cmd 1.7ms and next line cmd 40us
                when wait_display =>
                    clk_count := clk_count + 1; 
                    lcd_enable_out <= '0';
                    if(first_line_flag = '1' and string_flag = '1') then
                        if(clk_count < 1700 * freq) then
                            state <= wait_display;
                        else
                            state <= clk_count_value;
                        end if;
                    else
                        if(clk_count < 40 * freq) then
                            state <= wait_display;
                        else
                            state <= clk_count_value;
                        end if;                                               
                    end if;   
                
                --select correct clk_count value for sending the bits to the display
                when clk_count_value =>
                    if(string_flag = '1') then
                        state <= send_string;
                        if(daddr_counter = 0) then
                            clk_count := dietemp_matrix'length;
                            XADC2LCD_string_display_matrix(0 to dietemp_matrix'length - 1) <= dietemp_matrix;
                        elsif(daddr_counter = 1) then
                            clk_count := vccint_matrix'length;
                            XADC2LCD_string_display_matrix(0 to vccint_matrix'length - 1) <= vccint_matrix;
                        elsif(daddr_counter = 2) then
                            clk_count := vccaux_matrix'length;
                            XADC2LCD_string_display_matrix(0 to vccaux_matrix'length - 1) <= vccaux_matrix;
                        elsif(daddr_counter = 3) then
                            clk_count := vccbram_matrix'length;
                            XADC2LCD_string_display_matrix(0 to vccbram_matrix'length - 1) <= vccbram_matrix;
                        elsif(daddr_counter = 4) then
                            clk_count := vsnsvu_matrix'length;
                            XADC2LCD_string_display_matrix(0 to vsnsvu_matrix'length - 1) <= vsnsvu_matrix;
                        elsif(daddr_counter = 5) then
                            clk_count := vsns5v0_matrix'length;
                            XADC2LCD_string_display_matrix(0 to vsns5v0_matrix'length - 1) <= vsns5v0_matrix;
                        elsif(daddr_counter = 6) then
                            clk_count := isns5v0_matrix'length;
                            XADC2LCD_string_display_matrix(0 to isns5v0_matrix'length - 1) <= isns5v0_matrix;
                        elsif(daddr_counter = 7) then
                            clk_count := isns0v95_matrix'length;
                            XADC2LCD_string_display_matrix(0 to isns0v95_matrix'length - 1) <= isns0v95_matrix;
                        end if;
                    else 
                        state <= send_number;
                        clk_count := 4;
                    end if;   
                  
                --send string to display with counting down for correct order                         
                when send_string =>
                    if(clk_count /= 0 and lcd_ready_in = '1') then                         
                        state <= send_string;
                        lcd_enable_out <= '1';
                        lcd_data_out <= XADC2LCD_string_display_matrix(clk_count-1);
                        clk_count := clk_count-1;
                    elsif(clk_count = 0) then
                        clk_count := 0;                        
                        lcd_enable_out <= '0';
                        state <= space_display;
                    else
                        state <= send_string;
                        lcd_enable_out <= '0';
                    end if;
                
                --space_display
                --condition: lcd is ready
                --assignment: string flag zero because next will be a number, enable LCD and send the shift command for the cursor
                when space_display =>
                    string_flag := '0';
                    if(lcd_ready_in = '1') then
                        lcd_data_out <= space_cmd;
                        lcd_enable_out <= '1';
                        state <= wait_display;
                    else
                        state <= space_display;
                    end if;
                
                --send_number
                --condition: clk counter unequal to zero and lcd is ready / once counter is equal to zero - move to next state
                --assignment: asas condition is met LCD will be enabled, counting down and LCD data will take the value
                --send matrix to display with counting down for correct order                         
                when send_number =>
                    if(clk_count /= 0 and lcd_ready_in = '1') then                         
                        state <= send_number;
                        lcd_enable_out <= '1';
                        lcd_data_out <= XADC2LCD_CnM_display_matrix(clk_count-1);
                        clk_count := clk_count-1;
                    elsif(clk_count = 0) then                                                
                        lcd_enable_out <= '0';
                        clk_count := 0;
                        state <= exit_condition;
                    else
                        state <= send_number;
                        lcd_enable_out <= '0';
                    end if;
                
                --exit_condition
                --condition: daddr counter value decides if next loop iteration or starting from first state
                --assignment: count up daddr counter and reset if starting anew, assert string flag since a new line will be written
                --toggle first line flag since the LCD shows 2 lines                
                when exit_condition => 
                    daddr_counter := daddr_counter + 1;
                    string_flag := '1';
                    first_line_flag := not(first_line_flag);
                    if(daddr_counter>7) then
                        daddr_counter := 0;
                        state <= wait_display_ready;                            
                    else
                        state <= xadc_addr;
                    end if;                     
                    
            end case;
        end if; 
    
    xadc_do_shift <= x"0" & xadc_do_in(15 downto 4); 
        
    end process;

    tBIN2BCD : Binary_to_BCD
        generic map(
            g_INPUT_WIDTH => g_INPUT_WIDTH,
            g_DECIMAL_DIGITS => g_DECIMAL_DIGITS
            )   
        port map(
            i_Clock => clk,
            i_Binary => xadc_do_shift,
            i_Start => XADC2LCD_BCD_start,
            o_BCD => XADC2LCD_BCD_BCD,
            o_DV => XADC2LCD_BCD_DV
        );
        
    tCnM : CnM
        generic map(
            g_INPUT_WIDTH => g_INPUT_WIDTH,
            g_DECIMAL_DIGITS => g_DECIMAL_DIGITS,
            g_DISPLAY_CONSTANT => g_DISPLAY_CONSTANT,
            g_DISPLAY_WIDTH => g_DISPLAY_WIDTH
            )   
        port map(
            CnM_BCD_in => XADC2LCD_BCD_BCD,
            CnM_start_in => XADC2LCD_CnM_start,
            CnM_display_matrix_out => XADC2LCD_CnM_display_matrix
        );  

end rtl;
