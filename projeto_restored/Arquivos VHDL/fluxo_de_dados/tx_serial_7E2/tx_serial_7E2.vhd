library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tx_serial_7E2 is
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
end entity;

architecture tx_serial_7E2_arch of tx_serial_7E2 is
     
    component tx_serial_7E2_uc 
        port ( 
            clock   : in  std_logic;
            reset   : in  std_logic;
            partida : in  std_logic;
            tick    : in  std_logic;
            fim     : in  std_logic;
            zera    : out std_logic;
            conta   : out std_logic;
            carrega : out std_logic;
            desloca : out std_logic;
            pronto  : out std_logic
        );
    end component;

    component tx_serial_7E2_fd 
        port (
            clock        	: in  std_logic;
            reset        	: in  std_logic;
            zera         	: in  std_logic;
            conta        	: in  std_logic;
            carrega      	: in  std_logic;
            desloca      	: in  std_logic;
            dados_ascii		: in  std_logic_vector (6 downto 0);
            contador_bits  	: out std_logic_vector (3 downto 0);
            saida_serial 	: out std_logic;
            fim          	: out std_logic
        );
    end component;
    
    component contador_m
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
    
    component edge_detector 
        port (  
            clock     : in  std_logic;
            signal_in : in  std_logic;
            output    : out std_logic
        );
    end component;
    
    signal  s_reset, s_zera, s_pulso_partida,
            s_conta, s_carrega, s_desloca, s_tick, s_fim,
            s_saida_serial
        : std_logic;

begin

    -- sinais reset e partida ativos em alto
    s_reset   <= reset;

    UC: tx_serial_7E2_uc 
		port map (
		   clock   => clock, 
		   reset   => s_reset, 
		   partida => s_pulso_partida, 
		   tick    => s_tick, 
		   fim     => s_fim,
		   zera    => s_zera, 
		   conta   => s_conta, 
		   carrega => s_carrega, 
		   desloca => s_desloca, 
		   pronto  => pronto
		);

    FD: tx_serial_7E2_fd 
		port map (
			clock        => clock, 
			reset        => s_reset, 
			zera         => s_zera, 
			conta        => s_conta, 
			carrega      => s_carrega, 
			desloca      => s_desloca, 
			dados_ascii  => dados_ascii,
			contador_bits=> contador_bits, 
			saida_serial => s_saida_serial, 
			fim          => s_fim
		);

    -- gerador de tick
    -- fator de divisao para 9600 bauds (5208=50M/9600)
    -- fator de divisao para 115.200 bauds (434=50M/115200)
    GeradorTick: contador_m 
		generic map (
			M => 434, -- 115.200 bauds
			N => 9
		) 
		port map (
			clock => clock, 
			zera  => s_zera, 
			conta => '1', 
			Q     => open, 
			fim   => s_tick
		);
 
    DetectorBorda: edge_detector 
		port map (
			clock     => clock,
			signal_in => partida,
			output    => s_pulso_partida
		);
    
    -- saida
    saida_serial <= s_saida_serial;
    tick <= s_tick;

end architecture;

