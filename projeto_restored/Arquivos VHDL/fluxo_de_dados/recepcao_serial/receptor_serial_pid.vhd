library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;


entity receptor_serial_pid is
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
end entity;


architecture arch of receptor_serial_pid is

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
    
    component conversor_BCD_int is
        port (
            valor_BCD   : in  std_logic_vector(11 downto 0);
            valor_int   : out std_logic_vector( 9 downto 0)
        );
    end component;

    signal  s_puldo_dado_recebido, s_fim_contador_rx,
            s_registra_p1, s_registra_p2, s_registra_p3,
            s_registra_i1, s_registra_i2, s_registra_i3,
            s_registra_d1, s_registra_d2, s_registra_d3,
            s_registra_valor_final
        : std_logic;
    signal  s_valor_rx, s_contagem_rx,
            s_valor_p1, s_valor_p2, s_valor_p3,
            s_valor_i1, s_valor_i2, s_valor_i3,
            s_valor_d1, s_valor_d2, s_valor_d3
        : std_logic_vector ( 3 downto 0);
    signal  s_dado_ascii
        : std_logic_vector ( 6 downto 0);
    signal  s_valor_int_p, s_valor_int_i, s_valor_int_d
        : std_logic_vector ( 9 downto 0);
    signal  s_valor_BCD_p, s_valor_BCD_i, s_valor_BCD_d,
            s_reg_valor_BCD_p, s_reg_valor_BCD_i, s_reg_valor_BCD_d
        : std_logic_vector (11 downto 0);

