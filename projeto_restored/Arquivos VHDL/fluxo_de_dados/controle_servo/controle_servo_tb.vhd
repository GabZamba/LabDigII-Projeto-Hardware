-- controle_servo_tb
--
library ieee;
use ieee.std_logic_1164.all;

entity controle_servo_tb is
end entity;

architecture tb of controle_servo_tb is
  
    -- Componente a ser testado (Device Under Test -- DUT)
    component controle_servo is
        port (
            clock             : in  std_logic;
            reset             : in  std_logic;
            posicao_servo     : in  std_logic_vector (9 downto 0);
            controle          : out std_logic
        );
    end component;
    
    -- Declaração de sinais para conectar o componente a ser testado (DUT)
    --   valores iniciais para fins de simulacao (GHDL ou ModelSim)
    signal clock_in     : std_logic := '0';
    signal reset_in     : std_logic := '0';
    signal posicao_in   : std_logic_vector (9 downto 0) := "0000000000";
    signal controle_out : std_logic := '0';


    -- Configurações do clock
    signal keep_simulating : std_logic := '0'; -- delimita o tempo de geração do clock
    constant clockPeriod   : time := 20 ns;
  
begin
    -- Gerador de clock: executa enquanto 'keep_simulating = 1', com o período
    -- especificado. Quando keep_simulating=0, clock é interrompido, bem como a 
    -- simulação de eventos
    clock_in <= (not clock_in) and keep_simulating after clockPeriod/2;

    
    -- Conecta DUT (Device Under Test)
    dut: controle_servo 
        port map ( 
            clock     => clock_in,
            reset     => reset_in,
            posicao_servo   => posicao_in,
            controle  => controle_out
        );

    -- geracao dos sinais de entrada (estimulos)
    stimulus: process is
    begin
    
        assert false report "Inicio da simulacao" & LF & "... Simulacao ate 800 ms. Aguarde o final da simulacao..." severity note;
        keep_simulating <= '1';
        
        ---- inicio: reset ----------------
        reset_in <= '1'; 
        wait for 2*clockPeriod;
        reset_in <= '0';
        wait for 2*clockPeriod;

        ---- casos de teste
        posicao_in <= "0000000000";
        wait for 200 ms;


        posicao_in <= "0010000000";
        wait for 200 ms;


        posicao_in <= "0100000000";
        wait for 200 ms;

        posicao_in <= "1000000000";
        wait for 200 ms;

        
        posicao_in <= "1100000000"; 
        wait for 200 ms;

        ---- final dos casos de teste  da simulacao
        assert false report "Fim da simulacao" severity note;
        keep_simulating <= '0';
        
        wait; -- fim da simulação: aguarda indefinidamente
    end process;


end architecture;