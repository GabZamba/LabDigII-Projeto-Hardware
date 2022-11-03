library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;


entity componente_do_servomotor is
    port (
        clock                   : in  std_logic;
        reset                   : in  std_logic;
        conta_posicao_servo     : in  std_logic;
        zera_posicao_servo      : in  std_logic;

        pwm_servo               : out std_logic;
        angulo_medido           : out std_logic_vector(11 downto 0)
    );
end entity;


architecture arch of componente_do_servomotor is

    component contadorg_updown_m is
        generic (
            constant M: integer := 50
        );
        port (
            clock  : in  std_logic;
            zera_as: in  std_logic;
            zera_s : in  std_logic;
            conta  : in  std_logic;
            Q      : out std_logic_vector (natural(ceil(log2(real(M))))-1 downto 0);
            inicio : out std_logic;
            fim    : out std_logic;
            meio   : out std_logic 
       );
    end component;
    
    component rom_angulos_16x24 is
        port (
            endereco : in  std_logic_vector(9 downto 0);
            saida    : out std_logic_vector(23 downto 0)
        ); 
    end component;

    component controle_servo is
        port (
            clock             : in  std_logic;
            reset             : in  std_logic;
            posicao_servo     : in  std_logic_vector (9 downto 0);
            controle          : out std_logic
        );
    end component;

    component pid_alternativo is
        port (
            pulso_calcular   : in  std_logic; -- Periodo de 10 ms
            equilibrio		 : in  std_logic_vector (9 downto 0);
            entrada_sensor   : in  std_logic_vector (9 downto 0); 
            posicao_servo      : out std_logic_vector (9 downto 0) 
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
    signal  s_contador_posicao, s_equilibrio, s_entrada_sensor, s_posicao_servo
        : std_logic_vector (9 downto 0);
    signal  s_rom_saida               
        : std_logic_vector(23 downto 0);
    
    
begin
    
    CalculoPID: pid_alternativo 
        port map (
            pulso_calcular  => s_pulso_calcular, -- Periodo de 10 ms
            equilibrio		=> s_equilibrio,
            entrada_sensor  => s_entrada_sensor, 
            posicao_servo   => s_posicao_servo 
        );

    ContadorUpDown: contadorg_updown_m
        generic map (
            M => 1024
        )
        port map (
            clock   => clock,
            zera_as => reset,
            zera_s  => zera_posicao_servo,
            conta   => conta_posicao_servo,
            Q       => s_contador_posicao,
            inicio  => open,
            fim     => open,
            meio    => open
       );
    
    ControleServo: controle_servo 
        port map(
            clock             => clock,
            reset             => reset,
            posicao_servo     => s_posicao_servo,
            controle          => pwm_servo
        );

    
    RomAngulos: rom_angulos_16x24
        port map (
            endereco => s_contador_posicao,
            saida    => s_rom_saida
        );

    
    -- timer de 10ms entre cada medição
    Timer10ms: contador_m 
        generic map (
            M => 500_000,  -- 500.000 * 20ns = 10ms
            N => 20 
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
    
    angulo_medido    <= s_rom_saida(19 downto 16) & s_rom_saida(11 downto 8) & s_rom_saida(3 downto 0);

end arch;