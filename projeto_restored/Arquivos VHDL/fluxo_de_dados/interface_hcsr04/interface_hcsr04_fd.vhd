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
        digito2         : out std_logic_vector (3 downto 0)
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

    component contador_cm is
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
            pronto  : out std_logic
        );
    end component;
    
    signal s_zera:                                      std_logic;
    signal s_digito0, s_digito1, s_digito2:             std_logic_vector (3 downto 0);
    signal s_entrada_registrador, s_saida_registrador:  std_logic_vector (11 downto 0);

begin

    s_zera  <= reset or zera;

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

    ContadorDistancia: contador_cm
        generic map (
            R   => 2941,
            N   => 12
        )
        port map (
            clock   => clock,
            reset   => s_zera,
            pulso   => echo,
            digito0 => s_digito0,
            digito1 => s_digito1,
            digito2 => s_digito2,
            pronto  => fim_medida
        );

    s_entrada_registrador   <= s_digito2 & s_digito1 & s_digito0;
    RegistradorDados: registrador_n
        generic map (
            N => 12
        )
        port map (
            clock   => clock,
            clear   => s_zera,
            enable  => registra,
            D       => s_entrada_registrador, -- (lembrar que 0110101 35 é recebido como 1010110 56)
            Q       => s_saida_registrador
        );
    digito0 <= s_saida_registrador( 3 downto 0);
    digito1 <= s_saida_registrador( 7 downto 4);
    digito2 <= s_saida_registrador(11 downto 8);
    
    
end architecture;