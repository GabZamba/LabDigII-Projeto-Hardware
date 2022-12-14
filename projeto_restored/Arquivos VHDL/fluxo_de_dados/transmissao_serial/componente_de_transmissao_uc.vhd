library ieee;
use ieee.std_logic_1164.all;


entity componente_de_transmissao_uc is 
    port ( 
        clock       : in  std_logic;
        reset       : in  std_logic;
        partida     : in  std_logic;
        tx_feita    : in  std_logic;
        fim_mux_tx  : in  std_logic;

        conta_mux_tx        : out std_logic;
        zera_contador_tx    : out std_logic;
        partida_tx          : out std_logic;
        pronto              : out std_logic
    );
end entity;


architecture fsm_arch of componente_de_transmissao_uc is

    type tipo_estado is (
        inicial, preparacao,
        inicia_transmissao, aguarda_transmissao, 
        incrementa_mux_tx,
        final
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
    process (partida, fim_mux_tx, tx_feita, Eatual) 

    begin

        case Eatual is
            when inicial                            =>  
                if      partida='1'         then        Eprox <= preparacao;
                else                                    Eprox <= inicial;
                end if;
            when preparacao                         =>  Eprox <= inicia_transmissao;

            when inicia_transmissao                 =>  Eprox <= aguarda_transmissao;

            when aguarda_transmissao                =>  
                if      tx_feita='0'        then        Eprox <= aguarda_transmissao;
                elsif   fim_mux_tx='0'      then        Eprox <= incrementa_mux_tx;
                else                                    Eprox <= final;
                end if;

            when incrementa_mux_tx                  =>  Eprox <= inicia_transmissao;

            when final                              =>  Eprox <= inicial;

            when others                             =>  Eprox <= inicial;

        end case;

    end process;

  -- saidas de controle 
    with Eatual select
        zera_contador_tx    <= '1' when preparacao, '0' when others;

    with Eatual select
        partida_tx          <= '1' when inicia_transmissao, '0' when others;
    
    with Eatual select 
        conta_mux_tx        <= '1' when incrementa_mux_tx, '0' when others;

    with Eatual select 
        pronto              <= '1' when final, '0' when others;

end architecture fsm_arch;
