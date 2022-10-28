------------------------------------------------------------------
-- Arquivo   : mux_4x1_n.vhd
-- Projeto   : Experiencia 5 - Trena Digital com Saida Serial
------------------------------------------------------------------
-- Descricao : multiplexador 4x1  
--             > parametro BITS: numero de bits das entradas
--
--             > adaptado a partir do codigo my_4t1_mux.vhd 
--             > do livro "Free Range VHDL" 
--
------------------------------------------------------------------
-- Revisoes  :
--     Data        Versao  Autor             Descricao
--     20/09/2019  1.0     Edson Midorikawa  versao inicial
--     31/08/2022  2.0     Edson Midorikawa  revisao do codigo
------------------------------------------------------------------
--
library ieee;
use ieee.std_logic_1164.all;

entity mux_4x1_n is
    generic (
        constant BITS: integer := 4
    );
    port( 
        D3      : in  std_logic_vector (BITS-1 downto 0);
        D2      : in  std_logic_vector (BITS-1 downto 0);
        D1      : in  std_logic_vector (BITS-1 downto 0);
        D0      : in  std_logic_vector (BITS-1 downto 0);
        SEL     : in  std_logic_vector (1 downto 0);
        MUX_OUT : out std_logic_vector (BITS-1 downto 0)
    );
end entity mux_4x1_n;

architecture arch_mux_4x1_n of mux_4x1_n is
begin

    MUX_OUT <= D3 when (SEL = "11") else
               D2 when (SEL = "10") else
               D1 when (SEL = "01") else
               D0 when (SEL = "00") else
               (others => '1');

end architecture arch_mux_4x1_n;
