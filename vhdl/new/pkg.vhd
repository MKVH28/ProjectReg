library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package pkg is
    type send_array is array (natural range <>) of std_logic_vector(9 downto 0);
    
    constant LCD_0 : std_logic_vector(9 downto 0) := "10" & x"30";    
    constant LCD_1 : std_logic_vector(9 downto 0) := "10" & x"31";    
    constant LCD_2 : std_logic_vector(9 downto 0) := "10" & x"32";    
    constant LCD_3 : std_logic_vector(9 downto 0) := "10" & x"33";    
    constant LCD_4 : std_logic_vector(9 downto 0) := "10" & x"34";    
    constant LCD_5 : std_logic_vector(9 downto 0) := "10" & x"35";    
    constant LCD_6 : std_logic_vector(9 downto 0) := "10" & x"36";    
    constant LCD_7 : std_logic_vector(9 downto 0) := "10" & x"37";    
    constant LCD_8 : std_logic_vector(9 downto 0) := "10" & x"38";    
    constant LCD_9 : std_logic_vector(9 downto 0) := "10" & x"39";    
    
    constant LCD_A : std_logic_vector(9 downto 0) := "10" & x"41";
    constant LCD_B : std_logic_vector(9 downto 0) := "10" & x"42";
    constant LCD_C : std_logic_vector(9 downto 0) := "10" & x"43";
    constant LCD_D : std_logic_vector(9 downto 0) := "10" & x"44";
    constant LCD_E : std_logic_vector(9 downto 0) := "10" & x"45";
    constant LCD_F : std_logic_vector(9 downto 0) := "10" & x"46";
    constant LCD_G : std_logic_vector(9 downto 0) := "10" & x"47";
    constant LCD_H : std_logic_vector(9 downto 0) := "10" & x"48";
    constant LCD_I : std_logic_vector(9 downto 0) := "10" & x"49";
    constant LCD_J : std_logic_vector(9 downto 0) := "10" & x"4A";
    constant LCD_K : std_logic_vector(9 downto 0) := "10" & x"4B";
    constant LCD_L : std_logic_vector(9 downto 0) := "10" & x"4C";
    constant LCD_M : std_logic_vector(9 downto 0) := "10" & x"4D";
    constant LCD_N : std_logic_vector(9 downto 0) := "10" & x"4E";
    constant LCD_O : std_logic_vector(9 downto 0) := "10" & x"4F";
    constant LCD_P : std_logic_vector(9 downto 0) := "10" & x"50";
    constant LCD_Q : std_logic_vector(9 downto 0) := "10" & x"51";
    constant LCD_R : std_logic_vector(9 downto 0) := "10" & x"52";
    constant LCD_S : std_logic_vector(9 downto 0) := "10" & x"53";
    constant LCD_T : std_logic_vector(9 downto 0) := "10" & x"54";
    constant LCD_U : std_logic_vector(9 downto 0) := "10" & x"55";
    constant LCD_V : std_logic_vector(9 downto 0) := "10" & x"56";
    constant LCD_W : std_logic_vector(9 downto 0) := "10" & x"57";
    constant LCD_X : std_logic_vector(9 downto 0) := "10" & x"58";
    constant LCD_Y : std_logic_vector(9 downto 0) := "10" & x"59";
    constant LCD_Z : std_logic_vector(9 downto 0) := "10" & x"5A";
    
    constant dietemp_matrix     : send_array(6 downto 0) := (LCD_P,LCD_M,LCD_E,LCD_T,LCD_E,LCD_I,LCD_D); 
    constant vccint_matrix      : send_array(5 downto 0) := (LCD_T,LCD_N,LCD_I,LCD_C,LCD_C,LCD_V); 
    constant vccaux_matrix      : send_array(5 downto 0) := (LCD_X,LCD_U,LCD_A,LCD_C,LCD_C,LCD_V); 
    constant vccbram_matrix     : send_array(6 downto 0) := (LCD_M,LCD_A,LCD_R,LCD_B,LCD_C,LCD_C,LCD_V); 
    constant vsnsvu_matrix      : send_array(5 downto 0) := (LCD_U,LCD_V,LCD_S,LCD_N,LCD_S,LCD_V);
    constant vsns5v0_matrix     : send_array(6 downto 0) := (LCD_0,LCD_V,LCD_5,LCD_S,LCD_N,LCD_S,LCD_V);
    constant isns5v0_matrix     : send_array(6 downto 0) := (LCD_0,LCD_V,LCD_5,LCD_S,LCD_N,LCD_S,LCD_I);
    constant isns0v95_matrix    : send_array(7 downto 0) := (LCD_5,LCD_9,LCD_V,LCD_0,LCD_S,LCD_N,LCD_S,LCD_I);
    
    constant clear_display_cmd  : std_logic_vector(9 downto 0) := "00" & x"01";
    constant next_line_cmd      : std_logic_vector(9 downto 0) := "00" & x"C0";
    constant space_cmd          : std_logic_vector(9 downto 0) := "00" & x"14";
        
    constant S0_GPO : integer := 0;
    constant S1_GPO_CTRL : integer := 1;
    constant S2_GPI : integer := 2;
end package;

package body pkg is    
end package body;