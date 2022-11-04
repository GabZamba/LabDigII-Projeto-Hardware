library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;


entity projeto_fd is
    port (
        clock                   : in  std_logic;
        reset                   : in  std_logic;
        conta_posicao_servo_x   : in  std_logic;
        conta_posicao_servo_y   : in  std_logic;
        zera_posicao_servo_x    : in  std_logic;
        zera_posicao_servo_y    : in  std_logic;
        conta_tx                : in  std_logic;
        zera_contador_tx        : in  std_logic;
        distancia_medir         : in  std_logic;    -- não mais usado
        cubo_select             : in  std_logic;
        echo_cubo               : in  std_logic;
        echo_bola_x             : in  std_logic;
        echo_bola_y             : in  std_logic;
        tx_partida              : in  std_logic;
        timer_zera              : in  std_logic;
        entrada_serial          : in  std_logic;

        fim_contador_tx         : out std_logic;
        trigger_cubo            : out std_logic;
        trigger_bola_x          : out std_logic;
        trigger_bola_y          : out std_logic;
        fim_medida_cubo         : out std_logic;
        fim_medida_bola_x       : out std_logic;
        fim_medida_bola_y       : out std_logic;
        pwm_servo_x             : out std_logic;
        pwm_servo_y             : out std_logic;
        saida_serial            : out std_logic;
        tx_pronto               : out std_logic;
        fim_timer_2s            : out std_logic;

        db_angulo_medido_x      : out std_logic_vector(11 downto 0);
        db_angulo_medido_y      : out std_logic_vector(11 downto 0);
        db_distancia_medida_x   : out std_logic_vector(15 downto 0);
        db_distancia_medida_y   : out std_logic_vector(15 downto 0)
    );
end entity;


