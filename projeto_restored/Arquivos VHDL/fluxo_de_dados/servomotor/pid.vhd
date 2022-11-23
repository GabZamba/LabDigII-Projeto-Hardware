library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity pid is
    port (
        pulso_calcular      : in  std_logic; -- Periodo de 10 ms
        equilibrio          : in  std_logic_vector (9 downto 0);
        distancia_medida    : in  std_logic_vector (9 downto 0); 
        p_externo           : in  std_logic_vector (9 downto 0);
        i_externo           : in  std_logic_vector (9 downto 0);
        d_externo           : in  std_logic_vector (9 downto 0);
        
        posicao_servo       : out std_logic_vector (9 downto 0);
        db_erro_atual       : out std_logic_vector (9 downto 0)
    );
end pid;


architecture behavioral of pid is

    -- Utilizando valores inteiros para as constantes, para se obter o valor real, deve-se dividir por 100 os seus respectivos valores
    constant Kp                 : integer := 50; 
    constant Kd                 : integer := 0;
    constant Ki                 : integer := 0;

    signal saida_antiga         : integer := 512; -- servo motor em posição de equílibrio para a bolinha    
    signal erro_antigo          : integer := 0; 
    signal erro_acumulado       : integer := 0;     
    
begin


    process(pulso_calcular)
        variable p, i, d        : integer := 0; 
        variable erro_atual     : integer := 0; 
        variable saida_atual    : integer := 0;     
    
    begin    
    
        if pulso_calcular='1' then

            erro_acumulado  <= erro_acumulado + erro_antigo;

            erro_atual      := to_integer(unsigned(equilibrio)) - to_integer(unsigned(distancia_medida));

            db_erro_atual   <= std_logic_vector(to_unsigned( erro_atual, 10));

            p           := to_integer(unsigned(p_externo)) * erro_atual; 
            i           := to_integer(unsigned(i_externo)) * (erro_atual + erro_acumulado);
            d           := to_integer(unsigned(d_externo)) * (erro_atual - erro_antigo) / 100; -- dividindo pelo tempo que decorreu entre as amostras
            saida_atual :=  saida_antiga + (p + i + d) / 100; -- Obtendo os valores reais para Kp Kd e Ki 

            if saida_atual >= 1024    then saida_atual := 1023; end if;     
            if saida_atual < 0        then saida_atual := 0;    end if;

            posicao_servo <= std_logic_vector(to_unsigned( saida_atual, 10));
            erro_antigo     <= erro_atual;
            saida_antiga    <= saida_atual;

        end if;

    end process;

end behavioral;