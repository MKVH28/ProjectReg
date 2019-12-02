----------------------------------------------------------------------------------
-- Engineer: Volkan Oez
-- 
-- Module Name: tb_uart_mmio_ctrl
-- Project Name: Reg
-- Target Devices: Arty
-- Description: testbench for uart_mmio_ctrl
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

--library xil_defaultlib;
--use xil_defaultlib.all;
--use xil_defaultlib.pkg.all;

entity tb_uart_mmio_ctrl is
end entity tb_uart_mmio_ctrl;
 
architecture rtl of tb_uart_mmio_ctrl is
 
    component uart_mmio_ctrl
        Port ( 
            clk         : in std_logic;
            uart_txd_in : in std_logic;
            uart_rxd_out : out std_logic;
            LED         : out std_logic_vector(3 downto 0);
            ext_sw      : in std_logic_vector(3 downto 0);
            btn         : in std_logic_vector(0 downto 0)
        );
    end component;
 
    --Constant
       
    --Inputs
    signal tb_btn : std_logic_vector(0 downto 0) := "0";
    signal tb_uart_txd_in : std_logic := '1';    
    --Output
    signal tb_uart_rxd_out : std_logic;
    signal tb_LED : std_logic_vector(3 downto 0);    
    
    -- Clock period definitions
    constant clk_period : time := 10 ns;
    signal clock : std_logic := '0' ;
 
begin

    -- Clock process definitions
    clock<=NOT clock AFTER clk_period/2;
 
    -- Stimulus process
    stim_proc: process
    
    begin
        --reset
        tb_btn <= "1";
        wait for 1100us;
        tb_btn <= "0";
        wait for 10us;
        --first uart packet invalid after reset because in wrong state
        tb_uart_txd_in <= '0';
        wait for 104us;
        tb_uart_txd_in <= '1';
        wait for 208us;        
        tb_uart_txd_in <= '0';
        wait for 521us;
        tb_uart_txd_in <= '1'; 
        wait for 5000us;
        --second uart packet 0 = write / 000 = Register 0 / 0010 = GPI Module 
        tb_uart_txd_in <= '0';
        wait for 208us;
        tb_uart_txd_in <= '1';
        wait for 104us;        
        tb_uart_txd_in <= '0';
        wait for 625us;
        tb_uart_txd_in <= '1';
        --expectation is that the uart_controller SM sends back via UART TX the values of the slide switches - in this case 00001011        
        wait for 10ms;
        --terminate simulation
        assert false
            report "Simulation Completed"
        severity failure;
            
    end process stim_proc;
    
    -- Instantiate the Unit Under Test (UUT)
    uut : uart_mmio_ctrl 
    port map(
            clk          => clock,
            uart_txd_in  => tb_uart_txd_in,
            uart_rxd_out => tb_uart_rxd_out,
            LED          => tb_LED,
            ext_sw       => "1011",
            btn          => tb_btn
    );   
        
end rtl;