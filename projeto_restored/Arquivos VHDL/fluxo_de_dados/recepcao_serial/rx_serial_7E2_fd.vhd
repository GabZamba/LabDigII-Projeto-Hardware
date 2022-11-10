library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity rx_serial_7E2_fd is
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
end entity;

architecture rx_serial_7E2_fd_arch of rx_serial_7E2_fd is
     
    component deslocador_n
    generic (
        constant N : integer
    );
    port (
        clock          : in  std_logic;
        reset          : in  std_logic;
        carrega        : in  std_logic; 
        desloca        : in  std_logic; 
        entrada_serial : in  std_logic; 
        dados          : in  std_logic_vector (N-1 downto 0);
        saida          : out std_logic_vector (N-1 downto 0)
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

    component testador_paridade is
        port (
            dado     : in  std_logic_vector (6 downto 0);
            paridade : in  std_logic;
            par_ok   : out std_logic;
            impar_ok : out std_logic
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
    end component;
    

    signal s_paridade_ok, s_limpar
        : std_logic;
    signal s_saida_registrador
        : std_logic_vector (7 downto 0);
    signal s_saida_deslocador
        : std_logic_vector (10 downto 0);


begin

    s_limpar    <= reset or zera;

    -- deslocador que insere cada bit transmitido e desloca para esquerda
    Deslocador: deslocador_n 
        generic map (
            N => 11
        )
        port map (
            clock          => clock, 
            reset          => s_limpar, -- reseta tudo para 1
            carrega        => '0', -- sinal que permite carregar valor
            desloca        => desloca, 
            entrada_serial => dado_serial, 
            dados          => (others=>'1'), -- valor para ser carregado
            saida          => s_saida_deslocador -- 0 start bit, 1 a 7 dados, 8 paridade, 9 e 10 stop bit
        );

    -- conta o número de bits recebidos a partir do startbit
    ContadorDados: contador_m 
        generic map (
            M => 12,    -- 11 bits ao todo (1 start, 7 dados, 1 paridade e 2 stop), mas contagem começa em 1
            N => 4
        ) 
        port map (
            clock => clock, 
            zera  => s_limpar, 
            conta => conta_rx, 
            Q     => open, -- contagem atual
            fim   => fim_rx
        );

    -- registra os bits de dados e de paridade do deslocador, após término da recepção
    RegistradorDados: registrador_n
        generic map (
            N => 8
        )
        port map (
            clock   => clock,
            clear   => s_limpar,
            enable  => registra,
            D       => s_saida_deslocador(8 downto 1),
            Q       => s_saida_registrador
        );
    
    -- verifica se a paridade dos bits recebidos está correta
    TestadorParidade: testador_paridade
        port map (
            dado        => s_saida_registrador(6 downto 0),
            paridade    => s_saida_registrador(7),
            par_ok      => s_paridade_ok,
            impar_ok    => open -- !par_ok
        );
    
    -- saidas
    dados_ascii         <= s_saida_registrador(6 downto 0);
    paridade_recebida   <= s_saida_registrador(7);
    paridade_ok         <= tem_dado and s_paridade_ok; -- só poderá ser 1 se tiver dado
    
end architecture;

