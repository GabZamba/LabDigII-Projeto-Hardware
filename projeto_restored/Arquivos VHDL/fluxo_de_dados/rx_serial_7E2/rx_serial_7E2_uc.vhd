library ieee;
use ieee.std_logic_1164.all;

entity rx_serial_7E2_uc is 
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
end entity;

architecture rx_serial_7E2_uc_arch of rx_serial_7E2_uc is

    type tipo_estado is (inicial, preparacao, espera, recebe, armazenamento, final, dado_presente);
    signal Eatual: tipo_estado;  -- estado atual
    signal Eprox:  tipo_estado;  -- proximo estado

begin

  -- memoria de estado
    process (reset, clock)
    begin
        if reset = '1' then
            Eatual <= inicial;
        elsif clock'event and clock = '1' then
            Eatual <= Eprox; 
        end if;
    end process;

    -- logica de proximo estado

    process (dado_serial, tick_meio, fim, Eatual) 
    begin

        case Eatual is

            when inicial =>
                if dado_serial='0' then Eprox <= preparacao;
                else                    Eprox <= inicial;
                end if;

            when preparacao =>   
                Eprox <= espera;
            
            when espera =>
                if tick_meio='1' then   Eprox <= recebe;
                elsif   fim='1' then    Eprox <= armazenamento;
                else                    Eprox <= espera;
                end if;

            when recebe =>   
                Eprox <= espera;
            
            when armazenamento =>
                Eprox <= final;
            
            when final =>
                Eprox <= dado_presente;
            
            when dado_presente 	=>
                if dado_serial='0' then Eprox <= preparacao;
                else                    Eprox <= dado_presente;
                end if;
            
            when others =>
                Eprox <= inicial;

        end case;

    end process;

    -- logica de saida (Moore)

    with Eatual select
        zera	    <= '1' when preparacao, '0' when others;

    with Eatual select
        desloca	    <= '1' when recebe, '0' when others;

    with Eatual select
        conta_rx 	<= '1' when recebe, '0' when others;

    with Eatual select
        registra    <= '1' when armazenamento, '0' when others;

    with Eatual select
        pronto 	    <= '1' when final, '0' when others;

    with Eatual select
        tem_dado    <= '1' when dado_presente, '0' when others;

    with Eatual select
        db_estado   <=  "0001" when inicial,        -- 1
                        "0010" when preparacao,     -- 2
                        "0011" when espera,         -- 3
                        "0100" when recebe,         -- 4
                        "0101" when armazenamento,  -- 5
                        "0110" when final,          -- 6
                        "0111" when dado_presente,  -- 7
                        "1111" when others;         -- F



end architecture rx_serial_7E2_uc_arch;
