library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity projeto_fd is
    port (
        clock                       : in  std_logic;
        reset                       : in  std_logic;
        contador_posicao_conta      : in  std_logic;
        contador_posicao_zera       : in  std_logic;
        contador_transmissao_conta  : in  std_logic;
        contador_transmissao_zera   : in  std_logic;
        distancia_medir             : in  std_logic;
        distancia_echo              : in  std_logic;
        tx_partida                  : in  std_logic;
        timer_zera                  : in  std_logic;
        entrada_serial              : in  std_logic;

        contador_transmissao_fim    : out std_logic;
        distancia_trigger           : out std_logic;
        distancia_fim_medida        : out std_logic;
        servo_pwm                   : out std_logic;
        tx_saida_serial             : out std_logic;
        tx_pronto                   : out std_logic;
        timer_fim_2_seg             : out std_logic;
        interrompido                : out std_logic;

        db_angulo_medido            : out std_logic_vector(11 downto 0);
        db_distancia_medida         : out std_logic_vector(11 downto 0)
    );
end entity;

architecture arch of projeto_fd is
    component interface_hcsr04 is
        port (
            clock       : in std_logic;
            reset       : in std_logic;
            medir       : in std_logic;
            echo        : in std_logic;
    
            trigger     : out std_logic;
            medida      : out std_logic_vector(11 downto 0); 
            pronto      : out std_logic;
            db_estado   : out std_logic_vector(3 downto 0) 
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
    
    component rom_angulos_8x24 is
        port (
            endereco : in  std_logic_vector(2 downto 0);
            saida    : out std_logic_vector(23 downto 0)
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

    component controle_servo is
        port (
            clock             : in  std_logic;
            reset             : in  std_logic;
            posicao_servo     : in  std_logic_vector (2 downto 0);
            controle          : out std_logic
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

    signal s_enable_registrador         : std_logic := '0';
    signal s_contador_transmissao_saida : std_logic_vector (2 downto 0);
    signal s_contador_posicao_saida     : std_logic_vector (2 downto 0);
    signal s_tx_dado_ascii              : std_logic_vector (6 downto 0);
    signal s_dados_ascii                : std_logic_vector (6 downto 0);
    signal s_saida_reg                  : std_logic_vector (6 downto 0);
    signal s_distancia_medida           : std_logic_vector(11 downto 0);
    signal s_distancia_medida_ascii     : std_logic_vector(20 downto 0);
    signal s_rom_saida                  : std_logic_vector(23 downto 0);
    
    
begin

    MedidorDistancia: interface_hcsr04
        port map(
            clock           => clock,
            reset           => reset,
            medir           => distancia_medir,
            echo            => distancia_echo,
            trigger         => distancia_trigger,
            medida          => s_distancia_medida,
            pronto          => distancia_fim_medida,
            db_estado       => open
        );


    ContadorUpDown: contadorg_updown_m
        generic map (
            M => 8
        )
        port map (
            clock   => clock,
            zera_as => reset,
            zera_s  => contador_posicao_zera,
            conta   => contador_posicao_conta,
            Q       => s_contador_posicao_saida,
            inicio  => open,
            fim     => open,
            meio    => open
       ); 


    RomAngulos: rom_angulos_8x24
        port map (
            endereco => s_contador_posicao_saida,
            saida    => s_rom_saida
        );
    
        
    ControleServo: controle_servo 
        port map(
            clock             => clock,
            reset             => reset,
            posicao_servo     => s_contador_posicao_saida,
            controle          => servo_pwm
        );

    TransmissorSerial: tx_serial_7E2 
        port map (
            clock         => clock,
            reset         => reset, 
            partida       => tx_partida,
            dados_ascii   => s_tx_dado_ascii,
            saida_serial  => tx_saida_serial,
            tick          => open,
            contador_bits => open,
            pronto        => tx_pronto
        );

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
            fim   => timer_fim_2_seg,
            meio  => open
        );

    ContadorTransmissao: contador_m 
        generic map (
            M => 8,  
            N => 3 
        )
        port map (
            clock => clock,
            zera  => contador_transmissao_zera,
            conta => contador_transmissao_conta,
            Q     => s_contador_transmissao_saida,
            fim   => contador_transmissao_fim,
            meio  => open
        );
    
    MuxTransmissorSerial: mux_8x1_n 
        generic map(
            BITS    => 7 
        )
        port map( 
            D0      => s_rom_saida(22 downto 16),
            D1      => s_rom_saida(14 downto 8),
            D2      => s_rom_saida(6 downto 0),
            D3      => "0101100",
            D4      => s_distancia_medida_ascii(20 downto 14),
            D5      => s_distancia_medida_ascii(13 downto 7),
            D6      => s_distancia_medida_ascii(6 downto 0),
            D7      => "0100011",
            SEL     => s_contador_transmissao_saida,
            MUX_OUT => s_tx_dado_ascii
        );

    ReceptorSerial: rx_serial_7E2
        port map (
            clock               => clock,
            reset               => reset,
            dado_serial         => entrada_serial,
    
            dados_ascii         => s_dados_ascii,
            paridade_recebida   => open,
            tem_dado            => open,
            paridade_ok         => open,
            pronto_rx           => open,
            db_estado           => open
        );
        
    with s_dados_ascii select
        s_enable_registrador  <=    '1' when "1101001", -- i 
                                    '1' when "1110010", -- r
                                    '0' when others;
    
    RegistradorModo: registrador_n
        generic map (
            N   => 7 
        )
        port map (
            clock  => clock,
            clear  => reset,
            enable => s_enable_registrador,
            D      => s_dados_ascii,
            Q      => s_saida_reg
        );
    

    with s_saida_reg select
        interrompido  <=  '1' when "1101001", -- i 
                          '0' when "1110010", -- r
                          '0' when others;

    -- Converter digitos para ascii
    s_distancia_medida_ascii(6 downto 0)    <= "011" & s_distancia_medida(3 downto 0);   
    s_distancia_medida_ascii(13 downto 7)   <= "011" & s_distancia_medida(7 downto 4);
    s_distancia_medida_ascii(20 downto 14)  <= "011" & s_distancia_medida(11 downto 8);

    -- Depuracao

    db_distancia_medida <= s_distancia_medida;
    db_angulo_medido    <= s_rom_saida(19 downto 16) & s_rom_saida(11 downto 8) & s_rom_saida(3 downto 0);

end arch;