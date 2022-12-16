library ieee;
use ieee.std_logic_1164.all;

entity interface_hcsr04_fd is 
    port ( 
        clock       : in  std_logic;
        reset       : in  std_logic;
        zera        : in  std_logic;
        echo        : in  std_logic;
        gera        : in  std_logic;
        registra    : in  std_logic;

        pulso_trigger   : out std_logic;
        fim_medida      : out std_logic;
        digito0         : out std_logic_vector (3 downto 0);
        digito1         : out std_logic_vector (3 downto 0);
        digito2         : out std_logic_vector (3 downto 0);
        digito3         : out std_logic_vector (3 downto 0)
    );
end interface_hcsr04_fd;

architecture interface_hcsr04_fd_arch of interface_hcsr04_fd is

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
    end component;

    component gerador_pulso is
        generic (
            largura: integer:= 25
        );
        port (
            clock  : in  std_logic;
            reset  : in  std_logic;
            gera   : in  std_logic;
            para   : in  std_logic;
            pulso  : out std_logic;
            pronto : out std_logic
        );
    end component;

    component contador_mm is
        generic (
            constant R : integer := 2941;
            constant N : integer := 12
        );
        port (
            clock   : in  std_logic;
            reset   : in  std_logic;
            pulso   : in  std_logic;
            digito0 : out std_logic_vector(3 downto 0);
            digito1 : out std_logic_vector(3 downto 0);
            digito2 : out std_logic_vector(3 downto 0);
            digito3 : out std_logic_vector(3 downto 0);
            pronto  : out std_logic
        );
    end component;
    
    signal s_zera:                                      std_logic;
    signal s_digito0, s_digito1, s_digito2, s_digito3:  std_logic_vector (3 downto 0);
    signal s_entrada_registrador, s_saida_registrador:  std_logic_vector (15 downto 0);

begin

    s_zera  <= reset or zera;

    -- gera pulso trigger de 10us
    GeradorPulsoTrigger: gerador_pulso
        generic map (
            largura => 500  -- 500 * 20ns = 10us
        )
        port map (
            clock   => clock,
            reset   => reset,
            gera    => gera,
            para    => s_zera,
            pulso   => pulso_trigger,
            pronto  => open
        );

    -- converte o tempo do pulso de echo para mm
    ContadorDistancia: contador_mm
        generic map (
            -- R   => 2941,    -- 2941 * 20ns = 58,82 us, equivalente a 1cm
            -- N   => 12       -- 2^12 (4096) para caber 2941
            R   => 294,     -- 294 * 20ns = 5,80 us, equivalente a 1mm
            N   => 9        -- 2^9 (512) para caber 294
        )
        port map (
            clock   => clock,
            reset   => s_zera,
            pulso   => echo,
            digito0 => s_digito0,
            digito1 => s_digito1,
            digito2 => s_digito2,
            digito3 => s_digito3,
            pronto  => fim_medida
        );

    s_entrada_registrador   <= s_digito3 & s_digito2 & s_digito1 & s_digito0;

    -- registra os dados após a medição
    RegistradorDados: registrador_n
        generic map (
            N => 16
        )
        port map (
            clock   => clock,
            clear   => s_zera,
            enable  => registra,
            D       => s_entrada_registrador,
            Q       => s_saida_registrador
        );

    digito0 <= s_saida_registrador( 3 downto  0);
    digito1 <= s_saida_registrador( 7 downto  4);
    digito2 <= s_saida_registrador(11 downto  8);
    digito3 <= s_saida_registrador(15 downto 12);
    
    
end architecture;