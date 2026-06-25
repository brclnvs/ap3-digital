library ieee;
use ieee.std_logic_1164.all;
use work.mse_pack.all;

entity mse_bc is
    port(
        clk     : in  std_logic;
        rst     : in  std_logic;
        start   : in  std_logic;
        status  : in  mse_status_t;
        control : out mse_control_t;
        busy    : out std_logic;
        done   : out std_logic
    );
end entity mse_bc;

architecture behavior of mse_bc is

    type state_t is (IDLE, INIT, ACCUM, DIVIDE, DONE_ST);
    signal current_state, next_state : state_t;

begin

    -- Registro de estado
    p_reg : process(clk, rst)
    begin
        if rst = '1' then
            current_state <= IDLE;
        elsif rising_edge(clk) then
            current_state <= next_state;
        end if;
    end process p_reg;

    -- Lógica de próximo estado
    p_next : process(current_state, start, status)
    begin
        next_state <= current_state;
        case current_state is
            when IDLE   =>
                if start = '1' then next_state <= INIT; end if;
            when INIT   =>
                next_state <= ACCUM;
            when ACCUM  =>
                if status.cnt_done = '1' then next_state <= DIVIDE; end if;
            when DIVIDE =>
                next_state <= DONE_ST;
            when DONE_ST   =>
                if start = '0' then next_state <= IDLE; end if;
        end case;
    end process p_next;

    -- Saídas de Moore
    p_out : process(current_state)
    begin
        -- padrão: tudo desativado
        control.clr_acc  <= '0';
        control.en_acc   <= '0';
        control.clr_cnt  <= '0';
        control.inc_cnt  <= '0';
        control.load_mse <= '0';
        busy             <= '0';
        done          <= '0';

        case current_state is
            when IDLE =>
                null; -- tudo já em zero

            when INIT =>
                busy            <= '1';
                control.clr_acc <= '1';
                control.clr_cnt <= '1';

            when ACCUM =>
                busy            <= '1';
                control.en_acc  <= '1';
                control.inc_cnt <= '1';

            when DIVIDE =>
                busy             <= '1';
                control.load_mse <= '1';

            when DONE_ST =>
                done <= '1';
        end case;
    end process p_out;

end architecture behavior;