begin

    -- formato do valor: PPP,III,DDD#
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
            M   => 12,  --  PPP,III,DDD#
            N   => 4 
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
    s_registra_p1 <= s_puldo_dado_recebido and (not s_contagem_rx(3)) and (not s_contagem_rx(2)) and (not s_contagem_rx(1)) and (not s_contagem_rx(0)); -- contagem 0000
    s_registra_p2 <= s_puldo_dado_recebido and (not s_contagem_rx(3)) and (not s_contagem_rx(2)) and (not s_contagem_rx(1)) and (    s_contagem_rx(0)); -- contagem 0001
    s_registra_p3 <= s_puldo_dado_recebido and (not s_contagem_rx(3)) and (not s_contagem_rx(2)) and (    s_contagem_rx(1)) and (not s_contagem_rx(0)); -- contagem 0010
    s_registra_i1 <= s_puldo_dado_recebido and (not s_contagem_rx(3)) and (    s_contagem_rx(2)) and (not s_contagem_rx(1)) and (not s_contagem_rx(0)); -- contagem 0100
    s_registra_i2 <= s_puldo_dado_recebido and (not s_contagem_rx(3)) and (    s_contagem_rx(2)) and (not s_contagem_rx(1)) and (    s_contagem_rx(0)); -- contagem 0101
    s_registra_i3 <= s_puldo_dado_recebido and (not s_contagem_rx(3)) and (    s_contagem_rx(2)) and (    s_contagem_rx(1)) and (not s_contagem_rx(0)); -- contagem 0110
    s_registra_d1 <= s_puldo_dado_recebido and (    s_contagem_rx(3)) and (not s_contagem_rx(2)) and (not s_contagem_rx(1)) and (not s_contagem_rx(0)); -- contagem 1000
    s_registra_d2 <= s_puldo_dado_recebido and (    s_contagem_rx(3)) and (not s_contagem_rx(2)) and (not s_contagem_rx(1)) and (    s_contagem_rx(0)); -- contagem 1001
    s_registra_d3 <= s_puldo_dado_recebido and (    s_contagem_rx(3)) and (not s_contagem_rx(2)) and (    s_contagem_rx(1)) and (not s_contagem_rx(0)); -- contagem 1010




    s_valor_rx <= s_dado_ascii(3 downto 0);
    -- VALORES P
    -- registrador para a 1o caractere do p
    ValorP1: registrador_n
        generic map (
            N   => 4
        )
        port map (
            clock  => clock,
            clear  => reset,
            enable => s_registra_p1,
            D      => s_valor_rx,
            Q      => s_valor_p1
        );
    -- registrador para a 2o caractere do p
    ValorP2: registrador_n
        generic map (
            N   => 4
        )
        port map (
            clock  => clock,
            clear  => reset,
            enable => s_registra_p2,
            D      => s_valor_rx,
            Q      => s_valor_p2
        );
    -- registrador para a 3o caractere do p
    ValorP3: registrador_n
        generic map (
            N   => 4
        )
        port map (
            clock  => clock,
            clear  => reset,
            enable => s_registra_p3,
            D      => s_valor_rx,
            Q      => s_valor_p3
        );
    
    -- VALORES I
    -- registrador para a 1o caractere do i
    ValorI1: registrador_n
        generic map (
            N   => 4
        )
        port map (
            clock  => clock,
            clear  => reset,
            enable => s_registra_i1,
            D      => s_valor_rx,
            Q      => s_valor_i1
        );
    -- registrador para a 2o caractere do i
    ValorI2: registrador_n
        generic map (
            N   => 4
        )
        port map (
            clock  => clock,
            clear  => reset,
            enable => s_registra_i2,
            D      => s_valor_rx,
            Q      => s_valor_i2
        );
    -- registrador para a 3o caractere do i
    ValorI3: registrador_n
        generic map (
            N   => 4
        )
        port map (
            clock  => clock,
            clear  => reset,
            enable => s_registra_i3,
            D      => s_valor_rx,
            Q      => s_valor_i3
        );

    -- VALORES D
    -- registrador para a 1o caractere do d
    ValorD1: registrador_n
        generic map (
            N   => 4
        )
        port map (
            clock  => clock,
            clear  => reset,
            enable => s_registra_d1,
            D      => s_valor_rx,
            Q      => s_valor_d1
        );
    -- registrador para a 2o caractere do d
    ValorD2: registrador_n
        generic map (
            N   => 4
        )
        port map (
            clock  => clock,
            clear  => reset,
            enable => s_registra_d2,
            D      => s_valor_rx,
            Q      => s_valor_d2
        );
    -- registrador para a 3o caractere do d
    ValorD3: registrador_n
        generic map (
            N   => 4
        )
        port map (
            clock  => clock,
            clear  => reset,
            enable => s_registra_d3,
            D      => s_valor_rx,
            Q      => s_valor_d3
        );


    -- registrador para a distancia virtual completa
    s_registra_valor_final <= s_puldo_dado_recebido and s_fim_contador_rx; -- pulso assim que ultimo caractere é recebido

    s_valor_BCD_p <= s_valor_p1 & s_valor_p2 & s_valor_p3;
    s_valor_BCD_i <= s_valor_i1 & s_valor_i2 & s_valor_i3;
    s_valor_BCD_d <= s_valor_d1 & s_valor_d2 & s_valor_d3;

    ConversorP: conversor_BCD_int
        port map (
            valor_BCD   => s_valor_BCD_p,
            valor_int   => s_valor_int_p
        );

    ValorPInt: registrador_n
        generic map (
            N   => 10
        )
        port map (
            clock  => clock,
            clear  => reset,
            enable => s_registra_valor_final,
            D      => s_valor_int_p,
            Q      => valor_p
        );
    
    ValorPBCD: registrador_n
        generic map (
            N   => 12
        )
        port map (
            clock  => clock,
            clear  => reset,
            enable => s_registra_valor_final,
            D      => s_valor_BCD_p,
            Q      => s_reg_valor_BCD_p
        );
    
    
    ConversorI: conversor_BCD_int
        port map (
            valor_BCD   => s_valor_BCD_i,
            valor_int   => s_valor_int_i
        );

    ValorIInt: registrador_n
        generic map (
            N   => 10
        )
        port map (
            clock  => clock,
            clear  => reset,
            enable => s_registra_valor_final,
            D      => s_valor_int_i,
            Q      => valor_i
        );

    ValorIBCD: registrador_n
        generic map (
            N   => 12
        )
        port map (
            clock  => clock,
            clear  => reset,
            enable => s_registra_valor_final,
            D      => s_valor_BCD_i,
            Q      => s_reg_valor_BCD_i
        );
    
    ConversorD: conversor_BCD_int
        port map (
            valor_BCD   => s_valor_BCD_d,
            valor_int   => s_valor_int_d
        );

    ValorDInt: registrador_n
        generic map (
            N   => 10
        )
        port map (
            clock  => clock,
            clear  => reset,
            enable => s_registra_valor_final,
            D      => s_valor_int_d,
            Q      => valor_d
        );
    
    ValorDBCD: registrador_n
        generic map (
            N   => 12
        )
        port map (
            clock  => clock,
            clear  => reset,
            enable => s_registra_valor_final,
            D      => s_valor_BCD_d,
            Q      => s_reg_valor_BCD_d
        );

    -- Saídas
    pronto  <= s_registra_valor_final;
    pid_BCD <= s_reg_valor_BCD_d(7 downto 0) & s_reg_valor_BCD_i(7 downto 0) & s_reg_valor_BCD_p(7 downto 0);

end arch;