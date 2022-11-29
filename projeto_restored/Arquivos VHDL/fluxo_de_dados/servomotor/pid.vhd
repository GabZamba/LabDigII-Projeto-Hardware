library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity pid is
    port (
        pulso_calcular      : in  std_logic; -- Periodo de 10 ms
        reset               : in  std_logic;
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
    type tipo_estado is (
        estado1, estado2, 
        estado3, estado4, 
        estado5, estado6
    );
    signal Eatual           : tipo_estado;

    constant Kp : integer :=   6;
    constant Ki : integer :=   0;
    constant Kd : integer := 140;
    -- outros valores bons: 016,000,390# 017,000,365#

    signal erro_antigo      : integer := 0;
    signal erro_atual       : integer := 0;
    signal erro_acumulado   : integer := 0;
    signal p, i, d          : integer := 0;
    -- servo motor em posição de equílibrio para o carrinho
    signal saida_antiga     : integer := 512;
    signal saida_atual      : integer := 512;
    signal saida_proxima    : integer := 512;
    
    
begin

    process(pulso_calcular) 
    begin

        if reset = '1' then 
            erro_antigo     <= 0;
            erro_atual      <= 0;
            erro_acumulado  <= 0;
            saida_antiga    <= 512;
            saida_atual     <= 512;
            saida_proxima   <= 512;
        
        elsif pulso_calcular'event and pulso_calcular = '1' then
            if Eatual=estado1 then
                erro_acumulado  <= erro_acumulado + erro_antigo;
                erro_atual      <= to_integer(unsigned(distancia_medida)) - 20 - to_integer(unsigned(equilibrio));
                Eatual          <= estado2;
                
            elsif Eatual=estado2 then
                -- p               <= to_integer(unsigned(p_externo)) * erro_atual / 10; 
                -- i               <= to_integer(unsigned(i_externo)) * (erro_atual + erro_acumulado);
                -- d               <= to_integer(unsigned(d_externo)) * (erro_atual - erro_antigo) * 2;
                p               <= Kp * erro_atual / 10; 
                i               <= Ki * (erro_atual + erro_acumulado);
                d               <= Kd * (erro_atual - erro_antigo) * 2;
                Eatual          <= estado3;

            elsif Eatual=estado3 then    
                saida_proxima   <=  saida_antiga + (p + i + d) / 10;
                Eatual          <= estado4;

            elsif Eatual=estado4 then    
                if saida_proxima >= 1023    then saida_proxima <= 1023; end if;     
                if saida_proxima < 0        then saida_proxima <= 0;    end if;
                Eatual          <= estado5;

            elsif Eatual=estado5 then    
                saida_atual     <= (saida_antiga + saida_proxima)/2;
                Eatual          <= estado6;

            elsif Eatual=estado6 then    
                erro_antigo     <= erro_atual;
                saida_antiga    <= saida_atual;
                Eatual          <= estado1;
            end if;
        end if;

    end process;

    -- Saídas
    posicao_servo   <= std_logic_vector(to_unsigned(saida_atual, 10));
    db_erro_atual   <= std_logic_vector(to_unsigned( erro_atual, 10));

end behavioral;