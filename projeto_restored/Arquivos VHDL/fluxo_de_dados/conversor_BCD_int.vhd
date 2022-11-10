library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;


entity conversor_BCD_int is
    port (
        valor_BCD   : in  std_logic_vector(11 downto 0);
        valor_int   : out std_logic_vector( 9 downto 0)
    );
end entity;


architecture arch of conversor_BCD_int is

begin

    valor_int <= std_logic_vector(to_unsigned(
        to_integer(unsigned(valor_BCD(11 downto  8)))*100 + 
        to_integer(unsigned(valor_BCD( 7 downto  4)))*10 +
        to_integer(unsigned(valor_BCD( 3 downto  0)))
        , 10));

end arch;