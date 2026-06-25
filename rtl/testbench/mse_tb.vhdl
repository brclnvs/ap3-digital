library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.mse_pack.all;

entity mse_tb is
end entity mse_tb;

architecture sim of mse_tb is

    constant N_PIX      : positive := 4;
    constant BPS        : positive := 10;
    constant CLK_PERIOD : time     := 10 ns;
    constant OUT_W      : positive := mse_out_width;

    signal clk      : std_logic := '0';
    signal rst      : std_logic := '0';
    signal start    : std_logic := '0';
    signal pixel_a  : std_logic_vector(BPS - 1 downto 0) := (others => '0');
    signal pixel_b  : std_logic_vector(BPS - 1 downto 0) := (others => '0');

    signal mse_mult : std_logic_vector(OUT_W - 1 downto 0);
    signal busy_m   : std_logic;
    signal done_m   : std_logic;

    signal mse_lut  : std_logic_vector(OUT_W - 1 downto 0);
    signal busy_l   : std_logic;
    signal done_l   : std_logic;

    type pixel_vec_t is array (0 to N_PIX - 1) of natural;

begin

    clk <= not clk after CLK_PERIOD / 2;

    dut_mult : entity work.mse_top_mult
        generic map(N_PIXELS => N_PIX, BITS_PER_SAMPLE => BPS)
        port map(
            clk        => clk, rst => rst, start => start,
            pixel_a_in => pixel_a, pixel_b_in => pixel_b,
            mse_out    => mse_mult, busy => busy_m, done => done_m
        );

    dut_lut : entity work.mse_top_lut
        generic map(N_PIXELS => N_PIX, BITS_PER_SAMPLE => BPS)
        port map(
            clk        => clk, rst => rst, start => start,
            pixel_a_in => pixel_a, pixel_b_in => pixel_b,
            mse_out    => mse_lut, busy => busy_l, done => done_l
        );

    p_stim : process

        procedure run_test(
            label    : string;
            pa, pb   : pixel_vec_t;
            expected : natural
        ) is
            variable r_mult, r_lut : natural;
        begin
            report "--- " & label & " ---" severity note;
            
            -- 1. Reset correto do sistema
            rst <= '1';
            wait for 2 * CLK_PERIOD;
            rst <= '0'; 
            wait for CLK_PERIOD;

            -- 2. APENAS UM pulso de start
            start <= '1';
            wait for CLK_PERIOD;
            start <= '0';

            -- 3. Aguarda exatamente a transição IDLE -> INIT -> ACCUM (2 ciclos)
            wait for 2 * CLK_PERIOD; 

            -- 4. Alimenta N_PIX pares de pixels perfeitamente alinhados com o clock
            for i in 0 to N_PIX - 1 loop
                pixel_a <= std_logic_vector(to_unsigned(pa(i), BPS));
                pixel_b <= std_logic_vector(to_unsigned(pb(i), BPS));
                wait for CLK_PERIOD;
            end loop;

            -- Aguarda done de ambos
            wait until done_m = '1' and done_l = '1';
            wait for CLK_PERIOD; -- garante estabilidade de mse_out

            r_mult := to_integer(unsigned(mse_mult));
            r_lut  := to_integer(unsigned(mse_lut));

            -- Verifica Alternativa 1
            assert r_mult = expected
                report "[MULT] FALHA: obtido=" & integer'image(r_mult)
                       & " esperado=" & integer'image(expected)
                severity error;
            if r_mult = expected then
                report "[MULT] OK: MSE=" & integer'image(r_mult) severity note;
            end if;

            -- Verifica Alternativa 2
            assert r_lut = expected
                report "[LUT] FALHA: obtido=" & integer'image(r_lut)
                       & " esperado=" & integer'image(expected)
                severity error;
            if r_lut = expected then
                report "[LUT]  OK: MSE=" & integer'image(r_lut) severity note;
            end if;

            -- Verifica consistência entre alternativas
            assert r_mult = r_lut
                report "[COMPARE] DIVERGENCIA: MULT=" & integer'image(r_mult)
                       & " LUT=" & integer'image(r_lut)
                severity error;

            wait for 3 * CLK_PERIOD;
        end procedure;

    begin
        pixel_a <= (others => '0');
        pixel_b <= (others => '0');
        wait for 2 * CLK_PERIOD;

        -- Caso 1: pixels idênticos → MSE = 0
        run_test("Caso 1: pixels identicos",
            pa => (100, 200, 50, 10),
            pb => (100, 200, 50, 10),
            expected => 0);

        -- Caso 2: diferença constante 1 → Σdiff²=4 → MSE=4/4=1
        run_test("Caso 2: diferenca=1",
            pa => (101, 201, 51, 11),
            pb => (100, 200, 50, 10),
            expected => 1);

        -- Caso 3: arbitrário → diffs=(10,-20,5,-3) → Σ=(100+400+25+9)=534 → MSE=133
        run_test("Caso 3: valores arbitrarios",
            pa => (110, 180, 55,  7),
            pb => (100, 200, 50, 10),
            expected => 133);

        -- Caso 4: diferença máxima → diff=255 → Σ=4*65025=260100 → MSE=65025
        run_test("Caso 4: diferenca maxima",
            pa => (255, 255, 255, 255),
            pb => (0,   0,   0,   0),
            expected => 65025);
            
        report "=== Testbench concluido ===" severity note;
        wait;
    end process p_stim;

end architecture sim;
