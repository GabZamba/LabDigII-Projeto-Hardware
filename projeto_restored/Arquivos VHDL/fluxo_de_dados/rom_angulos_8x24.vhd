-----------------Laboratorio Digital-------------------------------------
-- Arquivo   : rom_angulos_8x24.vhd
-- Projeto   : Experiencia 6 - Sistema de Sonar
-------------------------------------------------------------------------
-- Descricao : 
--             memoria rom 8x24 (descricao comportamental)
--             conteudo com 8 posicoes angulares predefinidos
-------------------------------------------------------------------------
-- Revisoes  :
--     Data        Versao  Autor             Descricao
--     20/09/2019  1.0     Edson Midorikawa  criacao
--     01/10/2020  1.1     Edson Midorikawa  revisao
--     09/10/2021  1.2     Edson Midorikawa  revisao
--     24/09/2022  1.3     Edson Midorikawa  revisao
-------------------------------------------------------------------------
--
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity rom_angulos_8x24 is
    port (
        endereco : in  std_logic_vector(2 downto 0);
        saida    : out std_logic_vector(23 downto 0)
    ); 
end entity;

architecture rom_arch of rom_angulos_8x24 is
    type memoria_8x24 is array (integer range 0 to 7) of std_logic_vector(23 downto 0);
    constant tabela_angulos: memoria_8x24 := (
        x"303230", --  0 = 020  -- conteudo da ROM
        x"303430", --  1 = 040  -- angulos para o sonar
        x"303630", --  2 = 060  -- (valores em hexadecimal)
        x"303830", --  3 = 080
        x"313030", --  4 = 100
        x"313230", --  5 = 120
        x"313430", --  6 = 140
        x"313630"  --  7 = 160
    );
begin

    saida <= tabela_angulos(to_integer(unsigned(endereco)));

end architecture rom_arch;
