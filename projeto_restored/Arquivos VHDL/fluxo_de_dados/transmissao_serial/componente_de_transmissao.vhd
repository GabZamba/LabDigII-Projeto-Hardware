library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;


entity componente_de_transmissao is
    port (
        clock                   : in  std_logic;
        reset                   : in  std_logic;
        partida                 : in  std_logic;
        distancia_cubo          : in  std_logic_vector(11 downto 0);
        distancia_x             : in  std_logic_vector(11 downto 0);
        ascii_angulo_servo_x    : in  std_logic_vector(23 downto 0);

        saida_serial    : out std_logic;
        pronto          : out std_logic

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
            clock       : in  std_logic;
            reset       : in  std_logic;
            partida     : in  std_logic;
            tx_feita    : in  std_logic;
            fim_mux_tx  : in  std_logic;
    
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


    signal  s_conta_mux_tx, s_fim_mux_tx,
            s_zera_contador_tx, s_zera_contador_mux_tx,
            s_partida_tx, s_tx_feita
        : std_logic;
    signal  s_contagem_mux_tx
        : std_logic_vector (3 downto 0);
    signal  s_dados_ascii    
        : std_logic_vector (6 downto 0);
    signal  s_ascii_distancia_x, s_ascii_distancia_cubo
        : std_logic_vector(20 downto 0);


begin

    -- Unidade de Controle
    UC: componente_de_transmissao_uc
        port map ( 
            clock       => clock,
            reset       => reset,
            partida     => partida,
            tx_feita    => s_tx_feita,
            fim_mux_tx  => s_fim_mux_tx,

            conta_mux_tx        => s_conta_mux_tx,
            zera_contador_tx    => s_zera_contador_tx,
            partida_tx          => s_partida_tx,
            pronto              => pronto
        );

    -- Contadores que controlam os dados a serem transmitidos
    s_zera_contador_mux_tx    <= s_zera_contador_tx;

    ContadorMuxTx: contador_m
        generic map (
            M => 12,  
            N => 4 
        )
        port map (
            clock => clock,
            zera  => s_zera_contador_mux_tx,
            conta => s_conta_mux_tx,
            Q     => s_contagem_mux_tx,
            fim   => s_fim_mux_tx,
            meio  => open
        );

    -- Converter digitos para ascii
    s_ascii_distancia_cubo( 6 downto  0) <= "011" & distancia_cubo( 3 downto 0);
    s_ascii_distancia_cubo(13 downto  7) <= "011" & distancia_cubo( 7 downto 4);
    s_ascii_distancia_cubo(20 downto 14) <= "011" & distancia_cubo(11 downto 8);

    s_ascii_distancia_x( 6 downto  0) <= "011" & distancia_x( 3 downto 0);
    s_ascii_distancia_x(13 downto  7) <= "011" & distancia_x( 7 downto 4);
    s_ascii_distancia_x(20 downto 14) <= "011" & distancia_x(11 downto 8);

    -- Multiplexador para Transmissão Serial
    -- CCC.AAA,DDD;
    
    with s_contagem_mux_tx select
        s_dados_ascii <=
            s_ascii_distancia_cubo(20 downto 14)    when "0000",
            s_ascii_distancia_cubo(13 downto  7)    when "0001",
            s_ascii_distancia_cubo( 6 downto  0)    when "0010",
            "0101110"                               when "0011",   -- .
            ascii_angulo_servo_x(22 downto 16)      when "0100",
            ascii_angulo_servo_x(14 downto  8)      when "0101",
            ascii_angulo_servo_x( 6 downto  0)      when "0110",
            "0101100"                               when "0111",   -- ,
            s_ascii_distancia_x(20 downto 14)       when "1000",
            s_ascii_distancia_x(13 downto  7)       when "1001",
            s_ascii_distancia_x( 6 downto  0)       when "1010",
            "0111011"                               when "1011",   -- ;
            "0111111"                               when others;   -- ?

    -- Transmissor Serial
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