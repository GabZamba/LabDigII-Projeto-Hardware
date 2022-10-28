-----------------Laboratorio Digital-------------------------------------
-- Arquivo   : contadorg_updown_m.vhd
-- Projeto   : Experiencia 6 - Sistema de Sonar
-------------------------------------------------------------------------
-- Descricao : contador vai e volta (updown) modulo m, 
--             com parametro M generic
--             sinais para clear assincrono (zera_as) e sincrono (zera_s)
--             e saidas de inicio, fim e meio de contagem
-- 
--             calculo do numero de bits do contador em funcao do modulo:
--             N = natural(ceil(log2(real(M))))
--
-- baseado no componente contador_m
-------------------------------------------------------------------------
-- Revisoes  :
--     Data        Versao  Autor             Descricao
--     09/09/2021  1.0     Edson Midorikawa  criacao
--     24/09/2022  1.1     Edson Midorikawa  revisao
-------------------------------------------------------------------------
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity contadorg_updown_m is
    generic (
        constant M: integer := 50 -- modulo do contador
    );
    port (
        clock  : in  std_logic;
        zera_as: in  std_logic;
        zera_s : in  std_logic;
        conta  : in  std_logic;
        Q      : out std_logic_vector (natural(ceil(log2(real(M))))-1 downto 0);
        inicio : out std_logic;
        fim    : out std_logic;
        meio   : out std_logic 
   );
end entity;

architecture comportamental of contadorg_updown_m is
    signal IQ  : integer range 0 to M-1;
    signal dir : bit;
begin
  
    process (clock,zera_as,zera_s,conta,IQ)
    begin
        if zera_as='1' then IQ <= 0;   
        elsif rising_edge(clock) then
            if zera_s='1' then IQ <= 0;
            elsif conta='1' then 

                if dir = '0' then 
                    if IQ=M-1 then IQ <= M-2; dir <= '1';
                    else           IQ <= IQ + 1; 
                    end if;
                else
                    if IQ=0 then IQ <= 1;  dir <= '0';
                    else         IQ <= IQ - 1;
                    end if;
                end if;

            else IQ <= IQ;
            end if;
        end if;

        -- inicio de contagem    
        if IQ=0 then inicio <= '1'; 
        else         inicio <= '0'; 
        end if;

        -- fim de contagem    
        if IQ=M-1 then fim <= '1'; 
        else           fim <= '0'; 
        end if;

        -- meio da contagem
        if IQ=M/2-1 then meio <= '1'; 
        else             meio <= '0'; 
        end if;

        Q <= std_logic_vector(to_unsigned(IQ, Q'length));

    end process;

end architecture comportamental;
