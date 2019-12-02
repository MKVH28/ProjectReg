----------------------------------------------------------------------------------
-- Engineer: Volkan Oez
-- 
-- Module Name: register_interface
-- Project Name: Reg
-- Target Devices: Arty
-- Description: Register Interface which connects the register to all other modules
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

entity register_interface is
    Port (
        clk         : in std_logic;
        rst       : in std_logic;
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
end register_interface;


architecture rtl of register_interface is

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
    
    type rd_file_type is array (15 downto 0) of 
         std_logic_vector(7 downto 0);
         
    signal rd_data_array : rd_file_type := (others => (others => '0' ));
    
begin
                
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
        
bus_rd_data <= rd_data_array(to_integer(unsigned(bus_addr)));
        
end rtl;

