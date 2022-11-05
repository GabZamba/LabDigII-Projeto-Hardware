library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;


entity componente_de_transmissao is
    port (
        clock                   : in  std_logic;
        reset                   : in  std_logic;
        partida                 : in  std_logic;
        distancia_atual_cubo    : in  std_logic_vector(11 downto 0);
        distancia_atual_x       : in  std_logic_vector(11 downto 0);
        distancia_atual_y       : in  std_logic_vector(11 downto 0);
        ascii_angulo_servo_x    : in  std_logic_vector(23 downto 0);
        ascii_angulo_servo_y    : in  std_logic_vector(23 downto 0);

        saida_serial            : out std_logic;
        pronto                  : out std_logic

    );
end entity;


architecture arch of componente_de_transmissao is

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

    component componente_de_transmissao_uc is 
        port ( 
            clock               : in  std_logic;
            reset               : in  std_logic;
            partida             : in  std_logic;
            tx_feita            : in  std_logic;
            fim_mux_tx          : in  std_logic;
            fim_tx_total        : in  std_logic;

            conta_tx_total      : out std_logic;
            conta_mux_tx        : out std_logic;
            zera_contador_tx    : out std_logic;
            partida_tx          : out std_logic;
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

    signal  s_conta_mux_tx, s_fim_mux_tx, s_conta_tx_total, s_fim_tx_total,
            s_zera_contador_tx, s_zera_contador_mux_tx,
            s_partida_tx, s_tx_feita
        : std_logic;
    signal  s_contagem_tx
        : std_logic_vector (1 downto 0);
    signal  s_contagem_mux_tx
        : std_logic_vector (2 downto 0);
    signal  s_saida_mux_cubo, s_saida_mux_x, s_saida_mux_y, s_dados_ascii    
        : std_logic_vector (6 downto 0);
    signal  s_ascii_distancia_atual_x, s_ascii_distancia_atual_y, s_ascii_distancia_atual_cubo
        : std_logic_vector(20 downto 0);


begin

    -- Unidade de Controle
    UC: componente_de_transmissao_uc
        port map ( 
            clock               => clock,
            reset               => reset,
            partida             => partida,
            tx_feita            => s_tx_feita,
            fim_mux_tx          => s_fim_mux_tx,
            fim_tx_total        => s_fim_tx_total,

            conta_tx_total      => s_conta_tx_total,
            conta_mux_tx        => s_conta_mux_tx,
            zera_contador_tx    => s_zera_contador_tx,
            partida_tx          => s_partida_tx,
            pronto              => pronto
        );

    -- Contadores que controlam os dados a serem transmitidos
    s_zera_contador_mux_tx    <= s_zera_contador_tx or s_conta_tx_total;

    ContadorMuxTx: contador_m
        generic map (
            M => 8,  
            N => 3 
        )
        port map (
            clock => clock,
            zera  => s_zera_contador_mux_tx,
            conta => s_conta_mux_tx,
            Q     => s_contagem_mux_tx,
            fim   => s_fim_mux_tx,
            meio  => open
        );

    ContadorTxTotal: contador_m
        generic map (
            M => 3,  
            N => 2 
        )
        port map (
            clock => clock,
            zera  => s_zera_contador_tx,
            conta => s_conta_tx_total,
            Q     => s_contagem_tx,
            fim   => s_fim_tx_total,
            meio  => open
        );

    -- Converter digitos para ascii
    s_ascii_distancia_atual_cubo( 6 downto  0) <= "011" & distancia_atual_cubo( 3 downto 0);
    s_ascii_distancia_atual_cubo(13 downto  7) <= "011" & distancia_atual_cubo( 7 downto 4);
    s_ascii_distancia_atual_cubo(20 downto 14) <= "011" & distancia_atual_cubo(11 downto 8);

    s_ascii_distancia_atual_x( 6 downto  0) <= "011" & distancia_atual_x( 3 downto 0);
    s_ascii_distancia_atual_x(13 downto  7) <= "011" & distancia_atual_x( 7 downto 4);
    s_ascii_distancia_atual_x(20 downto 14) <= "011" & distancia_atual_x(11 downto 8);

    s_ascii_distancia_atual_y( 6 downto  0) <= "011" & distancia_atual_y( 3 downto 0);
    s_ascii_distancia_atual_y(13 downto  7) <= "011" & distancia_atual_y( 7 downto 4);
    s_ascii_distancia_atual_y(20 downto 14) <= "011" & distancia_atual_y(11 downto 8);

    -- Multiplexadores para Transmissão Serial
    MuxTxDistanciaCubo: mux_8x1_n
        generic map(
            BITS    => 7 
        )
        port map( 
            D0      => "0000000",   -- angulo do cubo é 0
            D1      => "0000000",
            D2      => "0000000",
            D3      => "0101100",   -- ,
            D4      => s_ascii_distancia_atual_cubo(20 downto 14),
            D5      => s_ascii_distancia_atual_cubo(13 downto  7),
            D6      => s_ascii_distancia_atual_cubo( 6 downto  0),
            D7      => "0100011",   -- #
            SEL     => s_contagem_mux_tx,
            MUX_OUT => s_saida_mux_cubo
        );

    MuxTxDistanciaX: mux_8x1_n
        generic map(
            BITS    => 7 
        )
        port map( 
            D0      => ascii_angulo_servo_x(22 downto 16),
            D1      => ascii_angulo_servo_x(14 downto  8),
            D2      => ascii_angulo_servo_x( 6 downto  0),
            D3      => "0101100",   -- ,
            D4      => s_ascii_distancia_atual_x(20 downto 14),
            D5      => s_ascii_distancia_atual_x(13 downto  7),
            D6      => s_ascii_distancia_atual_x( 6 downto  0),
            D7      => "0100011",   -- #
            SEL     => s_contagem_mux_tx,
            MUX_OUT => s_saida_mux_x
        );

    MuxTxDistanciaY: mux_8x1_n
        generic map(
            BITS    => 7 
        )
        port map( 
            D0      => ascii_angulo_servo_y(22 downto 16),
            D1      => ascii_angulo_servo_y(14 downto  8),
            D2      => ascii_angulo_servo_y( 6 downto  0),
            D3      => "0101100",   -- ,
            D4      => s_ascii_distancia_atual_y(20 downto 14),
            D5      => s_ascii_distancia_atual_y(13 downto  7),
            D6      => s_ascii_distancia_atual_y( 6 downto  0),
            D7      => "0001010",   -- \n
            SEL     => s_contagem_mux_tx,
            MUX_OUT => s_saida_mux_y
        );

    -- Transmissor Serial

    with s_contagem_tx select
        s_dados_ascii <= 
            s_saida_mux_cubo    when "00",
            s_saida_mux_x       when "01",
            s_saida_mux_y       when "10",
				"0000000"           when others;

    TransmissorSerial: tx_serial_7E2 
        port map (
            clock         => clock,
            reset         => reset, 
            partida       => s_partida_tx,
            dados_ascii   => s_dados_ascii,
            saida_serial  => saida_serial,
            tick          => open,
            contador_bits => open,
            pronto        => s_tx_feita
        );

end arch;