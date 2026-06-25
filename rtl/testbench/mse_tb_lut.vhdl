library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.mse_pack.all;

entity mse_tb_lut is
end entity mse_tb_lut;

architecture sim of mse_tb_lut is

    constant N_PIX      : positive := 4;
    constant BPS        : positive := 8;
    constant CLK_PERIOD : time     := 10 ns;
    constant OUT_W      : positive := mse_out_width;

    signal clk     : std_logic := '0';
    signal rst     : std_logic := '0';
    signal start   : std_logic := '0';
    signal pixel_a : std_logic_vector(BPS - 1 downto 0) := (others => '0');
    signal pixel_b : std_logic_vector(BPS - 1 downto 0) := (others => '0');
    signal mse_out : std_logic_vector(OUT_W - 1 downto 0);
    signal busy    : std_logic;
    signal done    : std_logic;

    type pixel_vec_t is array (0 to N_PIX - 1) of natural;

begin

    clk <= not clk after CLK_PERIOD / 2;

    dut : entity work.mse_top_lut
        generic map(N_PIXELS => N_PIX, BITS_PER_SAMPLE => BPS)
        port map(
            clk        => clk,
            rst        => rst,
            start      => start,
            pixel_a_in => pixel_a,
            pixel_b_in => pixel_b,
            mse_out    => mse_out,
            busy       => busy,
            done       => done
        );

    p_stim : process

        procedure run_test(
    test_name : string;
    pa, pb    : pixel_vec_t;
    expected  : natural
) is
    variable result : natural;
begin
    report "--- [LUT] " & test_name & " ---" severity note;

    -- Reset
    rst   <= '1'; wait for 2 * CLK_PERIOD;
    rst   <= '0'; wait for CLK_PERIOD;

-- Pulso de start (único)
    start <= '1'; 
    wait for CLK_PERIOD;
    start <= '0';
    
    -- Espera apenas 1 ciclo para o estado INIT 
    -- (No próximo ciclo a FSM já entra em ACCUM)
    wait for CLK_PERIOD;

    -- Alimenta pixels durante ACCUM
    for i in 0 to N_PIX - 1 loop
        pixel_a <= std_logic_vector(to_unsigned(pa(i), BPS));
        pixel_b <= std_logic_vector(to_unsigned(pb(i), BPS));
        wait for CLK_PERIOD;
    end loop;

    -- BLINDAGEM: Só entra no 'wait until' se o done ainda não tiver subido.
    -- Isso previne que a simulação trave se o hardware for mais rápido que o TB.
    if done = '0' then
        wait until done = '1';
    end if;
    wait for CLK_PERIOD;

    result := to_integer(unsigned(mse_out));

    assert result = expected
        report "FALHA: obtido=" & integer'image(result)
               & " esperado=" & integer'image(expected)
        severity error;

    if result = expected then
        report "OK: MSE=" & integer'image(result) severity note;
    end if;

    wait for 3 * CLK_PERIOD;
end procedure;

    begin
        pixel_a <= (others => '0');
        pixel_b <= (others => '0');
        wait for 2 * CLK_PERIOD;

        -- diffs=(0,0,0,0) → Σ=0 → MSE=0
        run_test("Caso 1: pixels identicos",
            pa => (100, 200,  50, 10),
            pb => (100, 200,  50, 10),
            expected => 0);

        -- diffs=(1,1,1,1) → Σ=4 → MSE=4/4=1
        run_test("Caso 2: diferenca constante 1",
            pa => (101, 201,  51, 11),
            pb => (100, 200,  50, 10),
            expected => 1);

        -- diffs=(10,-20,5,-3) → Σ=100+400+25+9=534 → MSE=534/4=133
        run_test("Caso 3: valores arbitrarios",
            pa => (110, 180,  55,  7),
            pb => (100, 200,  50, 10),
            expected => 133);

        -- diffs=(255,255,255,255) → Σ=4*65025=260100 → MSE=65025
        run_test("Caso 4: diferenca maxima",
            pa => (255, 255, 255, 255),
            pb => (  0,   0,   0,   0),
            expected => 65025);

        report "=== [LUT] Testbench concluido ===" severity note;
        wait;
    end process p_stim;

end architecture sim;
