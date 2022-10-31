-----------------Laboratorio Digital-------------------------------------
-- Arquivo   : rom_angulos_16x24.vhd
-- Projeto   : Experiencia 6 - Sistema de Sonar
-------------------------------------------------------------------------
-- Descricao : 
--             memoria rom 16x24 (descricao comportamental)
--             conteudo com 16 posicoes angulares predefinidos
-------------------------------------------------------------------------
-- Revisoes  :
--     Data        Versao  Autor             Descricao
--     20/09/2019  1.0     Edson Midorikawa  criacao
--     01/10/2020  1.1     Edson Midorikawa  revisao
--     09/10/2021  1.2     Edson Midorikawa  revisao
--     24/09/2022  1.3     Edson Midorikawa  revisao
--     31/10/2022  2.0     Gabriel Zambelli  refatoraçao
-------------------------------------------------------------------------
--
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity rom_angulos_16x24 is
    port (
        endereco : in  std_logic_vector(3 downto 0);
        saida    : out std_logic_vector(23 downto 0)
    ); 
end entity;


architecture rom_arch of rom_angulos_16x24 is

    type memoria_8x24 is array (integer range 0 to 15) of std_logic_vector(23 downto 0);

    constant tabela_angulos: memoria_8x24 := (
        x"303230", --   0 = 020  -- conteudo da ROM
        x"303239", --   1 = 029  -- angulos para o sonar
        x"303339", --   2 = 039  -- (valores em hexadecimal)
        x"303438", --   3 = 048
        x"313537", --   4 = 057
        x"313637", --   5 = 067
        x"313736", --   6 = 076
        x"313835", --   7 = 085
        x"303935", --   8 = 095
        x"313034", --   9 = 104
        x"313133", --  10 = 113
        x"313233", --  11 = 123
        x"313332", --  12 = 132
        x"313431", --  13 = 141
        x"313531", --  14 = 151
        x"313630"  --  15 = 160
    );

begin

    saida <= tabela_angulos(to_integer(unsigned(endereco)));

end architecture rom_arch;
