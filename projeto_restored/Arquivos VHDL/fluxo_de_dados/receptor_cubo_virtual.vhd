library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;


entity receptor_cubo_virtual is
    port (
        clock       : in  std_logic;
        reset       : in  std_logic;
        dado_serial : in  std_logic;

        pronto                  : out std_logic;
        distancia_cubo_virtual  : out std_logic_vector(15 downto 0)
    );
end entity;


architecture arch of receptor_cubo_virtual is

    component rx_serial_7E2 is
        port (
            clock               : in std_logic;
            reset               : in std_logic;
            dado_serial         : in std_logic;

            dados_ascii         : out std_logic_vector(6 downto 0);
            paridade_recebida   : out std_logic;
            tem_dado            : out std_logic;
            paridade_ok         : out std_logic;
            pronto_rx           : out std_logic;
            db_estado           : out std_logic_vector(6 downto 0)
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

    signal  s_puldo_dado_recebido, s_fim_contador_rx,
            s_registra_1, s_registra_2, s_registra_3,
            s_registra_distancia_final
        : std_logic;
    signal  s_contagem_rx
        : std_logic_vector (1 downto 0);
    signal  s_valor_rx, s_dist1_cubo, s_dist2_cubo, s_dist3_cubo
        : std_logic_vector (3 downto 0);
    signal  s_dado_ascii
        : std_logic_vector (6 downto 0);
    signal  s_distancia_recebida, s_distancia_cubo_virtual
        : std_logic_vector (11 downto 0);

begin

    ReceptorSerial: rx_serial_7E2
        port map (
            clock               => clock,
            reset               => reset,
            dado_serial         => dado_serial,
    
            dados_ascii         => s_dado_ascii,
            paridade_recebida   => open,
            tem_dado            => open,
            paridade_ok         => open,
            pronto_rx           => s_puldo_dado_recebido,
            db_estado           => open
        );

    -- conta o número de caracteres recebidos serialmente
    ContadorRx: contador_m 
        generic map (
            M   => 4,   -- 3 caracteres para a distancia em BCD (0400, primeiro digito é sempre 0, não precisa transmitir), 1 para #  
            N   => 2 
        )
        port map (
            clock   => clock,
            zera    => reset,
            conta   => s_puldo_dado_recebido,
            Q       => s_contagem_rx,
            fim     => s_fim_contador_rx,
            meio    => open
        );

    -- sinais para registrar em cada registrador, levando em consideração qual a contagem atual
    s_registra_1 <= s_puldo_dado_recebido and (not s_contagem_rx(1)) and (not s_contagem_rx(0)); -- contagem 00
    s_registra_2 <= s_puldo_dado_recebido and (not s_contagem_rx(1)) and      s_contagem_rx(0) ; -- contagem 01
    s_registra_3 <= s_puldo_dado_recebido and      s_contagem_rx(1)  and (not s_contagem_rx(0)); -- contagem 10

    s_valor_rx <= s_dado_ascii(3 downto 0);
    -- registrador para a 1o caractere da distância virtual
    DistanciaVirtual1: registrador_n
        generic map (
            N   => 4
        )
        port map (
            clock  => clock,
            clear  => reset,
            enable => s_registra_1,
            D      => s_valor_rx,
            Q      => s_dist1_cubo
        );
    -- registrador para a 2o caractere da distância virtual
    DistanciaVirtual2: registrador_n
        generic map (
            N   => 4
        )
        port map (
            clock  => clock,
            clear  => reset,
            enable => s_registra_2,
            D      => s_valor_rx,
            Q      => s_dist2_cubo
        );
    -- registrador para a 3o caractere da distância virtual
    DistanciaVirtual3: registrador_n
        generic map (
            N   => 4
        )
        port map (
            clock  => clock,
            clear  => reset,
            enable => s_registra_3,
            D      => s_valor_rx,
            Q      => s_dist3_cubo
        );

    -- registrador para a distancia virtual completa
    s_registra_distancia_final <= s_puldo_dado_recebido and s_fim_contador_rx; -- pulso assim que ultimo caractere é recebido

    s_distancia_recebida <= s_dist1_cubo & s_dist2_cubo & s_dist3_cubo;

    DistanciaCuboVirtual: registrador_n
        generic map (
            N   => 12
        )
        port map (
            clock  => clock,
            clear  => reset,
            enable => s_registra_distancia_final,
            D      => s_distancia_recebida,
            Q      => s_distancia_cubo_virtual
        );

    -- Saídas
    distancia_cubo_virtual  <= "0000" & s_distancia_cubo_virtual;
    pronto <= s_registra_distancia_final;


end arch;