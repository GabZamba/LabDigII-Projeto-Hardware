library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity rx_serial_7E2 is
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
end entity;

architecture rx_serial_7E2_arch of rx_serial_7E2 is

    component rx_serial_7E2_uc is 
    port (
        clock       : in  std_logic;
        reset       : in  std_logic;
        dado_serial : in  std_logic;
        tick_meio   : in  std_logic;
        fim         : in  std_logic;
        
        zera        : out std_logic;
        conta_rx    : out std_logic;
        registra    : out std_logic;
        desloca     : out std_logic;
        pronto      : out std_logic;
        tem_dado    : out std_logic;
        db_estado   : out std_logic_vector(3 downto 0)
    );
    end component;

    component rx_serial_7E2_fd is
        port (
            clock               : in  std_logic;
            reset               : in  std_logic;
            zera                : in  std_logic;
            conta_rx            : in  std_logic;
            registra            : in  std_logic;
            desloca             : in  std_logic;
            dado_serial         : in  std_logic;
            tem_dado            : in  std_logic;
    
            fim_rx              : out std_logic;
            paridade_recebida   : out std_logic;
            paridade_ok         : out std_logic;
            dados_ascii         : out std_logic_vector (6 downto 0)
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
    end component contador_m;

    component hex7seg is
        port (
            hexa : in  std_logic_vector(3 downto 0);
            sseg : out std_logic_vector(6 downto 0)
        );
    end component;

    
    signal s_zera, s_conta_rx, s_registra, s_desloca, s_tick_meio, s_fim_rx, s_tem_dado: std_logic;
    signal s_estado: std_logic_vector(3 downto 0);

begin

    UC: rx_serial_7E2_uc 
		port map (
            -- entradas
            clock       => clock,
            reset       => reset,
            dado_serial => dado_serial,
            tick_meio   => s_tick_meio,
            fim         => s_fim_rx,
            -- saidas
            zera        => s_zera,
            conta_rx    => s_conta_rx,
            registra    => s_registra,
            desloca     => s_desloca,
            pronto      => pronto_rx,
            tem_dado    => s_tem_dado,
            db_estado   => s_estado
		);

    FD: rx_serial_7E2_fd 
		port map (
			-- entradas
            clock               => clock, 
            reset               => reset,
			zera                => s_zera, 
			conta_rx            => s_conta_rx, 
			registra            => s_registra, 
			desloca             => s_desloca, 
			dado_serial         => dado_serial,
            tem_dado            => s_tem_dado,
            -- saidas
            fim_rx              => s_fim_rx,
            paridade_recebida   => paridade_recebida,
            paridade_ok         => paridade_ok,
            dados_ascii         => dados_ascii
		);

    -- gerador de tick
    ContadorTick: contador_m
        generic map (
            M => 434, -- 115.200 bauds (50M/115.200)
            N => 9
        )
        port map (
            clock => clock,
            zera  => s_zera,
            conta => '1',
            Q     => open,
            fim   => open,
            meio  => s_tick_meio
        );
 
    DB_7SegEstado: hex7seg 
        port map (
            hexa    => s_estado,
            sseg    => db_estado
        );

    -- saídas
    tem_dado <= s_tem_dado;
    
    
end architecture;

