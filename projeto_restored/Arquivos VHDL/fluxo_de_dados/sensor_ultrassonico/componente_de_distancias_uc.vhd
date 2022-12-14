library ieee;
use ieee.std_logic_1164.all;


entity componente_de_distancias_uc is 
    port (
        clock               : in  std_logic;
        reset               : in  std_logic;
        fim_medida          : in  std_logic;
        fim_contador_medida : in  std_logic;
        fim_timer_20ms      : in  std_logic;
        fim_timer_distMax   : in  std_logic;

        zera                : out std_logic;
        zera_timer_distMax  : out std_logic;
        pulso_medir         : out std_logic;
        registra_medida     : out std_logic;
        registra_final      : out std_logic;
        conta_20ms          : out std_logic;
        conta_medida        : out std_logic;
        pronto              : out std_logic
    );
end entity;


architecture fsm_arch of componente_de_distancias_uc is

    type tipo_estado is (
        inicial,
        gera_pulso_medida, aguarda_fim_medida,
        registra_medida_realizada, verifica_fim_medidas,
        incrementa_contador_medida, espera_20ms,
        registra_medida_final, final, espera_20ms_fim
    );

    signal Eatual, Eprox: tipo_estado;

begin

    -- estado
    process (reset, clock)
    begin
        if reset = '1' then
            Eatual <= inicial;
        elsif clock'event and clock = '1' then
            Eatual <= Eprox; 
        end if;
    end process;

    -- logica de proximo estado
    process (fim_medida, fim_contador_medida, fim_timer_20ms, fim_timer_distMax, Eatual) 
    begin

        case Eatual is

            when inicial                    =>      Eprox <= gera_pulso_medida;

            when gera_pulso_medida =>               Eprox <= aguarda_fim_medida;

            when aguarda_fim_medida =>  
                if fim_medida='1' then              Eprox <= registra_medida_realizada;
                elsif fim_timer_distMax='1' then    Eprox <= verifica_fim_medidas;
                else                                Eprox <= aguarda_fim_medida;
                end if;

            when registra_medida_realizada  =>      Eprox <= verifica_fim_medidas;

            when verifica_fim_medidas =>  
                if fim_contador_medida='1' then     Eprox <= registra_medida_final;
                else                                Eprox <= incrementa_contador_medida;
                end if;
            
            when incrementa_contador_medida =>      Eprox <= espera_20ms;

            when espera_20ms =>
                if fim_timer_20ms='1' then          Eprox <= gera_pulso_medida;
                else                                Eprox <= espera_20ms;
                end if;

            when registra_medida_final      =>      Eprox <= final;

            when final                      =>      Eprox <= espera_20ms_fim;

            when espera_20ms_fim =>
                if fim_timer_20ms='1' then          Eprox <= inicial;
                else                                Eprox <= espera_20ms_fim;
                end if;

            when others                     =>      Eprox <= inicial;

        end case;

    end process;

  -- saidas de controle

    with Eatual select 
        zera                <= '1' when inicial, '0' when others;

    with Eatual select 
        pulso_medir         <= '1' when gera_pulso_medida, '0' when others;
    with Eatual select
        zera_timer_distMax  <= '1' when gera_pulso_medida, '0' when others;   

    with Eatual select
        registra_medida     <= '1' when registra_medida_realizada, '0' when others;  

    with Eatual select
        conta_medida        <= '1' when incrementa_contador_medida, '0' when others;  

    with Eatual select
        conta_20ms          <= '1' when espera_20ms, '1' when espera_20ms_fim, '0' when others;  

    with Eatual select
        registra_final      <= '1' when registra_medida_final, '0' when others;    

    with Eatual select
        pronto              <= '1' when final, '0' when others;   


end architecture fsm_arch;
