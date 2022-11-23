library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;


entity componente_do_servomotor is
    port (
        clock                   : in  std_logic;
        reset                   : in  std_logic;
        posicao_equilibrio      : in  std_logic_vector (9 downto 0);
        distancia_medida        : in  std_logic_vector (9 downto 0);
        p_externo               : in  std_logic_vector (9 downto 0);
        i_externo               : in  std_logic_vector (9 downto 0);
        d_externo               : in  std_logic_vector (9 downto 0);

        pwm_servo               : out std_logic;
        angulo_medido           : out std_logic_vector(23 downto 0);
        db_erro_atual           : out std_logic_vector (9 downto 0)
    );
end entity;


architecture arch of componente_do_servomotor is


    component controle_servo is
        port (
            clock             : in  std_logic;
            reset             : in  std_logic;
            posicao_servo     : in  std_logic_vector (9 downto 0);
            controle          : out std_logic
        );
    end component;

    component pid is
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
    end component;

    component rom_angulos_141x24 is
        port (
            endereco : in  std_logic_vector(9 downto 0);
            saida    : out std_logic_vector(23 downto 0)
        ); 
    end component;

    component contador_m is
        generic (
            constant M : integer := 50;  
            constant N : integer := 6 
        );
        port (
            clock : in  std_logic;
            zera  : in  std_logic;
            conta : in  std_logic;
            Q     : out std_logic_vector (N-1 downto 0);
            fim   : out std_logic;
            meio  : out std_logic
        );
    end component;


    signal  s_pulso_calcular
        : std_logic;
    signal  s_posicao_servo
        : std_logic_vector (9 downto 0);


begin

    CalculoPID: pid 
        port map (
            pulso_calcular      => s_pulso_calcular, -- Periodo de 10 ms
            reset               => reset,
            equilibrio          => posicao_equilibrio,
            distancia_medida    => distancia_medida, 
            p_externo           => p_externo,
            i_externo           => i_externo,
            d_externo           => d_externo,
            
            posicao_servo       => s_posicao_servo,
            db_erro_atual       => db_erro_atual
        );
    
    ControleServo: controle_servo 
        port map(
            clock             => clock,
            reset             => reset,
            posicao_servo     => s_posicao_servo,
            controle          => pwm_servo
        );

    RomAngulos: rom_angulos_141x24
        port map (
            endereco => s_posicao_servo,
            saida    => angulo_medido
        );

    -- timer de 100ms entre cada medição do pid
    Timer100ms: contador_m 
        generic map (
            M => 5_000_000,  -- 5.000.000 * 20ns = 100ms
            N => 23 
            -- M => 100,  
            -- N => 7 
        )
        port map (
            clock => clock,
            zera  => '0',
            conta => '1',
            Q     => open,
            fim   => s_pulso_calcular,
            meio  => open
        );

end arch;