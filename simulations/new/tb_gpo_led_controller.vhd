----------------------------------------------------------------------------------
-- Engineer: Volkan Oez
-- 
-- Module Name: tb_gpo_led_controller
-- Project Name: Reg
-- Target Devices: Arty
-- Description: Testbench for gpo_led_controller
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
use xil_defaultlib.all;
--use xil_defaultlib.pkg.all;

entity tb_gpo_led_controller is
--  Port ( );
end tb_gpo_led_controller;

architecture rtl of tb_gpo_led_controller is

    -- Component Declaration for the Unit Under Test (UUT)

    component tGPO_LED_CONTROLLER
        generic (
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
    end component;

    --input
    signal tb_led : std_logic_vector(3 downto 0);
    signal tb_rd_data : std_logic_vector (7 downto 0);
    signal tb_reset : std_logic;
    
    --output
    signal tb_wr : std_logic;
    signal tb_rd : std_logic;
    signal tb_wr_data : std_logic_vector (7 downto 0);
    signal tb_addr : std_logic_vector (7 downto 0); 
    signal tb_cs : std_logic; 

    -- Clock period definitions
    constant clk_period : time := 10 ns;
    signal clock : std_logic := '0' ;

begin

    clock<=NOT clock AFTER clk_period/2;

-- Instantiate the Unit Under Test (UUT)
    uut : tGPO_LED_CONTROLLER
    port map( 
        clk             => clock,          
        reset           => tb_reset,
        cs              => tb_cs,
        wr              => tb_wr,
        rd              => tb_rd ,                      
        rd_data         => tb_rd_data,
        wr_data         => tb_wr_data,                      
        addr            => tb_addr,
        led             => tb_led
    );

    tb_cs <= '1' when tb_addr(3 downto 0)="0001" else '0';
    
stim_proc: process
    --coming out of reset - getting data and waiting for completion - depending which order it will be transferred to bus addr or write
    begin
        tb_reset <= '1';
        wait for 95 ns;
        tb_reset <= '0';
        --test chip select
        tb_addr <= "00000000";
        wait for 100 ns;
        tb_wr_data <= x"48";        
        wait for 100 ns;
        --test first dvsr_sel_reg
        tb_addr <= "10000001";
        wait for 100 ns;
        tb_wr_data <= x"01";
        wait for 10 ns;
        tb_wr <= '1';
        wait for 100 ns;
        tb_wr <= '0';
        wait for 100 ns;
        --test second dvsr_sel_reg
        tb_addr <= "10000001";
        wait for 100 ns;
        tb_wr_data <= x"02";
        wait for 10 ns;
        tb_wr <= '1';
        wait for 100 ns;
        tb_wr <= '0';
        wait for 100 ns;
        --test third dvsr_sel_reg
        tb_addr <= "10000001";
        wait for 100 ns;
        tb_wr_data <= x"03";
        wait for 10 ns;
        tb_wr <= '1';
        wait for 100 ns;
        tb_wr <= '0';
        wait for 100 ns;
        --test PWM for first LED
        tb_addr <= "11000001";
        wait for 100 ns;
        tb_wr_data <= x"04";
        wait for 10 ns;
        tb_wr <= '1';
        wait for 100 ns;
        tb_wr <= '0';
        wait for 100 ns; 
        --test offset
--        tb_addr <= "11010001";
--        wait for 100 ns;
--        tb_wr_data <= x"14";
--        wait for 10 ns;
--        tb_wr <= '1';
--        wait for 100 ns;
--        tb_wr <= '0';
--        wait for 1000000 ns;   
        --test alternate blinking one direction
        tb_addr <= "11000001";
        wait for 100 ns;
        tb_wr_data <= x"02";
        wait for 10 ns;
        tb_wr <= '1';
        wait for 100 ns;
        tb_wr <= '0';
        wait for 10 ns;
        tb_addr <= "11010001";
        wait for 100 ns;
        tb_wr_data <= x"24";
        wait for 10 ns;
        tb_wr <= '1';
        wait for 100 ns;
        tb_wr <= '0';
        wait for 10 ns;
        tb_addr <= "11100001";
        wait for 100 ns;
        tb_wr_data <= x"46";
        wait for 10 ns;
        tb_wr <= '1';
        wait for 100 ns;
        tb_wr <= '0';
        wait for 10 ns;
        tb_addr <= "11110001";
        wait for 100 ns;
        tb_wr_data <= x"68";
        wait for 10 ns;
        tb_wr <= '1';
        wait for 100 ns;
        tb_wr <= '0';
        wait for 1000000 ns;        
        -- terminate simulation
        assert false
            report "Simulation Completed"
        severity failure;

    end process;

end rtl;
