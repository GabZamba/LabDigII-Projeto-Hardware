
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity controle_servo is
  port (
      clock             : in  std_logic;
      reset             : in  std_logic;
      posicao_servo     : in  std_logic_vector (2 downto 0);
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
      contagem_pwm    <= 0;
      controle         <= '0';
      posicao_controle <= s_posicao;
    elsif(rising_edge(clock)) then
        -- saida
        if(contagem_pwm < posicao_controle) then
          controle  <= '1';
        else
          controle  <= '0';
        end if;
        -- atualiza contagem e posicao
        if(contagem_pwm=CONTAGEM_MAXIMA_PWM-1) then
          contagem_pwm   <= 0;
          posicao_controle <= s_posicao;
        else
          contagem_pwm   <= contagem_pwm + 1;
        end if;
    end if;
  end process;

  process(posicao_servo)
  begin
    case posicao_servo is
      when "000" =>    s_posicao <=  50000;
      when "001" =>    s_posicao <=  57000; 
      when "010" =>    s_posicao <=  64000;
      when "011" =>    s_posicao <=  71000;
      when "100" =>    s_posicao <=  78000;
      when "101" =>    s_posicao <=  85000; 
      when "110" =>    s_posicao <=  92000;
      when "111" =>    s_posicao <= 100000;
      
      when others =>  s_posicao <=       0;  -- nulo   saida 0
    end case;
  end process;
  
  
end rtl;