library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity componente_de_distancias_tb is
end entity;

architecture tb of componente_de_distancias_tb is
  
  -- Componente a ser testado (Device Under Test -- DUT)
    component componente_de_distancias is
        port (
            clock   : in  std_logic;
            reset   : in  std_logic;
            echo    : in  std_logic;
    
            trigger                 : out std_logic;
            fim_medida              : out std_logic;
            pronto                  : out std_logic;
            distancia_atual_int     : out std_logic_vector( 9 downto 0);
            distancia_anterior_BCD  : out std_logic_vector(15 downto 0);
            distancia_atual_BCD     : out std_logic_vector(15 downto 0);
            db_distancia_medida     : out std_logic_vector(15 downto 0)
        );
    end component;
  
    -- Declaração de sinais para conectar o componente a ser testado (DUT)
    --   valores iniciais para fins de simulacao (GHDL ou ModelSim)
    signal clock_in             : std_logic := '0';
    signal reset_in             : std_logic := '0';
    signal echo_in              : std_logic := '0';
    signal trigger_out          : std_logic := '0';
    signal fim_medida_out       : std_logic := '0';
    signal medida_atual_out     : std_logic_vector (15 downto 0) := x"0000";
    signal medida_anterior_out  : std_logic_vector (15 downto 0) := x"0000";
    signal db_medida            : std_logic_vector (15 downto 0) := x"0000";
    signal pronto_out           : std_logic := '0';

    -- Configurações do clock
    constant clockPeriod   : time      := 20 ns; -- clock de 50MHz
    signal keep_simulating : std_logic := '0';   -- delimita o tempo de geração do clock
    
    -- Array de casos de teste
    type caso_teste_type is record
        id    : natural; 
        tempo : integer;     
    end record;

    type casos_teste_array is array (natural range <>) of caso_teste_type;
    constant casos_teste : casos_teste_array :=
        (
            -- primeiras 4 medidas
            (1, 7588),  -- 5882us (1000mm)
            (1, 7589),  -- 5899us (1002,9mm) arredondar para 1003mm
            (1, 7600),  -- 6000us (1020,1mm) truncar para 1020mm
            (1, 7580),  -- 5800us ( 986,1mm) truncar para 986mm
            -- primeiras 4 medidas
            (2, 6600),  -- 5882us (1000mm)
            (2, 6499),  -- 5899us (1002,9mm) arredondar para 1003mm
            (2, 6900),  -- 6000us (1020,1mm) truncar para 1020mm
            (2, 6800),  -- 5800us ( 986,1mm) truncar para 986mm
            -- primeiras 4 medidas
            (3, 15882),  -- 5882us (1000mm)
            (3, 15899),  -- 5899us (1002,9mm) arredondar para 1003mm
            (3, 16000),  -- 6000us (1020,1mm) truncar para 1020mm
            (3, 15800),  -- 5800us ( 986,1mm) truncar para 986mm
            -- próximas 4 medidas
            (4, 24353),  -- 4353us (740mm)
            (4, 24399),  -- 4399us (747,9mm)  arredondar para 748mm
            (4, 24412),  -- 4412us (750mm)
            (4, 30100)  -- 29410us (5m, acima de 4m, o limite máximo)
            -- inserir aqui outros casos de teste (inserir "," na linha anterior)
        );

    signal larguraPulso: time := 1 ns;
    signal caso  : integer := 0;
    signal valorMedido, valorAtual, valorAnterior  : integer := 0;

begin
    -- Gerador de clock: executa enquanto 'keep_simulating = 1', com o período
    -- especificado. Quando keep_simulating=0, clock é interrompido, bem como a 
    -- simulação de eventos
    clock_in <= (not clock_in) and keep_simulating after clockPeriod/2;
    
    -- Conecta DUT (Device Under Test)
    dut: componente_de_distancias
        port map (
            clock     => clock_in,
            reset     => reset_in,
            echo      => echo_in,

            trigger                 => trigger_out,
            fim_medida              => fim_medida_out,
            pronto                  => pronto_out,
            distancia_atual_int     => open,
            distancia_anterior_BCD  => medida_anterior_out,
            distancia_atual_BCD     => medida_atual_out,
            db_distancia_medida     => db_medida
        );

    -- geracao dos sinais de entrada (estimulos)
    stimulus: process is
    begin
    
        assert false report "Inicio das simulacoes" severity note;
        keep_simulating <= '1';
        
        ---- valores iniciais ----------------
        echo_in  <= '0';

        ---- inicio: reset ----------------
        wait for 2*clockPeriod;
        reset_in <= '1'; 
        wait for 2 us;
        reset_in <= '0';
        wait until falling_edge(clock_in);

        ---- espera de 100us
        wait for 100 us;

        ---- loop pelos casos de teste
        for i in casos_teste'range loop
            -- 1) determina largura do pulso echo
            assert false report "Caso de teste " & integer'image(casos_teste(i).id) & ": " &
                integer'image(casos_teste(i).tempo) & "us" severity note;
            larguraPulso <= casos_teste(i).tempo * 100 ns; -- caso de teste "i"
            caso <= casos_teste(i).id;
            valorMedido <= 0;

            -- 2) envia pulso medir
            wait until falling_edge(clock_in);
        
            -- 3) espera por 400us (tempo entre trigger e echo)
            wait for 400 us;
        
            -- 4) gera pulso de echo (largura = larguraPulso)
            echo_in <= '1';
            wait for larguraPulso;
            echo_in <= '0';
        
            -- 5) espera final da medida
            wait until fim_medida_out = '1';
            wait for 5*clockPeriod;

            -- 6) converte cada valor BCD para inteiro
            valorMedido <= 
                to_integer(unsigned(db_medida(15 downto 12)))*1000 + 
                to_integer(unsigned(db_medida(11 downto 8)))*100 + 
                to_integer(unsigned(db_medida(7 downto 4)))*10 +
                to_integer(unsigned(db_medida(3 downto 0)));

            valorAtual <= 
                to_integer(unsigned(medida_atual_out(15 downto 12)))*1000 + 
                to_integer(unsigned(medida_atual_out(11 downto 8)))*100 + 
                to_integer(unsigned(medida_atual_out(7 downto 4)))*10 +
                to_integer(unsigned(medida_atual_out(3 downto 0)));

            valorAnterior <= 
                to_integer(unsigned(medida_anterior_out(15 downto 12)))*1000 + 
                to_integer(unsigned(medida_anterior_out(11 downto 8)))*100 + 
                to_integer(unsigned(medida_anterior_out(7 downto 4)))*10 +
                to_integer(unsigned(medida_anterior_out(3 downto 0)));

            wait for 2000 us;
            assert false report "Fim do caso " & integer'image(casos_teste(i).id) & ", valor medido: " & integer'image(valorMedido) severity note;
        
            -- 7) espera entre casos de tese
            -- wait for 100 us;

        end loop;

        ---- final dos casos de teste da simulacao
        assert false report "Fim das simulacoes" severity note;
        keep_simulating <= '0';
        
        wait; -- fim da simulação: aguarda indefinidamente (não retirar esta linha)
    end process;

end architecture;
