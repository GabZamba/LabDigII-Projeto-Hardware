library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity controle_servo is
  port (
      clock             : in  std_logic;
      reset             : in  std_logic;
      posicao_servo     : in  std_logic_vector (9 downto 0);
      controle          : out std_logic
  );
end controle_servo;

architecture rtl of controle_servo is
  constant CONTAGEM_MAXIMA_PWM  : integer := 1000000;
  signal posicao_servo_int      : integer range 0 to 511;  
  signal contagem_pwm           : integer range 0 to CONTAGEM_MAXIMA_PWM-1;
  signal posicao_controle       : integer range 0 to CONTAGEM_MAXIMA_PWM-1;
  signal s_posicao              : integer range 0 to CONTAGEM_MAXIMA_PWM-1;
  
begin
  posicao_servo_int <= to_integer(unsigned(posicao_servo));

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
    s_posicao <= 50000 + (50000*posicao_servo_int)/512;
  end process;
  
  
end rtl;