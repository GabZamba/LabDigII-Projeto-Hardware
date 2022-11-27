library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity receptor_cubo_virtual_tb is
end entity;

architecture tb of receptor_cubo_virtual_tb is

    -- Declaração de sinais para conectar o componente a ser testado (DUT)
    signal clock_in             : std_logic  := '0';
    signal reset_in             : std_logic  := '0';
    -- saidas
    signal pronto_out           : std_logic  := '0';
    signal distancia_cubo_int   : std_logic_vector( 9 downto 0);
    signal distancia_cubo_BCD   : std_logic_vector(15 downto 0);

    -- para procedimento UART_WRITE_BYTE
    signal entrada_serial_in    : std_logic := '1';
    signal serialData           : std_logic_vector(7 downto 0) := "00000000";
  
    -- Configurações do clock
    constant clockPeriod : time := 20 ns;            -- 50MHz
    -- constant bitPeriod   : time := 5208*clockPeriod; -- 5208 clocks por bit (9.600 bauds)
    constant bitPeriod   : time := 434*clockPeriod;  -- 434 clocks por bit (115.200 bauds)
    
    ---- UART_WRITE_BYTE()
    -- Procedimento para geracao da sequencia de comunicacao serial 8N2
    -- adaptacao de codigo acessado de:
    -- https://www.nandland.com/goboard/uart-go-board-project-part1.html
    procedure UART_WRITE_BYTE (
        Data_In : in  std_logic_vector(7 downto 0);
        signal Serial_Out : out std_logic ) is
    begin
  
        -- envia Start Bit
        Serial_Out <= '0';
        wait for bitPeriod;
  
        -- envia 8 bits seriais (dados + paridade)
        for ii in 0 to 7 loop
            Serial_Out <= Data_In(ii);
            wait for bitPeriod;
        end loop;  -- loop ii
  
        -- envia 2 Stop Bits
        Serial_Out <= '1';
        wait for 2*bitPeriod;
  
    end UART_WRITE_BYTE;
    -- fim procedure
  
    ---- Array de casos de teste
    type caso_teste_type is record
        id   : natural;
        data : std_logic_vector(7 downto 0);     
    end record;
  
    type casos_teste_array is array (natural range <>) of caso_teste_type;
    constant casos_teste : casos_teste_array :=
        (
            ( 1, "10110001"), -- c11 (paridade=1 + dado=1)
            ( 2, "00110000"), -- c12 (paridade=0 + dado=0)
            ( 3, "10110010"), -- c13 (paridade=1 + dado=2)
            ( 4, "10100011"), -- #   (paridade=1 + dado=,)
            ( 5, "00110011"), -- c21 (paridade=1 + dado=3)
            ( 6, "10110100"), -- c22 (paridade=0 + dado=4)
            ( 7, "00110101"), -- c23 (paridade=1 + dado=5)
            ( 8, "10100011"), -- #   (paridade=1 + dado=,)
            ( 9, "00110110"), -- c31 (paridade=1 + dado=6)
            (10, "10110111"), -- c32 (paridade=0 + dado=7)
            (11, "10111000"), -- c33 (paridade=1 + dado=8)
            (12, "10100011")  -- #   (paridade=1 + dado=,)
        );
    signal caso : natural;
  
    ---- controle do clock e simulacao
    signal keep_simulating: std_logic := '0'; -- delimita o tempo de gera��o do clock
  
  
begin
 
    ---- Gerador de Clock
    clock_in <= (not clock_in) and keep_simulating after clockPeriod/2;
    
    -- Instanciação direta DUT (Device Under Test)
    DUT: entity work.receptor_cubo_virtual
        port map (
            clock       => clock_in, 
            reset       => reset_in,
            dado_serial => entrada_serial_in,
    
            pronto      => pronto_out,
            distancia_cubo_int  => distancia_cubo_int,
            distancia_cubo_BCD  => distancia_cubo_BCD
        );
    
    ---- Geracao dos sinais de entrada (estimulo)
    stimulus: process is
    begin
    
        ---- inicio da simulacao
        assert false report "inicio da simulacao" severity note;
        keep_simulating <= '1';
        -- reset com 5 periodos de clock
        reset_in <= '0';
        -- wait for bitPeriod;
        reset_in <= '1', '0' after 5*clockPeriod; 
        wait for bitPeriod;
      
        ---- loop pelos casos de teste
        for i in casos_teste'range loop
            caso <= casos_teste(i).id;
            assert false report "Caso de teste " & integer'image(casos_teste(i).id) severity note;
            serialData <= casos_teste(i).data; -- caso de teste "i"
            -- aguarda 2 periodos de bit antes de enviar bits
            wait for 2*bitPeriod;
      
            -- 1) envia bits seriais para circuito de recepcao
            UART_WRITE_BYTE ( Data_In=>serialData, Serial_Out=>entrada_serial_in );
            entrada_serial_in <= '1'; -- repouso
            wait for bitPeriod;
      
            -- 2) intervalo entre casos de teste
            wait for 2*bitPeriod;
        end loop;
      
        ---- final dos casos de teste da simulacao
        -- reset
        reset_in <= '0';
        wait for bitPeriod;
        reset_in <= '1', '0' after 5*clockPeriod; 
        wait for bitPeriod;
      
        ---- final da simulacao
        assert false report "fim da simulacao" severity note;
        keep_simulating <= '0';
        
        wait; -- fim da simulação: aguarda indefinidamente
    
    end process stimulus;

end architecture tb;