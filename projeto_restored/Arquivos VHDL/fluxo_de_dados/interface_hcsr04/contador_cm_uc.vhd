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

entity contador_cm_uc is 
    port ( 
        clock       : in  std_logic;
        reset       : in  std_logic;
        pulso       : in  std_logic;

        zera        : out std_logic:= '0';
        conta       : out std_logic:= '0';
        pronto      : out std_logic:= '0'
    );
end contador_cm_uc;

architecture arch of contador_cm_uc is
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
                if pulso='1' then 
                    Eprox <= contagem;  -- migra para o estado de contagem
                    zera <= '1';        -- manda pulso para zerar contadores
                    pronto <= '0';
                else Eprox <= parado;
                end if;

            when contagem =>
                zera    <= '0';
                if pulso='0' then Eprox <= final;
                else Eprox <= contagem;
                end if;

            when final =>
                Eprox <= parado;
                pronto <= '1';
        end case;
    end process;

    with Eatual select 
        conta <= '1' when contagem, '0' when others;

end architecture arch;
