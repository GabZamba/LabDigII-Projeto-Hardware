library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity projeto is
    port (
        clock               : in  std_logic;
        reset               : in  std_logic;
        echo_cubo           : in  std_logic;
        echo_bola_x         : in  std_logic;
        entrada_serial      : in  std_logic;
        cubo_select         : in  std_logic;
        display_select      : in  std_logic_vector(1 downto 0);

        trigger_cubo        : out std_logic;
        trigger_bola_x      : out std_logic;
        pwm_servo_x         : out std_logic;
        saida_serial        : out std_logic;

        db_display_select   : out std_logic_vector(1 downto 0);
        db_7seg_0           : out std_logic_vector(6 downto 0);
        db_7seg_1           : out std_logic_vector(6 downto 0);
        db_7seg_2           : out std_logic_vector(6 downto 0);
        db_7seg_3           : out std_logic_vector(6 downto 0)
    );
end entity projeto;


architecture arch of projeto is

    component projeto_fd is
        port (
            clock                   : in  std_logic;
            reset                   : in  std_logic;
            cubo_select             : in  std_logic;
            echo_cubo               : in  std_logic;
            echo_bola_x             : in  std_logic;
            entrada_serial          : in  std_logic;
    
            trigger_cubo            : out std_logic;
            trigger_bola_x          : out std_logic;
            fim_medida_cubo         : out std_logic;
            fim_medida_bola_x       : out std_logic;
            pwm_servo_x             : out std_logic;
            saida_serial            : out std_logic;
    
            db_angulo_medido_x      : out std_logic_vector(11 downto 0);
            db_distancia_cubo       : out std_logic_vector(15 downto 0);
            db_distancia_medida_x   : out std_logic_vector(15 downto 0)
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

    signal  s_reset
        : std_logic; 
    signal  s_db_angulo_medido_x           
        : std_logic_vector(11 downto 0);
    signal  s_db_distancia_medida_x, s_db_distancia_cubo,
            s_db_angulo_x, s_saida_seletor_display
        : std_logic_vector(15 downto 0);


begin

    s_reset <= not reset; 

    FD: projeto_fd 
		port map (
            clock                   => clock,
            reset                   => s_reset,
            cubo_select             => cubo_select,
            echo_cubo               => echo_cubo,
            echo_bola_x             => echo_bola_x,
            entrada_serial          => entrada_serial,
    
            trigger_cubo            => trigger_cubo,
            trigger_bola_x          => trigger_bola_x,
            fim_medida_cubo         => open,
            fim_medida_bola_x       => open,
            pwm_servo_x             => pwm_servo_x,
            saida_serial            => saida_serial,
    
            db_angulo_medido_x      => s_db_angulo_medido_x,
            db_distancia_cubo       => s_db_distancia_cubo,
            db_distancia_medida_x   => s_db_distancia_medida_x
            
		);

    -- Multiplexador para Displays de 7 Segmentos
    s_db_angulo_x   <= "0000" & s_db_angulo_medido_x;
    Multiplexador7Seg: mux_4x1_n
        generic map (
            BITS    => 16
        )
        port map ( 
            D3      => s_db_angulo_x,
            D2      => s_db_distancia_cubo,
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

    -- Depuração
    db_display_select   <= display_select;
    
end architecture;

