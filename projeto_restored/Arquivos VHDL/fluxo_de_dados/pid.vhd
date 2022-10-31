library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity pid is
    port (
        clock            : in  std_logic; -- Periodo de 10 ms
		equilibrio		 : in  std_logic_vector (9 downto 0);
        entrada_sensor   : in  std_logic_vector (9 downto 0); 
        saida_servo      : out std_logic_vector (9 downto 0) 
    );
end pid;
architecture behavioral of pid is
    type estados is (Inicial,
			CalculaNovoErro,
			CalculaTermosPID,
			DivideTermosPID,                              
			SobrepoeSaida,
			ConverteSaida,
			EscreveSaida
		);	                             
    
    signal state, next_state 	: estados := Inicial;

	-- Utilizando valores inteiros para as constantes, para se obter o valor real, deve-se dividir por 100 os seus respectivos valores
    signal Kp 					: integer := 50; 
    signal Kd 					: integer := 0;
    signal Ki 					: integer := 0;

    signal saida 				: integer := 256; -- servo motor em posição de equílibrio para a bolinha	
    signal erro					: integer := 0;		
    signal entrada_valor 		: integer := 0 ;
    signal p,i,d 				: integer := 0;
    signal saida_vetor 			: std_logic_vector (9 downto 0);
    
begin
	entrada_valor 		<= to_integer(unsigned(entrada_sensor));
	equilibrio_valor 	<= to_integer(unsigned(equilibrio));

	process(clock,state)
    
	variable saida_antiga 	: integer := 0;   
    variable erro_antigo 	: integer := 0;
	variable erro_acumulado	: integer := 0;
    
	begin	 
        if clock'event and clock='1' then  
			state <= next_state;
        end if;
        case state is
			when Inicial =>
				next_state 		<= CalculaNovoErro;
				erro_antigo 	:= erro;
				saida_antiga 	:= saida;
				erro_acumulado	:= erro_acumulado+erro;
				
		  	when CalculaNovoErro =>  
				next_state 	<= CalculaTermosPID;
				erro 		<= (equilibrio_valor-entrada_valor);
		  
		  	when CalculaTermosPID =>
				next_state 	<= DivideTermosPID;
				p 			<= Kp*(erro); 
				i 			<= Ki*(erro+erro_acumulado);
				d 			<= Kd*(erro-erro_antigo)/100; -- dividindo pelo tempo que decorreu entre as amostras                     
				
		  	when DivideTermosPID =>
				next_state <= SobrepoeSaida;
				saida <=  saida_antiga+(p+i+d)/100; -- Obtendo os valores reais para Kp Kd e Ki 
		  
		  	when SobrepoeSaida =>
				next_state <=ConverteSaida;	
				if saida >= 512 then
				 	saida <= 511 ;
				end if;     
				if saida < 0 then 
					saida <= 0;
				end if;
				
		  	when ConverteSaida =>
				saida_vetor <= std_logic_vector(to_unsigned(saida ,9));
				next_state <=EscreveSaida;
			
		  	when EscreveSaida =>
				next_state <= Inicial;
				saida_servo <= saida_vetor;
	 	end case;
    end process;
end behavioral;