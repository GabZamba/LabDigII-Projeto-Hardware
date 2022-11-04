library ieee;
use ieee.std_logic_1164.all;

entity projeto_uc is 
    port ( 
        clock               : in  std_logic;
        reset               : in  std_logic;
        ligar               : in  std_logic;
        fim_contador_tx     : in  std_logic;
        fim_medida_bola_x   : in  std_logic;
        tx_pronto           : in  std_logic;
        fim_timer_2s        : in  std_logic;

        conta_posicao_servo : out std_logic;
        zera_posicao_servo  : out std_logic;
        conta_tx            : out std_logic;
        zera_contador_tx    : out std_logic;
        distancia_medir     : out std_logic;
        tx_partida          : out std_logic;
        timer_zera          : out std_logic;

        db_estado           : out std_logic_vector(3 downto 0) 
    );
end projeto_uc;

architecture fsm_arch of projeto_uc is
    type tipo_estado is (
        inicial, preparacao, 
        zera_timer, espera_timer, 
        inicia_medicao, aguarda_medicao, 
        zera_contador_transmissao, inicia_transmissao, aguarda_transmissao, 
        move_servo_motor,
        incrementa_contador_transmissao
    );
    signal Eatual, Eprox: tipo_estado;
begin

    -- estado
    process (reset, clock, ligar)
    begin
        if reset = '1' or ligar = '0' then
            Eatual <= inicial;
        elsif clock'event and clock = '1' then
            Eatual <= Eprox; 
        end if;
    end process;

    -- logica de proximo estado
    process (ligar, fim_contador_tx, fim_medida_bola_x, tx_pronto, fim_timer_2s, Eatual) 
    begin
        case Eatual is
            when inicial                            =>  
                if ligar='1' then                       Eprox <= preparacao;
                else                                    Eprox <= inicial;
                end if;
            when preparacao                         =>  Eprox <= zera_timer;

            when zera_timer                         =>  Eprox <= espera_timer;
            when espera_timer                       =>  
                if fim_timer_2s='0' then                Eprox <= espera_timer;
                else                                    Eprox <= inicia_medicao;
                end if;

            when inicia_medicao                     =>  Eprox <= aguarda_medicao;
            when aguarda_medicao                    =>  
                if fim_medida_bola_x='0' then           Eprox <= aguarda_medicao;
                else                                    Eprox <= zera_contador_transmissao;
                end if;

            when zera_contador_transmissao          =>  Eprox <= inicia_transmissao;
            when inicia_transmissao                 =>  Eprox <= aguarda_transmissao;
            when aguarda_transmissao                =>  
                if tx_pronto='0' then                   Eprox <= aguarda_transmissao;
                elsif fim_contador_tx='0' then          Eprox <= incrementa_contador_transmissao;
                else                                    Eprox <= move_servo_motor;
                end if;

            when move_servo_motor                   =>  Eprox <= zera_timer;

            when incrementa_contador_transmissao    =>  Eprox <= inicia_transmissao;

            when others                             =>  Eprox <= inicial;
        end case;
    end process;

  -- saidas de controle
    with Eatual select
        zera_posicao_servo      <= '1' when preparacao, '0' when others;  

    with Eatual select
        timer_zera              <= '1' when zera_timer, '0' when others;

    with Eatual select
        distancia_medir         <= '1' when inicia_medicao, '0' when others;
    
    with Eatual select
        zera_contador_tx        <= '1' when zera_contador_transmissao, '0' when others;
    with Eatual select
        tx_partida              <= '1' when inicia_transmissao, '0' when others;
        
    with Eatual select 
        conta_posicao_servo     <= '1' when move_servo_motor, '0' when others;
    
    with Eatual select 
        conta_tx                <= '1' when incrementa_contador_transmissao, '0' when others;
    
    

    with Eatual select
        db_estado <=    
            "0000" when inicial,                            -- 0
            "0001" when preparacao,                         -- 1
            "0010" when zera_timer,                         -- 2
            "0011" when espera_timer,                       -- 3
            "0100" when inicia_medicao,                     -- 4
            "0101" when aguarda_medicao,                    -- 5
            "0110" when zera_contador_transmissao,          -- 6
            "0111" when inicia_transmissao,                 -- 7
            "1000" when aguarda_transmissao,                -- 8
            "1001" when incrementa_contador_transmissao,    -- 9
            "1010" when move_servo_motor,                   -- 10
            "1111" when others;                             -- F

end architecture fsm_arch;