architecture arch of projeto_fd is

    component componente_de_distancias is
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
    end component;

    component componente_do_servomotor is
        port (
            clock                   : in  std_logic;
            reset                   : in  std_logic;
            conta_posicao_servo     : in  std_logic;
            zera_posicao_servo      : in  std_logic;
            posicao_equilibrio      : in  std_logic_vector (9 downto 0);
            distancia_medida        : in  std_logic_vector (9 downto 0);
    
            pwm_servo               : out std_logic;
            angulo_medido           : out std_logic_vector(23 downto 0)
        );
    end component;

    component receptor_cubo_virtual is
        port (
            clock       : in  std_logic;
            reset       : in  std_logic;
            dado_serial : in  std_logic;
    
            pronto                  : out std_logic;
            distancia_cubo_virtual  : out std_logic_vector(15 downto 0)
        );
    end component;

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

    component tx_serial_7E2 is
        port (
            clock         : in  std_logic;
            reset         : in  std_logic;
            partida       : in  std_logic;
            dados_ascii   : in  std_logic_vector (6 downto 0);
            saida_serial  : out std_logic;
            tick          : out std_logic;
            contador_bits : out std_logic_vector (3 downto 0);
            pronto        : out std_logic
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

    component mux_8x1_n is
        generic (
            constant BITS: integer := 4
        );
        port ( 
            D0      : in  std_logic_vector (BITS-1 downto 0);
            D1      : in  std_logic_vector (BITS-1 downto 0);
            D2      : in  std_logic_vector (BITS-1 downto 0);
            D3      : in  std_logic_vector (BITS-1 downto 0);
            D4      : in  std_logic_vector (BITS-1 downto 0);
            D5      : in  std_logic_vector (BITS-1 downto 0);
            D6      : in  std_logic_vector (BITS-1 downto 0);
            D7      : in  std_logic_vector (BITS-1 downto 0);
            SEL     : in  std_logic_vector (2 downto 0);
            MUX_OUT : out std_logic_vector (BITS-1 downto 0)
        );
    end component;

    signal  s_fim_tx
        : std_logic;
    signal  s_contagem_tx 
        : std_logic_vector (0 downto 0);
    signal  s_contagem_mux_tx 
        : std_logic_vector (2 downto 0);
    signal  s_contador_posicao_saida, s_contador_posicao_x, s_contador_posicao_y
        : std_logic_vector (9 downto 0);
    signal  s_saida_mux_x, s_saida_mux_y, s_dados_ascii            
        : std_logic_vector (6 downto 0);
    signal  s_distancia_atual_x, s_distancia_atual_y, s_distancia_cubo_real, s_distancia_cubo_virtual, s_distancia_cubo           
        : std_logic_vector(15 downto 0);
    signal  s_ascii_distancia_atual_x, s_ascii_distancia_atual_y
        : std_logic_vector(20 downto 0);
    signal  s_ascii_angulo_servo_x, s_ascii_angulo_servo_y
        : std_logic_vector(23 downto 0);
    
    
begin

    MedidorDistanciaCubo: componente_de_distancias 
        port map(
            clock           => clock,
            reset           => reset,
            echo            => echo_cubo,

            trigger             => trigger_cubo,
            fim_medida          => open,
            pronto              => fim_medida_cubo,
            distancia_anterior  => open,
            distancia_atual     => s_distancia_cubo_real,
            db_distancia_medida => open
        );

    MedidorDistanciaX: componente_de_distancias 
        port map(
            clock           => clock,
            reset           => reset,
            echo            => echo_bola_x,

            trigger             => trigger_bola_x,
            fim_medida          => fim_medida_bola_x,
            pronto              => open,
            distancia_anterior  => open,
            distancia_atual     => s_distancia_atual_x,
            db_distancia_medida => db_distancia_medida_x
        );

    MedidorDistanciaY: componente_de_distancias 
        port map(
            clock           => clock,
            reset           => reset,
            echo            => echo_bola_y,

            trigger             => trigger_bola_y,
            fim_medida          => fim_medida_bola_y,
            pronto              => open,
            distancia_anterior  => open,
            distancia_atual     => s_distancia_atual_y,
            db_distancia_medida => db_distancia_medida_y
        );

    -- Servomotor Distancia X
    ServomotorX: componente_do_servomotor 
        port map (
            clock                   => clock,
            reset                   => reset,
            conta_posicao_servo     => conta_posicao_servo_x,
            zera_posicao_servo      => zera_posicao_servo_x,
            posicao_equilibrio      => s_distancia_cubo(9 downto 0),
            distancia_medida        => s_distancia_atual_x(9 downto 0),
    
            pwm_servo               => pwm_servo_x,
            angulo_medido           => s_ascii_angulo_servo_x
        );

    -- Servomotor Distancia Y
    ServomotorY: componente_do_servomotor 
        port map (
            clock                   => clock,
            reset                   => reset,
            conta_posicao_servo     => conta_posicao_servo_y,
            zera_posicao_servo      => zera_posicao_servo_y,
            posicao_equilibrio      => s_distancia_cubo(9 downto 0),
            distancia_medida        => s_distancia_atual_y(9 downto 0),
    
            pwm_servo               => pwm_servo_y,
            angulo_medido           => s_ascii_angulo_servo_y
        );

    -- timer de 2s entre cada medição
    Timer2Seg: contador_m 
        generic map (
            M => 100000000,  
            N => 20 
            -- M => 100,  
            -- N => 7 
        )
        port map (
            clock => clock,
            zera  => timer_zera,
            conta => '1',
            Q     => open,
            fim   => fim_timer_2s,
            meio  => open
        );

    ContadorMuxTx: contador_m 
        generic map (
            M => 8,  
            N => 3 
        )
        port map (
            clock => clock,
            zera  => conta_tx,
            conta => s_fim_tx,
            Q     => s_contagem_mux_tx,
            fim   => tx_pronto,
            meio  => open
        );
    
    ContadorTxTotal: contador_m 
        generic map (
            M => 2,  
            N => 1 
        )
        port map (
            clock => clock,
            zera  => zera_contador_tx,
            conta => conta_tx,
            Q     => s_contagem_tx,
            fim   => fim_contador_tx,
            meio  => open
        );
    


    -- Converter digitos para ascii
    s_ascii_distancia_atual_x( 6 downto  0) <= "011" & s_distancia_atual_x( 3 downto 0);   
    s_ascii_distancia_atual_x(13 downto  7) <= "011" & s_distancia_atual_x( 7 downto 4);
    s_ascii_distancia_atual_x(20 downto 14) <= "011" & s_distancia_atual_x(11 downto 8);

    s_ascii_distancia_atual_y( 6 downto  0) <= "011" & s_distancia_atual_y( 3 downto 0);   
    s_ascii_distancia_atual_y(13 downto  7) <= "011" & s_distancia_atual_y( 7 downto 4);
    s_ascii_distancia_atual_y(20 downto 14) <= "011" & s_distancia_atual_y(11 downto 8);

    -- Multiplexadores para Transmissão Serial

    MuxTxDistanciaX: mux_8x1_n 
        generic map(
            BITS    => 7 
        )
        port map( 
            D0      => s_ascii_angulo_servo_x(22 downto 16),
            D1      => s_ascii_angulo_servo_x(14 downto  8),
            D2      => s_ascii_angulo_servo_x( 6 downto  0),
            D3      => "0101100",
            D4      => s_ascii_distancia_atual_x(20 downto 14),
            D5      => s_ascii_distancia_atual_x(13 downto  7),
            D6      => s_ascii_distancia_atual_x( 6 downto  0),
            D7      => "0100011",
            SEL     => s_contagem_mux_tx,
            MUX_OUT => s_saida_mux_x
        );

    MuxTxDistanciaY: mux_8x1_n 
        generic map(
            BITS    => 7 
        )
        port map( 
            D0      => s_ascii_angulo_servo_y(22 downto 16),
            D1      => s_ascii_angulo_servo_y(14 downto  8),
            D2      => s_ascii_angulo_servo_y( 6 downto  0),
            D3      => "0101100",
            D4      => s_ascii_distancia_atual_y(20 downto 14),
            D5      => s_ascii_distancia_atual_y(13 downto  7),
            D6      => s_ascii_distancia_atual_y( 6 downto  0),
            D7      => "0100011",
            SEL     => s_contagem_mux_tx,
            MUX_OUT => s_saida_mux_y
        );
    
    with s_contagem_tx select
        s_dados_ascii <= 
            s_saida_mux_y when "1",
            s_saida_mux_x when others;
    
    
    TransmissorSerial: tx_serial_7E2 
        port map (
            clock         => clock,
            reset         => reset, 
            partida       => tx_partida,
            dados_ascii   => s_dados_ascii,
            saida_serial  => saida_serial,
            tick          => open,
            contador_bits => open,
            pronto        => s_fim_tx
        );


    ReceptorCuboVirtual: receptor_cubo_virtual 
        port map(
            clock           => clock,
            reset           => reset,
            dado_serial     => entrada_serial,

            distancia_cubo_virtual  => s_distancia_cubo_virtual,
            pronto                  => open
        );

    with cubo_select select
        s_distancia_cubo <=
            s_distancia_cubo_virtual when '1',
            s_distancia_cubo_real when '0';

    -- Depuração
    db_angulo_medido_x  <= s_ascii_angulo_servo_x(19 downto 16) & s_ascii_angulo_servo_x(11 downto 8) & s_ascii_angulo_servo_x(3 downto 0);
    db_angulo_medido_y  <= s_ascii_angulo_servo_y(19 downto 16) & s_ascii_angulo_servo_y(11 downto 8) & s_ascii_angulo_servo_y(3 downto 0);

end arch;