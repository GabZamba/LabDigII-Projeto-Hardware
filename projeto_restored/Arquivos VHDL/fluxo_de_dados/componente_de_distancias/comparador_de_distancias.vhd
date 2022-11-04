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
        resultado       : out std_logic_vector (15 downto 0)
    );
end entity comparador_de_distancias;


architecture comportamental of comparador_de_distancias is

    signal v1, v2, v3, v4
        : integer range 0 to DistMax_mm;
    signal d1, d2, d3, d4, result
        : integer range 0 to 9999; -- para os 16 digitos da distancia (2^16)

begin

    -- Converte as medidas BCD para inteiro
    d1 <=   to_integer(unsigned(dist1(15 downto 12)))*1000 + 
            to_integer(unsigned(dist1(11 downto 8)))*100 + 
            to_integer(unsigned(dist1(7 downto 4)))*10 +
            to_integer(unsigned(dist1(3 downto 0)));
    d2 <=   to_integer(unsigned(dist2(15 downto 12)))*1000 + 
            to_integer(unsigned(dist2(11 downto 8)))*100 + 
            to_integer(unsigned(dist2(7 downto 4)))*10 +
            to_integer(unsigned(dist2(3 downto 0)));
    d3 <=   to_integer(unsigned(dist3(15 downto 12)))*1000 + 
            to_integer(unsigned(dist3(11 downto 8)))*100 + 
            to_integer(unsigned(dist3(7 downto 4)))*10 +
            to_integer(unsigned(dist3(3 downto 0)));
    d4 <=   to_integer(unsigned(dist4(15 downto 12)))*1000 + 
            to_integer(unsigned(dist4(11 downto 8)))*100 + 
            to_integer(unsigned(dist4(7 downto 4)))*10 +
            to_integer(unsigned(dist4(3 downto 0)));

    -- Se forem maiores do que a distância máxima, as anula
    v1 <= d1 when d1 <= DistMax_mm else 0;
    v2 <= d2 when d2 <= DistMax_mm else 0;
    v3 <= d3 when d3 <= DistMax_mm else 0;
    v4 <= d4 when d4 <= DistMax_mm else 0;

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

    -- converte o resultado (inteiro) para BCD 4 Digitos
    resultado <=    std_logic_vector(to_unsigned( result / 1000, 4)) &
                    std_logic_vector(to_unsigned( (result mod 1000) / 100, 4)) &
                    std_logic_vector(to_unsigned( (result mod 100) / 10, 4)) &
                    std_logic_vector(to_unsigned( (result mod 10), 4));

end architecture;