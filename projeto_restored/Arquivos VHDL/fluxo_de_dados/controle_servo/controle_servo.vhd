library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity controle_servo is
    port (
        clock             : in  std_logic;
        reset             : in  std_logic;
        posicao_servo     : in  std_logic_vector (3 downto 0);
        controle          : out std_logic
    );
end controle_servo;

architecture rtl of controle_servo is
    constant CONTAGEM_MAXIMA_PWM  : integer := 1000000;  
    signal contagem_pwm           : integer range 0 to CONTAGEM_MAXIMA_PWM-1;
    signal posicao_controle       : integer range 0 to CONTAGEM_MAXIMA_PWM-1;
    signal s_posicao              : integer range 0 to CONTAGEM_MAXIMA_PWM-1;
  
begin

    process(clock,reset,s_posicao)
    begin

        -- inicia contagem e posicao
        if(reset='1') then
        contagem_pwm        <= 0;
        controle            <= '0';
        posicao_controle    <= s_posicao;
        elsif(rising_edge(clock)) then
            -- saida
            if(contagem_pwm < posicao_controle) then    
                controle  <= '1';
            else
                controle  <= '0';
            end if;
            -- atualiza contagem e posicao
            if(contagem_pwm=CONTAGEM_MAXIMA_PWM-1) then
                contagem_pwm        <= 0;
                posicao_controle    <= s_posicao;
            else
                contagem_pwm    <= contagem_pwm + 1;
            end if;
        end if;

    end process;

    process(posicao_servo)
    begin

        case posicao_servo is
            when "0000" =>  s_posicao <=  50000;
            when "0001" =>  s_posicao <=  53333; 
            when "0010" =>  s_posicao <=  56666;
            when "0011" =>  s_posicao <=  60000;
            when "0100" =>  s_posicao <=  63333;
            when "0101" =>  s_posicao <=  66666; 
            when "0110" =>  s_posicao <=  70000;
            when "0111" =>  s_posicao <=  73333;
            when "1000" =>  s_posicao <=  76666;
            when "1001" =>  s_posicao <=  80000; 
            when "1010" =>  s_posicao <=  83333;
            when "1011" =>  s_posicao <=  86666;
            when "1100" =>  s_posicao <=  90000;
            when "1101" =>  s_posicao <=  93333; 
            when "1110" =>  s_posicao <=  96666;
            when "1111" =>  s_posicao <= 100000;
            when others =>  s_posicao <=      0;  -- nulo   saida 0
        end case;

    end process;
  
  
end rtl;