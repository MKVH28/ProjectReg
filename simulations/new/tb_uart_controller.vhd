----------------------------------------------------------------------------------
-- Engineer: Volkan Oez
-- 
-- Module Name: tb_uart_controller
-- Project Name: Reg
-- Target Devices: Arty
-- Description: Testbench for uart_contrroller
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

entity tb_uart_controller is
end tb_uart_controller;

architecture rtl of tb_uart_controller is

    -- Component Declaration for the Unit Under Test (UUT)

    component uart_controller
        port ( 
            clk             : in std_logic;
            reset           : in std_logic;
            -- slot interface
            cs              : out std_logic_vector (31 downto 0);
            wr              : out std_logic;
            rd              : out std_logic;
            rd_data         : in std_logic_vector (7 downto 0);
            wr_data         : out std_logic_vector (7 downto 0);
            addr            : out std_logic_vector (7 downto 0);
            --external signals
            rx_data         : in std_logic_vector (7 downto 0);
            rx_done_tick    : in std_logic 
       );
    end component;
    
    --input
    signal tb_rx_data : std_logic_vector(7 downto 0);
    signal tb_rx_done_tick : std_logic;
    signal tb_rd_data : std_logic_vector (7 downto 0);
    signal tb_reset : std_logic;
    
    --output
    signal tb_wr : std_logic;
    signal tb_rd : std_logic;
    signal tb_wr_data : std_logic_vector (7 downto 0);
    signal tb_addr : std_logic_vector (7 downto 0); 
    signal tb_cs : std_logic_vector (31 downto 0);    
    
    -- Clock period definitions
    constant clk_period : time := 10 ns;
    signal clock : std_logic := '0' ;
    
begin

    clock<=NOT clock AFTER clk_period/2;

-- Instantiate the Unit Under Test (UUT)
    uut : uart_controller
    port map( 
        clk             => clock,          
        reset           => tb_reset,
        cs              => tb_cs,
        wr              => tb_wr,
        rd              => tb_rd ,                      
        rd_data         => tb_rd_data,
        wr_data         => tb_wr_data,                      
        addr            => tb_addr,
        rx_data         => tb_rx_data ,
        rx_done_tick    => tb_rx_done_tick
    );
    
    stim_proc: process
    --coming out of reset - getting data and waiting for completion - depending which order it will be transferred to bus addr or write
    begin
        tb_reset <= '1';
        wait for 95 ns;
        tb_reset <= '0';
        tb_rx_data <= x"84";
        wait for 100 ns;
        tb_rx_done_tick <= '1';
        wait for 10 ns;
        tb_rx_done_tick <= '0';
        wait for 100 ns;
        tb_rx_data <= x"48";
        wait for 100 ns;
        tb_rx_done_tick <= '1';
        wait for 10 ns;
        tb_rx_done_tick <= '0';
        wait for 100 ns;
        tb_rx_data <= x"00";
        wait for 100 ns;
        tb_rx_done_tick <= '1';
        wait for 10 ns;
        tb_rx_done_tick <= '0';
        wait for 100 ns;
        tb_rx_data <= x"80";
        wait for 100 ns;
        tb_rx_done_tick <= '1';
        wait for 10 ns;
        tb_rx_done_tick <= '0';
        wait for 100 ns;
        tb_rx_data <= x"03";
        wait for 100 ns;
        tb_rx_done_tick <= '1';
        wait for 10 ns;
        tb_rx_done_tick <= '0';
        wait for 100 ns;
        -- terminate simulation
        assert false
            report "Simulation Completed"
        severity failure;
                                              
    end process;
        
end;
