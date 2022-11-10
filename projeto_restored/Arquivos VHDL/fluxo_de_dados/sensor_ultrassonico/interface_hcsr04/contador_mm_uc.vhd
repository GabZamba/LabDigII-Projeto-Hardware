--------------------------------------------------------------------
-- Arquivo   : interface_hcsr04_uc.vhd
-- Projeto   : Experiencia 4 - Interface com sensor de distancia
--------------------------------------------------------------------
-- Descricao : unidade de controle do circuito de interface com
--             sensor de distancia
--             
--             implementa arredondamento da medida
--------------------------------------------------------------------
-- Revisoes  :
--     Data        Versao  Autor             Descricao
--     09/09/2021  1.0     Edson Midorikawa  versao inicial
--     03/09/2022  1.1     Edson Midorikawa  revisao
--------------------------------------------------------------------
--

library ieee;
use ieee.std_logic_1164.all;

entity contador_mm_uc is 
    port ( 
        clock       : in  std_logic;
        reset       : in  std_logic;
        pulso       : in  std_logic;

        zera        : out std_logic:= '0';
        conta       : out std_logic:= '0';
        pronto      : out std_logic:= '0'
    );
end contador_mm_uc;

architecture arch of contador_mm_uc is
    type tipo_estado is (parado, contagem, final);
    signal Eatual, Eprox: tipo_estado;
begin

    
    -- logica de estado e contagem
    process(clock,reset)
    begin
        if (reset='1') then
            Eatual <= parado;
        elsif (clock'event and clock='1') then
            Eatual <= Eprox;
        end if;
    end process;

    -- logica de proximo estado e contagem
    process(Eatual, pulso)
    begin
        case Eatual is
            when parado =>
                if pulso='1' then   Eprox <= contagem;
                else                Eprox <= parado;
                end if;

            when contagem =>
                if pulso='0' then   Eprox <= final;
                else                Eprox <= contagem;
                end if;

            when final =>           Eprox <= parado;
        end case;
    end process;

    with Eatual select 
        conta   <= '1' when contagem, '0' when others;

    with Eatual select 
        zera    <= '1' when parado, '0' when others;
        
    with Eatual select 
        pronto  <= '1' when final, '0' when others;

end architecture arch;
