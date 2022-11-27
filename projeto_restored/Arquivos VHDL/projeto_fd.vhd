library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;


entity projeto_fd is
    port (
        clock                   : in  std_logic;
        reset                   : in  std_logic;
        cubo_select             : in  std_logic;
        echo_cubo               : in  std_logic;
        echo_x                  : in  std_logic;
        entrada_serial          : in  std_logic;
        entrada_serial_pid      : in  std_logic;

        trigger_cubo            : out std_logic;
        trigger_x               : out std_logic;
        fim_medida_cubo         : out std_logic;
        fim_medida_bola_x       : out std_logic;
        pwm_servo_x             : out std_logic;
        saida_serial            : out std_logic;

        db_angulo_medido_x      : out std_logic_vector(11 downto 0);
        db_pid                  : out std_logic_vector(15 downto 0);
        db_distancia_cubo       : out std_logic_vector(15 downto 0);
        db_distancia_medida_x   : out std_logic_vector(15 downto 0)
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
            distancia_int       : out std_logic_vector( 9 downto 0);
            distancia_BCD       : out std_logic_vector(15 downto 0);
            db_distancia_medida : out std_logic_vector(15 downto 0)
        );
    end component;

    component componente_do_servomotor is
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
    end component;

    component receptor_cubo_virtual is
        port (
            clock       : in  std_logic;
            reset       : in  std_logic;
            dado_serial : in  std_logic;
    
            pronto              : out std_logic;
            distancia_cubo_int  : out std_logic_vector( 9 downto 0);
            distancia_cubo_BCD  : out std_logic_vector(15 downto 0)
        );
    end component;

    
    component receptor_serial_pid is
        port (
            clock       : in  std_logic;
            reset       : in  std_logic;
            dado_serial : in  std_logic;

            pronto      : out std_logic;
            valor_p     : out std_logic_vector( 9 downto 0);
            valor_i     : out std_logic_vector( 9 downto 0);
            valor_d     : out std_logic_vector( 9 downto 0);
            pid_BCD     : out std_logic_vector(23 downto 0)
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
    
    component componente_de_transmissao is
        port (
            clock                   : in  std_logic;
            reset                   : in  std_logic;
            partida                 : in  std_logic;
            distancia_cubo    : in  std_logic_vector(11 downto 0);
            distancia_x       : in  std_logic_vector(11 downto 0);
            ascii_angulo_servo_x    : in  std_logic_vector(23 downto 0);

            saida_serial            : out std_logic;
            pronto                  : out std_logic

        );
    end component;


    signal  s_partida_tx
        : std_logic;
    signal  s_distancia_int_x, 
            s_distancia_int_cubo_real, s_distancia_int_cubo_virtual, s_distancia_int_cubo,
            s_valor_p, s_valor_i, s_valor_d
        : std_logic_vector( 9 downto 0);
    signal  s_distancia_BCD_cubo
        : std_logic_vector(11 downto 0);
    signal  s_distancia_BCD_x, s_distancia_BCD_cubo_real, s_distancia_BCD_cubo_virtual
        : std_logic_vector(15 downto 0);
    signal  s_ascii_angulo_servo_x, s_pid_BCD
        : std_logic_vector(23 downto 0);
    
    
begin

    -- Componentes para os sensores ultrassônicos de distância

    MedidorDistanciaCubo: componente_de_distancias 
        port map (
            clock           => clock,
            reset           => reset,
            echo            => echo_cubo,
    
            trigger             => trigger_cubo,
            fim_medida          => open,
            pronto              => fim_medida_cubo,
            distancia_int       => s_distancia_int_cubo_real,
            distancia_BCD       => s_distancia_BCD_cubo_real,
            db_distancia_medida => open
        );

    MedidorDistanciaX: componente_de_distancias 
        port map(
            clock           => clock,
            reset           => reset,
            echo            => echo_x,

            trigger             => trigger_x,
            fim_medida          => fim_medida_bola_x,
            pronto              => open,
            distancia_int       => s_distancia_int_x,
            distancia_BCD       => s_distancia_BCD_x,
            db_distancia_medida => open
        );

    -- Componente do Servomotor

    ServomotorX: componente_do_servomotor 
        port map (
            clock                   => clock,
            reset                   => reset,
            posicao_equilibrio      => s_distancia_int_cubo,
            distancia_medida        => s_distancia_int_x,
            p_externo               => s_valor_p,
            i_externo               => s_valor_i,
            d_externo               => s_valor_d,
    
            pwm_servo               => pwm_servo_x,
            angulo_medido           => s_ascii_angulo_servo_x,
            db_erro_atual           => open
        );

    -- timer de 100ms entre cada transmissão
    Timer100ms: contador_m 
        generic map (
            M => 5_000_000, -- 5.000.000 * 20ns = 100ms
            N => 23
            -- M => 100,
            -- N => 7
        )
        port map (
            clock => clock,
            zera  => reset,
            conta => '1',
            Q     => open,
            fim   => s_partida_tx,
            meio  => open
        );

    -- Componente que realiza a transmissão serial dos dados
    ComponenteDeTransmissao: componente_de_transmissao
        port map (
            clock                   => clock,
            reset                   => reset,
            partida                 => s_partida_tx,
            distancia_cubo          => s_distancia_BCD_cubo,
            distancia_x             => s_distancia_BCD_x(11 downto 0),
            ascii_angulo_servo_x    => s_ascii_angulo_servo_x,

            saida_serial            => saida_serial,
            pronto                  => open
        );

    -- ReceptorCuboVirtual: receptor_cubo_virtual 
    --     port map(
    --         clock           => clock,
    --         reset           => reset,
    --         dado_serial     => entrada_serial,

    --         distancia_cubo_int  => s_distancia_int_cubo_virtual,
    --         distancia_cubo_BCD  => s_distancia_BCD_cubo_virtual,
    --         pronto              => open
    --     );
    s_distancia_int_cubo_virtual <= "0100101100";
    s_distancia_BCD_cubo_virtual <= "0000001100000000";

        
    ReceptorPID: receptor_serial_pid
        port map (
            clock       => clock,
            reset       => reset,
            dado_serial => entrada_serial_pid,

            pronto      => open,
            valor_p     => s_valor_p,
            valor_i     => s_valor_i,
            valor_d     => s_valor_d,
            pid_BCD     => s_pid_BCD
        );

    with cubo_select select
        s_distancia_int_cubo <=
            s_distancia_int_cubo_virtual    when '1',
            s_distancia_int_cubo_real       when others;
        
    with cubo_select select
        s_distancia_BCD_cubo <=
            s_distancia_BCD_cubo_virtual(11 downto 0)   when '1',
            s_distancia_BCD_cubo_real(11 downto 0)      when others;

    -- Depuração
    db_distancia_cubo       <= "0000" & s_distancia_BCD_cubo;
    db_distancia_medida_x   <= s_distancia_BCD_x;
    db_angulo_medido_x      <= s_ascii_angulo_servo_x(19 downto 16) & s_ascii_angulo_servo_x(11 downto 8) & s_ascii_angulo_servo_x(3 downto 0);
    db_pid                  <= s_pid_BCD( 7 downto 0) & s_pid_BCD(23 downto 16); -- 2 dig de p e 2 dig de d

end arch;