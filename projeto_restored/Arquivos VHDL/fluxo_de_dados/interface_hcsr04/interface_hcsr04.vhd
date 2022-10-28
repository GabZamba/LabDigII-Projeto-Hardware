library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity interface_hcsr04 is
    port (
        clock       : in std_logic;
        reset       : in std_logic;
        medir       : in std_logic;
        echo        : in std_logic;

        trigger     : out std_logic;
        medida      : out std_logic_vector(11 downto 0); -- 3 digitos BCD
        pronto      : out std_logic;
        db_estado   : out std_logic_vector(3 downto 0) -- estado da UC
    );
end entity interface_hcsr04;

architecture interface_hcsr04_arch of interface_hcsr04 is

    component interface_hcsr04_uc is 
        port ( 
            clock       : in  std_logic;
            reset       : in  std_logic;
            medir       : in  std_logic;
            echo        : in  std_logic;
            fim_medida  : in  std_logic;

            zera        : out std_logic;
            gera        : out std_logic;
            registra    : out std_logic;
            pronto      : out std_logic;
            db_estado   : out std_logic_vector(3 downto 0) 
        );
    end component;

    component interface_hcsr04_fd is 
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
    end component;

    signal s_zera, s_gera, s_fim_medida, s_registra: std_logic;
    signal s_digito0, s_digito1, s_digito2, s_estado: std_logic_vector(3 downto 0);

begin
    UC: interface_hcsr04_uc 
		port map (
            -- entradas
            clock       => clock,
            reset       => reset,
            medir       => medir,
            echo        => echo,
            fim_medida  => s_fim_medida,
            -- saídas
            zera        => s_zera,
            gera        => s_gera,
            registra    => s_registra,
            pronto      => pronto,
            db_estado   => s_estado
		);

    FD: interface_hcsr04_fd 
		port map (
			-- entradas
            clock       => clock,
            reset       => reset,
            zera        => s_zera,
            echo        => echo,
            gera        => s_gera,
            registra    => s_registra, 
            -- saidas
            pulso_trigger   => trigger,
            fim_medida      => s_fim_medida,
            digito0         => s_digito0,
            digito1         => s_digito1,
            digito2         => s_digito2
		);

    -- outras saídas
    medida      <= s_digito2 & s_digito1 & s_digito0;
    db_estado   <= s_estado;

    
end architecture;

