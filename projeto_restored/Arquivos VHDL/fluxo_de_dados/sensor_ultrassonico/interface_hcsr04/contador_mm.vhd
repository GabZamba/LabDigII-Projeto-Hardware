library ieee;
use ieee.std_logic_1164.all;

entity contador_mm is
    generic (
        constant R : integer := 294;
        constant N : integer := 9
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
end entity;

architecture contador_mm_arch of contador_mm is

    component contador_mm_uc is 
    port ( 
        clock   : in  std_logic;
        reset   : in  std_logic;
        pulso   : in  std_logic;

        zera    : out std_logic;
        conta   : out std_logic;
        pronto  : out std_logic
    );
    end component;


    component contador_m is
        generic (
            constant M : integer;
            constant N : integer
        );
        port (
            clock : in  std_logic;
            zera  : in  std_logic;
            conta : in  std_logic;
            Q     : out std_logic_vector (N-1 downto 0);
            fim   : out std_logic
        );
    end component;

    component edge_detector is
        port (  
            clock     : in  std_logic;
            signal_in : in  std_logic;
            output    : out std_logic
        );
    end component;

    component analisa_m is
        generic (
            constant M : integer := 50;  
            constant N : integer := 6 
        );
        port (
            valor            : in  std_logic_vector (N-1 downto 0);
            zero             : out std_logic;
            meio             : out std_logic;
            fim              : out std_logic;
            metade_superior  : out std_logic
        );
    end component;

    component contador_bcd_4digitos is 
        port ( 
            clock   : in  std_logic;
            zera    : in  std_logic;
            conta   : in  std_logic;

            digito0 : out std_logic_vector(3 downto 0);
            digito1 : out std_logic_vector(3 downto 0);
            digito2 : out std_logic_vector(3 downto 0);
            digito3 : out std_logic_vector(3 downto 0);
            fim     : out std_logic
        );
    end component;

    signal s_reset, s_zera, s_conta, s_metade_superior, s_conta_BCD:    std_logic := '0';
    signal s_contagem_tick:                                             std_logic_vector (N-1 downto 0);

begin
    UC: contador_mm_uc  
    port map ( 
        clock   => clock,
        reset   => reset,
        pulso   => pulso,

        zera    => s_zera,
        conta   => s_conta,
        pronto  => pronto
    );

    s_reset <= reset or s_zera;

    -- emite um pulso de tick a cada R * 20 ns (294 * 20ns = 5,80 us, equivalente a 1mm)
    ContadorTick: contador_m 
        generic map (
            M   => R, 
            N   => N
        ) 
        port map (
            clock   => clock, 
            zera    => s_reset, 
            conta   => s_conta,      
            Q       => s_contagem_tick,      -- contagem atual
            fim     => open
        );

    -- emite o sinal s_metade_superior quando a contagem de tick ultrapassa 294/2 = 146
    AnalisadorDeArredondamento: analisa_m
        generic map (
            M   => R,  
            N   => N
        )
        port map (
            valor           => s_contagem_tick,
            zero            => open,
            meio            => open,
            fim             => open,
            metade_superior => s_metade_superior
        );
    
    -- emite um pulso assim que a contagem o sinal s_metade_superior é ativado, incrementando o contadorBCD
    DetectorBordaMetade: edge_detector
        port map (
            clock       => clock,
            signal_in   => s_metade_superior,
            output      => s_conta_BCD
        );

    ContadorBCD4Digitos: contador_bcd_4digitos
        port map (
            clock   => clock,
            zera    => s_reset,
            conta   => s_conta_BCD,
            
            digito0 => digito0,
            digito1 => digito1,
            digito2 => digito2,
            digito3 => digito3,
            fim     => open
        );
  
end architecture;