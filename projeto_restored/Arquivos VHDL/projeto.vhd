library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity projeto is
    port (
        clock               : in  std_logic;
        reset               : in  std_logic;
        ligar               : in  std_logic;
        echo_cubo           : in  std_logic;
        echo_bola_x         : in  std_logic;
        echo_bola_y         : in  std_logic;
        entrada_serial      : in  std_logic;
        display_select      : in  std_logic_vector(1 downto 0);

        trigger_cubo        : out std_logic;
        trigger_bola_x      : out std_logic;
        trigger_bola_y      : out std_logic;
        pwm_servo_x         : out std_logic;
        pwm_servo_y         : out std_logic;
        saida_serial        : out std_logic;
        fim_posicao         : out std_logic;

        db_display_select   : out std_logic_vector(1 downto 0);
        db_7seg_0           : out std_logic_vector(6 downto 0);
        db_7seg_1           : out std_logic_vector(6 downto 0);
        db_7seg_2           : out std_logic_vector(6 downto 0);
        db_7seg_3           : out std_logic_vector(6 downto 0);
        db_estado           : out std_logic_vector(6 downto 0) 
    );
end entity projeto;


architecture arch of projeto is

    component projeto_uc is 
        port ( 
            clock               : in  std_logic;
            reset               : in  std_logic;
            ligar               : in  std_logic;
            fim_contador_tx     : in  std_logic;
            fim_medida_bola_x   : in  std_logic;
            tx_pronto           : in  std_logic;
            fim_timer_2s        : in  std_logic;
    
            conta_posicao_servo : out std_logic;
            zera_posicao_servo  : out std_logic;
            conta_tx            : out std_logic;
            zera_contador_tx    : out std_logic;
            distancia_medir     : out std_logic;
            tx_partida          : out std_logic;
            timer_zera          : out std_logic;
    
            db_estado           : out std_logic_vector(3 downto 0) 
        );
    end component;

    component projeto_fd is
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
    end component;

    component mux_4x1_n is
        generic (
            constant BITS: integer := 4
        );
        port( 
            D3      : in  std_logic_vector (BITS-1 downto 0);
            D2      : in  std_logic_vector (BITS-1 downto 0);
            D1      : in  std_logic_vector (BITS-1 downto 0);
            D0      : in  std_logic_vector (BITS-1 downto 0);
            SEL     : in  std_logic_vector (1 downto 0);
            MUX_OUT : out std_logic_vector (BITS-1 downto 0)
        );
    end component;

    component hex7seg is
        port (
            hexa : in  std_logic_vector(3 downto 0);
            sseg : out std_logic_vector(6 downto 0)
        );
    end component;


    signal  s_reset, s_fim_contador_tx, s_fim_medida_bola_x, s_tx_pronto,
            s_fim_timer_2s, s_conta_posicao_servo, s_zera_posicao_servo, 
            s_conta_tx, s_zera_contador_tx, s_distancia_medir,
            s_tx_partida, s_timer_zera
        : std_logic; 
    signal  s_db_estado                  
        : std_logic_vector(3 downto 0);
    signal  s_db_angulo_medido_x, s_db_angulo_medido_y           
        : std_logic_vector(11 downto 0);
    signal  s_db_distancia_medida_x, s_db_distancia_medida_y,
            s_db_angulo_x, s_db_angulo_y, s_saida_seletor_display
        : std_logic_vector(15 downto 0);


begin

    s_reset <= not reset; 

    UC: projeto_uc 
		port map (
            clock                   => clock,
            reset                   => s_reset,
            ligar                   => ligar,
            fim_contador_tx         => s_fim_contador_tx,
            fim_medida_bola_x       => s_fim_medida_bola_x,
            tx_pronto               => s_tx_pronto,
            fim_timer_2s            => s_fim_timer_2s,

            conta_posicao_servo     => s_conta_posicao_servo,
            zera_posicao_servo      => s_zera_posicao_servo,
            conta_tx                => s_conta_tx,
            zera_contador_tx        => s_zera_contador_tx,
            distancia_medir         => s_distancia_medir,
            tx_partida              => s_tx_partida,
            timer_zera              => s_timer_zera,

            db_estado               => s_db_estado
		);

    FD: projeto_fd 
		port map (
            clock                   => clock,
            reset                   => s_reset,
            conta_posicao_servo_x   => s_conta_posicao_servo,
            conta_posicao_servo_y   => s_conta_posicao_servo,
            zera_posicao_servo_x    => s_zera_posicao_servo,
            zera_posicao_servo_y    => s_zera_posicao_servo,
            conta_tx                => s_conta_tx,
            zera_contador_tx        => s_zera_contador_tx,
            distancia_medir         => s_distancia_medir,   -- não mais usado
            echo_cubo               => echo_cubo,
            echo_bola_x             => echo_bola_x,
            echo_bola_y             => echo_bola_y,
            tx_partida              => s_tx_partida,
            timer_zera              => s_timer_zera,
            entrada_serial          => entrada_serial,
    
            fim_contador_tx         => s_fim_contador_tx,
            trigger_cubo            => trigger_cubo,
            trigger_bola_x          => trigger_bola_x,
            trigger_bola_y          => trigger_bola_y,
            fim_medida_cubo         => open,
            fim_medida_bola_x       => s_fim_medida_bola_x,
            fim_medida_bola_y       => open,
            pwm_servo_x             => pwm_servo_x,
            pwm_servo_y             => pwm_servo_y,
            saida_serial            => saida_serial,
            tx_pronto               => s_tx_pronto,
            fim_timer_2s            => s_fim_timer_2s,
    
            db_angulo_medido_x      => s_db_angulo_medido_x,
            db_angulo_medido_y      => s_db_angulo_medido_y,
            db_distancia_medida_x   => s_db_distancia_medida_x,
            db_distancia_medida_y   => s_db_distancia_medida_y
            
		);

    -- Multiplexador para Displays de 7 Segmentos
    s_db_angulo_x   <= "0000" & s_db_angulo_medido_x;
    s_db_angulo_y   <= "0000" & s_db_angulo_medido_y;
    Multiplexador7Seg: mux_4x1_n
        generic map (
            BITS    => 16
        )
        port map ( 
            D3      => s_db_angulo_y,
            D2      => s_db_distancia_medida_y,
            D1      => s_db_angulo_x,
            D0      => s_db_distancia_medida_x,
            SEL     => display_select,
            MUX_OUT => s_saida_seletor_display
        );
        
    -- Conversores Displays de 7 Segmentos
    Display7SegDigito0: hex7seg
        port map (
            hexa    => s_saida_seletor_display(3 downto 0),
            sseg    => db_7seg_0
        );
    Display7SegDigito1: hex7seg
        port map (
            hexa    => s_saida_seletor_display(7 downto 4),
            sseg    => db_7seg_1
        );
    Display7SegDigito2: hex7seg
        port map (
            hexa    => s_saida_seletor_display(11 downto 8),
            sseg    => db_7seg_2
        );
    Display7SegDigito3: hex7seg
        port map (
            hexa    => s_saida_seletor_display(15 downto 12),
            sseg    => db_7seg_3
        );
    Display7SegEstado: hex7seg 
        port map (
            hexa    => s_db_estado,
            sseg    => db_estado
        );

    -- Saídas
    fim_posicao         <= s_fim_contador_tx;

    -- Depuração
    db_display_select   <= display_select;
    
end architecture;

