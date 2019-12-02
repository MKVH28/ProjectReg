----------------------------------------------------------------------------------
-- Engineer: Volkan Oez
-- 
-- Module Name: lcd_controller
-- Project Name: Reg
-- Target Devices: Arty
-- Description: display module (init + display function) 
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity lcd_controller is
    port( 
        clk             : in std_logic;                     --system clock
        enable_in       : in std_logic;                     --latches data into lcd controller, reset        
        data_in         : in std_logic_vector(9 downto 0);  --data signals input for LCD
        rw_out          : out std_logic;                    --read/write
        rs_out          : out std_logic;                    --register select (instruction register or data register)
        enable_out      : out std_logic;                    --enable for LCD
        busy_out        : out std_logic := '1';             --busy signal
        data_out        : out std_logic_vector(7 downto 0); --data signals output for LCD
        init_done_out   : out std_logic := '0'              --init done signal
    );
end lcd_controller;
--, rst_in 
architecture rtl of lcd_controller is
    type control is (power_up, 
                     init_first,
                     wait1, 
                     init_second, 
                     wait2, 
                     init_third, 
                     init_fourth, 
                     init_fifth, 
                     init_sixth,
                     wait3, 
                     init_seventh, 
                     ready,
                     send);
    signal state : control;
    constant freq : integer := 100;                                             --system clock in MHz --> 1 * freq = 10ns * 100 = 1us
    constant wait_addr_setup_time : integer := 10;                              --address setup time min 40ns
    constant wait_enable_pulse_width : integer := wait_addr_setup_time + 30;    --enable pulse width min 250ns
    constant wait_execution : integer := wait_enable_pulse_width + 4000;        --execution time 40us normally 

