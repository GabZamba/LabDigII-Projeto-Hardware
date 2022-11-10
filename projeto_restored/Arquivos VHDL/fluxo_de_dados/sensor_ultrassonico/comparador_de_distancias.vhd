library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity comparador_de_distancias is
    generic (
        constant DistMax_mm : integer := 500  
    );
    port (
        dist1           : in  std_logic_vector (15 downto 0);
        dist2           : in  std_logic_vector (15 downto 0);
        dist3           : in  std_logic_vector (15 downto 0);
        dist4           : in  std_logic_vector (15 downto 0);

        resultadoInt    : out std_logic_vector ( 9 downto 0);
        resultadoBCD    : out std_logic_vector (15 downto 0)
    );
end entity comparador_de_distancias;


architecture comportamental of comparador_de_distancias is

    component conversor_BCD_int is
        port (
            valor_BCD   : in  std_logic_vector(11 downto 0);
            valor_int   : out std_logic_vector( 9 downto 0)
        );
    end component;

    signal v1, v2, v3, v4, result
        : integer range 0 to DistMax_mm;
    signal d1, d2, d3, d4
        : std_logic_vector(9 downto 0);

begin

    -- Converte as medidas BCD para inteiro
    CD1: conversor_BCD_int
        port map (
            valor_BCD   => dist1(11 downto 0),
            valor_int   => d1
        );

    CD2: conversor_BCD_int
        port map (
            valor_BCD   => dist2(11 downto 0),
            valor_int   => d2
        );
    
    CD3: conversor_BCD_int
        port map (
            valor_BCD   => dist3(11 downto 0),
            valor_int   => d3
        );
    
    CD4: conversor_BCD_int
        port map (
            valor_BCD   => dist4(11 downto 0),
            valor_int   => d4
        );
    

    -- Se forem maiores do que a distância máxima, as anula
    v1 <= to_integer(unsigned(d1)) when to_integer(unsigned(d1)) <= DistMax_mm else 0;
    v2 <= to_integer(unsigned(d2)) when to_integer(unsigned(d2)) <= DistMax_mm else 0;
    v3 <= to_integer(unsigned(d3)) when to_integer(unsigned(d3)) <= DistMax_mm else 0;
    v4 <= to_integer(unsigned(d4)) when to_integer(unsigned(d4)) <= DistMax_mm else 0;

    -- Constrói o resultado da média
    process(v1, v2, v3, v4)
    begin

        -- todos os quatro não-nulos
        if v1/=0 and v2/=0 and v3/=0 and v4/=0 then result <= (v1 + v2 + v3 + v4)/4;
        -- um dos quatro nulos
        elsif   (v1/=0 and v2/=0 and v3/=0) or 
                (v1/=0 and v2/=0 and v4/=0) or 
                (v1/=0 and v3/=0 and v4/=0) or
                (v2/=0 and v3/=0 and v4/=0) then result <= (v1 + v2 + v3 + v4)/3;
        -- dois dos quatro nulos
        elsif   (v1/=0 and v2/=0) or 
                (v1/=0 and v3/=0) or 
                (v1/=0 and v4/=0) or 
                (v2/=0 and v3/=0) or 
                (v2/=0 and v4/=0) or 
                (v3/=0 and v4/=0) then result <= (v1 + v2 + v3 + v4)/2;
        -- três dos quatro nulos
        else result <= (v1 + v2 + v3 + v4);
        end if;

    end process;

    resultadoInt <= std_logic_vector(to_unsigned( result, 10));

    -- converte o resultado (inteiro) para BCD 4 Digitos
    resultadoBCD <= std_logic_vector(to_unsigned( result / 1000, 4)) &
                    std_logic_vector(to_unsigned( (result mod 1000) / 100, 4)) &
                    std_logic_vector(to_unsigned( (result mod 100) / 10, 4)) &
                    std_logic_vector(to_unsigned( (result mod 10), 4));

end architecture;