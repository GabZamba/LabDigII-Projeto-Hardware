library ieee;
use ieee.std_logic_1164.all;

entity contador_cm is
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
end entity;

architecture contador_cm_arch of contador_cm is

    component contador_cm_uc is 
    port ( 
        clock       : in  std_logic;
        reset       : in  std_logic;
        pulso       : in  std_logic;

        zera        : out std_logic;
        conta       : out std_logic;
        pronto      : out std_logic
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

    component contador_bcd_3digitos is 
        port ( 
            clock   : in  std_logic;
            zera    : in  std_logic;
            conta   : in  std_logic;

            digito0 : out std_logic_vector(3 downto 0);
            digito1 : out std_logic_vector(3 downto 0);
            digito2 : out std_logic_vector(3 downto 0);
            fim     : out std_logic
        );
    end component;

    signal s_reset, s_zera, s_conta, s_metade_superior, s_conta_BCD:    std_logic := '0';
    signal s_contagem_tick:                                             std_logic_vector (11 downto 0);

begin
    UC: contador_cm_uc  
    port map ( 
        clock       => clock,
        reset       => reset,
        pulso       => pulso,

        zera        => s_zera,
        conta       => s_conta,
        pronto      => pronto
    );

    s_reset <= reset or s_zera;

    ContadorTick: contador_m 
        generic map (
            M   => 2941, 
            N   => 12
        ) 
        port map (
            clock   => clock, 
            zera    => s_reset, 
            conta   => s_conta,      
            Q       => s_contagem_tick,      -- contagem atual
            fim     => open
        );

    AnalisadorDeArredondamento: analisa_m
        generic map (
            M   => 2941,  
            N   => 12
        )
        port map (
            valor           => s_contagem_tick,
            zero            => open,
            meio            => open,
            fim             => open,
            metade_superior => s_metade_superior
        );
    
    DetectorBordaMetade: edge_detector
        port map (
            clock       => clock,
            signal_in   => s_metade_superior,
            output      => s_conta_BCD
        );

    ContadorBCD3Digitos: contador_bcd_3digitos
        port map (
            clock   => clock,
            zera    => s_reset,
            conta   => s_conta_BCD,
            
            digito0 => digito0,
            digito1 => digito1,
            digito2 => digito2,
            fim     => open
        );
  
end architecture;