begin
    process(clk)
        variable clk_count : INTEGER := 0; -- event counter for timing
    begin
        if(rising_edge(clk)) then
            case state is
                --power on -> wait 50ms for Vcc to stabilize
                when power_up =>
                    clk_count := clk_count + 1;
                    busy_out <= '1';
                    if(clk_count < (50000 * freq)) then                         
                        state <= power_up;
                    else
                        clk_count := 0;
                        rs_out <= '0'; --instruction register for initialization 
                        rw_out <= '0'; --write
                        enable_out <= '0';
                        state <= init_first;
                    end if;
               
               -- init_first = first function set
                when init_first =>
                    clk_count := clk_count + 1; 
                    if(clk_count < wait_addr_setup_time) then --wait 50ns between RS/RW change and EN high
                        state <= init_first;
                        data_out <= "00111000"; --function set "0011****"
                    elsif(clk_count < wait_enable_pulse_width) then --hold EN high for min 250ns
                        enable_out <= '1';                                                        
                        state <= init_first;
                    elsif(clk_count < wait_execution) then --hold en low for min 250ns and wait 40us before new command
                        enable_out <= '0';
                        state <= init_first;
                    else 
                        clk_count := 0;
                        state <= wait1;
                    end if;
                        
                -- wait1 = wait min 4.1ms after first function set       
                when wait1 =>
                    clk_count := clk_count + 1; 
                    if(clk_count < 4100 * freq) then --wait 4.1ms
                        state <= wait1;
                    else 
                        clk_count := 0;
                        state <= init_second;
                    end if;
                        
                -- init_second = second function set                
                when init_second =>
                    clk_count := clk_count + 1; 
                    if(clk_count < wait_addr_setup_time) then --wait 50ns between RS/RW change and EN high
                        state <= init_second;
                        data_out <= "00111000"; --function set "0011****"
                    elsif(clk_count < wait_enable_pulse_width) then --whold EN high for min 250ns
                        enable_out <= '1';
                        state <= init_second;
                    elsif(clk_count < wait_execution) then --hold en low for min 250ns and wait 40us before new command
                        enable_out <= '0';
                        state <= init_second;
                    else 
                        clk_count := 0;
                        state <= wait2;
                    end if;
                    
                --wait2 = wait min 100us after second function set
                when wait2 =>
                    clk_count := clk_count + 1; 
                    if(clk_count < 100 * freq) then --wait 100us
                        state <= wait2;
                    else 
                        clk_count := 0;
                        state <= init_third;
                    end if;
                    
                -- init_third = third function set                
                when init_third =>
                    clk_count := clk_count + 1; 
                    if(clk_count < wait_addr_setup_time) then --wait 50ns between RS/RW change and EN high
                        state <= init_third;
                        data_out <= "00111000"; --set "0011****"
                    elsif(clk_count < wait_enable_pulse_width) then --hold EN high for min 250ns
                        enable_out <= '1';
                        state <= init_third;
                    elsif(clk_count < wait_execution) then --hold en low for min 250ns and wait 40us before new command
                        enable_out <= '0';
                        state <= init_third;
                    else 
                        clk_count := 0;
                        state <= init_fourth;
                    end if;
                    
                -- init_fourth = fourth function set - N=1 2-line / F=0 5x8 dots                 
                when init_fourth =>
                    clk_count := clk_count + 1; 
                    if(clk_count < wait_addr_setup_time) then --wait 50ns between RS/RW change and EN high
                        state <= init_fourth;
                        data_out <= "00111000"; --set "00111000"                        
                    elsif(clk_count < wait_enable_pulse_width) then --hold EN high for min 250ns
                        enable_out <= '1';
                        state <= init_fourth;
                    elsif(clk_count < wait_execution) then --hold en low for min 250ns and wait 40us before new command
                        enable_out <= '0';
                        state <= init_fourth;
                    else 
                        clk_count := 0;
                        state <= init_fifth;
                    end if;
                    
                -- init_fifth = fifth function set - display on, cursor on, blink on                 
                when init_fifth =>
                    clk_count := clk_count + 1; 
                    if(clk_count < wait_addr_setup_time) then --wait 50ns between RS/RW change and EN high
                        state <= init_fifth;
                        data_out <= "00001111"; --set "00001111"
                    elsif(clk_count < wait_enable_pulse_width) then --hold EN high for min 250ns
                        enable_out <= '1';
                        state <= init_fifth;
                    elsif(clk_count < wait_execution) then --hold en low for min 250ns and wait 40us before new command
                        enable_out <= '0';
                        state <= init_fifth;
                    else 
                        clk_count := 0;
                        state <= init_sixth;
                    end if;
                
                -- init_sixth = sixth function set - clear display                 
                when init_sixth =>
                    clk_count := clk_count + 1; 
                    if(clk_count < wait_addr_setup_time) then --wait 50ns between RS/RW change and EN high
                        state <= init_sixth;
                        data_out <= "00000001"; --set "00000001"
                    elsif(clk_count < wait_enable_pulse_width) then --whold EN high for min 250ns
                        enable_out <= '1';
                        state <= init_sixth;
                    elsif(clk_count < wait_execution) then --hold en low for min 250ns and wait 40us before new command
                        enable_out <= '0';
                        state <= init_sixth;
                    else 
                        clk_count := 0;
                        state <= wait3;
                    end if;
                
                when wait3 =>
                    clk_count := clk_count + 1; 
                    if(clk_count < 1700 * freq) then --wait 1.7ms
                        state <= wait3;
                    else 
                        clk_count := 0;
                        state <= init_seventh;
                    end if;
                
                -- init_seventh = seventh function set - entry mode set                 
                when init_seventh =>
                    clk_count := clk_count + 1; 
                    if(clk_count < wait_addr_setup_time) then --wait 50ns between RS/RW change and EN high
                        state <= init_seventh;
                        data_out <= "00000110"; --set "00000110"
                    elsif(clk_count < wait_enable_pulse_width) then --hold EN high for min 250ns
                        enable_out <= '1';
                        state <= init_seventh;
                    elsif(clk_count < wait_execution) then --hold en low for min 250ns and wait 40us before new command
                        enable_out <= '0';
                        state <= init_seventh;
                    else 
                        clk_count := 0;
                        state <= ready;
                        rs_out <= '1'; --init done and ready to write
                        busy_out <= '0'; 
                        init_done_out <= '1';
                    end if;
                
                -- ready = waiting for input 
                when ready =>
                    if(enable_in = '1') then
                        busy_out <= '1';
                        state <= send;
                        rs_out <= data_in(9);
                        rw_out <= data_in(8);   
                    else
                        busy_out <= '0';
                        rs_out <= data_in(9);
                        rw_out <= data_in(8);
                        data_out <= "00000000";
                        state <= ready;
                    end if;
                    
                -- send = send out data
                when send =>
                    clk_count := clk_count + 1;                                      
                    if(clk_count < wait_addr_setup_time) then --wait 50ns between RS/RW change and EN high
                        state <= send;
                        data_out <= data_in(7 downto 0); 
                    elsif(clk_count < wait_enable_pulse_width) then --whold EN high for min 250ns
                        enable_out <= '1';
                        state <= send;
                    elsif(clk_count < wait_execution) then --hold en low for min 250ns and wait 40us before new command
                        enable_out <= '0';
                        state <= send;
                    else 
                        clk_count := 0;
                        state <= ready;
                    end if;
                      
            end case;
        end if;
    end process;    
end rtl;

-- Testing
-- when test1 =>                    
    -- clk_count := clk_count + 1; 
    -- if(clk_count < 5) then --wait 50ns between RS/RW change and EN high
        -- state <= test1;
        -- data_out <= x"48"; --set "00001111"
    -- elsif(clk_count < 30) then --whold EN high for min 250ns
        -- enable_out <= '1';
        -- state <= test1;
    -- elsif(clk_count < 4030) then --hold en low for min 250ns before new command
        -- enable_out <= '0';
        -- state <= test1;
    -- else 
        -- clk_count := 0;
        -- state <= test2;
    -- end if;
    

-- when test2 =>                    
    -- clk_count := clk_count + 1; 
    -- if(clk_count < 5) then --wait 50ns between RS/RW change and EN high
        -- state <= test2;
        -- data_out <= x"48"; --set "00001111"
    -- elsif(clk_count < 30) then --whold EN high for min 250ns
        -- enable_out <= '1';
        -- state <= test2;
    -- elsif(clk_count < 4030) then --hold en low for min 250ns before new command
        -- enable_out <= '0';
        -- state <= test2;
    -- else 
        -- --clk_count := 0;
        -- led_1 <= '1';
    -- end if;