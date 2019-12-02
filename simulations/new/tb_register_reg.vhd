----------------------------------------------------------------------------------
-- Engineer: Volkan Oez
-- 
-- Module Name: tb_register_reg
-- Project Name: Reg
-- Target Devices: Arty
-- Description: testbench / register file for project reg
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

entity tb_register_reg is
end tb_register_reg;

architecture rtl of tb_register_reg is

    component register_reg
        generic(
            B: integer; --number of bits
            W: integer  --number of address bits
        );
        port(
            clk, reset      : in std_logic;                      --system clock and reset
            wr_en           : in std_logic;                      --write enable
            w_addr          : in std_logic_vector(W-1 downto 0); --write address
            w_data          : in std_logic_vector(B-1 downto 0); --write data
            r_addr_0        : in std_logic_vector(W-1 downto 0); --read address
            r_addr_1        : in std_logic_vector(W-1 downto 0); --read address
            r_data_0        : out std_logic_vector(B-1 downto 0);--read data
            r_data_1        : out std_logic_vector(B-1 downto 0) --read data
        );
    end component;
    
    --constant
    constant B : integer := 4;
    constant W : integer := 1;
    
    --input
    signal tb_reset     : std_logic;
    signal tb_wr_en     : std_logic;
    signal tb_w_addr    : std_logic_vector(W-1 downto 0);
    signal tb_r_addr_0  : std_logic_vector(W-1 downto 0);
    signal tb_r_addr_1  : std_logic_vector(W-1 downto 0);
    signal tb_w_data    : std_logic_vector(B-1 downto 0);
    
    --output
    signal tb_r_data_0 : std_logic_vector(B-1 downto 0);
    signal tb_r_data_1 : std_logic_vector(B-1 downto 0);
    
    -- Clock period definitions
    constant clk_period : time := 10 ns;
    signal clock : std_logic := '0' ;

begin

    clock<=NOT clock AFTER clk_period/2;

    uut : register_reg
    generic map(
        B => B,
        W => W
        )
    port map( 
        clk             => clock,          
        reset           => tb_reset,
        wr_en           => tb_wr_en,
        w_addr          => tb_w_addr,
        r_addr_0        => tb_r_addr_0,
        r_addr_1        => tb_r_addr_1,
        w_data          => tb_w_data,
        r_data_0        => tb_r_data_0,
        r_data_1        => tb_r_data_1
    );

    stim_proc: process
    
    begin
        
        --initial input
        tb_reset <= '1';
        tb_wr_en <= '0';
        tb_w_addr <= (others=>'0');
        tb_r_addr_0 <= "0";
        tb_r_addr_1 <= "1";
        tb_w_data <= (others=>'0');
        wait for 90 ns;
        --write register 0
        tb_reset <= '0';
        wait until rising_edge(clock);
        tb_w_data <= "0101";
        wait until rising_edge(clock);
        tb_wr_en <= '1';
        wait until rising_edge(clock);
        tb_wr_en <= '0';
        wait until rising_edge(clock);
        --write register 1
        tb_w_addr <= "1";
        wait until rising_edge(clock);
        tb_w_data <= "0011";
        wait until rising_edge(clock);
        tb_wr_en <= '1';
        wait until rising_edge(clock);
        tb_wr_en <= '0';
        wait until rising_edge(clock);
        --reset test
        tb_reset <= '1';       
        wait;
                 
    end process;

end rtl;
