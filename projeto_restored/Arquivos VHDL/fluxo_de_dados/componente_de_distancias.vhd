library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;


entity componente_de_distancias is
    port (
        clock   : in  std_logic;
        reset   : in  std_logic;
        echo    : in  std_logic;

        trigger             : out std_logic;
        fim_medida          : out std_logic;
        pronto              : out std_logic;
        distancia_anterior  : out std_logic_vector(15 downto 0);
        distancia_atual     : out std_logic_vector(15 downto 0);
        db_distancia_medida : out std_logic_vector(15 downto 0)
    );
end entity;


architecture arch of componente_de_distancias is

    component interface_hcsr04 is
        port (
            clock       : in std_logic;
            reset       : in std_logic;
            medir       : in std_logic;
            echo        : in std_logic;
    
            trigger     : out std_logic;
            medida      : out std_logic_vector(15 downto 0); 
            pronto      : out std_logic;
            db_estado   : out std_logic_vector(3 downto 0) 
        );
    end component;

    component componente_de_distancias_uc is 
        port (
            clock                   : in  std_logic;
            reset                   : in  std_logic;
            fim_medida              : in  std_logic;
            fim_contador_medida     : in  std_logic;
            fim_timer_1ms           : in  std_logic;
            fim_timer_distMax       : in  std_logic;
    
            zera                : out std_logic;
            zera_timer_distMax  : out std_logic;
            pulso_medir         : out std_logic;
            registra_medida     : out std_logic;
            registra_atual      : out std_logic;
            registra_anterior   : out std_logic;
            conta_1ms           : out std_logic;
            conta_medida        : out std_logic;
            pronto              : out std_logic
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

    component registrador_n is
        generic (
           constant N: integer := 8 
        );
        port (
           clock  : in  std_logic;
           clear  : in  std_logic;
           enable : in  std_logic;
           D      : in  std_logic_vector (N-1 downto 0);
           Q      : out std_logic_vector (N-1 downto 0) 
        );
    end component registrador_n;

    component comparador_de_distancias is
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
    end component comparador_de_distancias;


    signal  s_reset, s_zera, s_reset_sensor, s_zera_timer_distMax,      -- sinais de reset
            s_registra_medida, s_registra_anterior, s_registra_atual,   -- sinais de registro
            s_registra_1, s_registra_2, s_registra_3, s_registra_4,
            s_pulso_medir, s_conta_medida, s_conta_1ms,                 -- sinais de 
            s_fim_medida, s_fim_timer_1ms, s_fim_timer_distMax, s_fim_contador_medida, s_fim   -- sinais de fim
        : std_logic := '0';
    signal  s_contagem_atual 
        : std_logic_vector (1 downto 0);
    signal  s_distancia_medida, s_distancia_atual, s_distancia_anterior,
            s_dist1, s_dist2, s_dist3, s_dist4, s_distancia_aproximada     
        : std_logic_vector(15 downto 0);
    
    
begin
    
    s_reset <= reset or s_zera;
    s_reset_sensor <= reset or s_fim_timer_distMax;

    -- Sensor Ultrassônico de Distância
    SensorUltrassonico: interface_hcsr04
        port map(
            clock           => clock,
            reset           => s_reset_sensor,
            medir           => s_pulso_medir,   -- sempre realizará a medição 1ms após a prévia
            echo            => echo,
            trigger         => trigger,
            medida          => s_distancia_medida,
            pronto          => s_fim_medida,        -- pulso que indica o término
            db_estado       => open
        );

    -- Unidade de Controle
    UC: componente_de_distancias_uc
        port map (
            clock                   => clock,
            reset                   => reset,
            fim_medida              => s_fim_medida,
            fim_contador_medida     => s_fim_contador_medida,
            fim_timer_1ms           => s_fim_timer_1ms,
            fim_timer_distMax       => s_fim_timer_distMax,

            zera                => s_zera,
            zera_timer_distMax  => s_zera_timer_distMax,
            pulso_medir         => s_pulso_medir,
            registra_medida     => s_registra_medida,
            registra_atual      => s_registra_atual,
            registra_anterior   => s_registra_anterior,
            conta_1ms           => s_conta_1ms,
            conta_medida        => s_conta_medida,
            pronto              => pronto
        );

    -- timer usado para dar um intervalo entre cada realização de medida de distância
    Timer1ms: contador_m 
        generic map (  
            M => 50_000,  
            N => 20 
        )
        port map (
            clock => clock,
            zera  => s_fim_medida,
            conta => s_conta_1ms,
            Q     => open,
            fim   => s_fim_timer_1ms,
            meio  => open
        );

    -- timer de limite para espera do sinal do sonar (4m ~> 23ms)
    TimerDistMax: contador_m 
        generic map (  
            M => 147_050,    -- 147.050 * 20ns = 50cm * 58.82us/cm
            -- M => 1_250_000,  -- 1.250.000 * 20ns = 25ms (pouco mais de 4m)
            N => 21 
        )
        port map (
            clock => clock,
            zera  => s_zera_timer_distMax,
            conta => '1',
            Q     => open,
            fim   => s_fim_timer_distMax,
            meio  => open
        );

    -- contador do número de medições de distância que devem ser realizados
    ContadorMedida: contador_m 
        generic map (  
            M => 4, 
            N => 2 
        )
        port map (
            clock => clock,
            zera  => s_reset,
            conta => s_conta_medida,
            Q     => s_contagem_atual,
            fim   => s_fim_contador_medida,
            meio  => open
        );

    -- sinais para registrar em cada registrador (levam em consideração qual a contagem atual)
    s_registra_1 <= s_registra_medida and (not s_contagem_atual(1)) and (not s_contagem_atual(0)); -- contagem 00
    s_registra_2 <= s_registra_medida and (not s_contagem_atual(1)) and      s_contagem_atual(0) ; -- contagem 01
    s_registra_3 <= s_registra_medida and      s_contagem_atual(1)  and (not s_contagem_atual(0)); -- contagem 10
    s_registra_4 <= s_registra_medida and      s_contagem_atual(1)  and      s_contagem_atual(0) ; -- contagem 11
    -- registrador para a 1a medida de distância
    Distancia1: registrador_n
        generic map (
            N   => 16
        )
        port map (
            clock  => clock,
            clear  => s_reset,
            enable => s_registra_1,
            D      => s_distancia_medida,
            Q      => s_dist1
        );
    -- registrador para a 2a medida de distância
    Distancia2: registrador_n
        generic map (
            N   => 16
        )
        port map (
            clock  => clock,
            clear  => s_reset,
            enable => s_registra_2,
            D      => s_distancia_medida,
            Q      => s_dist2
        );
    -- registrador para a 3a medida de distância
    Distancia3: registrador_n
        generic map (
            N   => 16
        )
        port map (
            clock  => clock,
            clear  => s_reset,
            enable => s_registra_3,
            D      => s_distancia_medida,
            Q      => s_dist3
        );
    -- registrador para a 4a medida de distância
    Distancia4: registrador_n
        generic map (
            N   => 16
        )
        port map (
            clock  => clock,
            clear  => s_reset,
            enable => s_registra_4,
            D      => s_distancia_medida,
            Q      => s_dist4
        );


    -- compara 4 distâncias, devolvendo a média entre as menores do que DistMax_mm
    ComparadorDistancias: comparador_de_distancias
        generic map (
            DistMax_mm => 4000  -- para Modelsim (4m)
        )
        port map (
            dist1           => s_dist1,
            dist2           => s_dist2,
            dist3           => s_dist3,
            dist4           => s_dist4,
            resultado       => s_distancia_aproximada
        );

    -- Registrador com o valor da medida atual da distância (após correção/aproximação)
    DistanciaAtual: registrador_n
        generic map (
            N   => 16
        )
        port map (
            clock  => clock,
            clear  => reset,
            enable => s_registra_atual,
            D      => s_distancia_aproximada,
            Q      => s_distancia_atual
        );
    
    
    -- Registrador com o valor da medida anterior de distância (valor será usado no cálculo de velocidade)
    DistanciaAnterior: registrador_n
        generic map (
            N   => 16
        )
        port map (
            clock  => clock,
            clear  => reset,
            enable => s_registra_anterior,
            D      => s_distancia_atual,
            Q      => s_distancia_anterior
        );


    -- Saídas
    fim_medida          <= s_fim_medida;
    distancia_atual     <= s_distancia_atual;
    distancia_anterior  <= s_distancia_anterior;

    -- Depuracao
    db_distancia_medida <= s_distancia_medida;

end arch;