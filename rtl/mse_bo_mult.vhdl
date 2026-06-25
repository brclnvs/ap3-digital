library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.mse_pack.all;

entity mse_bo_mult is
    generic(
        N_PIXELS        : positive := 64;
        BITS_PER_SAMPLE : positive := 8
    );
    port(
        clk        : in  std_logic;
        rst        : in  std_logic;
        control    : in  mse_control_t;
        pixel_a_in : in  std_logic_vector(BITS_PER_SAMPLE - 1 downto 0);
        pixel_b_in : in  std_logic_vector(BITS_PER_SAMPLE - 1 downto 0);
        status     : out mse_status_t;
        mse_out    : out std_logic_vector(mse_out_width - 1 downto 0)
    );
end entity mse_bo_mult;

architecture structure of mse_bo_mult is

    ---------------------------------------------------------------------------
    -- Constantes locais
    ---------------------------------------------------------------------------
    constant DIFF_W   : positive := diff_width(BITS_PER_SAMPLE);
    constant SQUARE_W : positive := square_width(BITS_PER_SAMPLE);
    constant ACC_W    : positive := acc_width(BITS_PER_SAMPLE, N_PIXELS);
    constant OUT_W    : positive := mse_out_width;

    ---------------------------------------------------------------------------
    -- Sinais internos
    ---------------------------------------------------------------------------

    -- Subtrator
    signal diff       : signed(DIFF_W - 1 downto 0);

    -- Quadrador
    signal square     : unsigned(SQUARE_W - 1 downto 0);

    -- Acumulador
    signal acc_d      : unsigned(ACC_W - 1 downto 0);
    signal acc_q      : unsigned(ACC_W - 1 downto 0);

    -- Contador
    signal cnt_d      : unsigned(ACC_W - 1 downto 0);
    signal cnt_q      : unsigned(ACC_W - 1 downto 0);

    -- Normalizador e saída
    signal mse_next   : unsigned(ACC_W - 1 downto 0);
    signal mse_d      : unsigned(OUT_W - 1 downto 0);
    signal mse_q      : unsigned(OUT_W - 1 downto 0);

begin

    ---------------------------------------------------------------------------
    -- Subtrator com sinal: diff = signed(pixel_a) - signed(pixel_b)
    -- Extende de N bits unsigned para N+1 bits signed antes de subtrair
    ---------------------------------------------------------------------------
    sub_i : entity work.signed_subtractor
        generic map(N => DIFF_W)
        port map(
            input_a    => signed(resize(unsigned(pixel_a_in), DIFF_W)),
            input_b    => signed(resize(unsigned(pixel_b_in), DIFF_W)),
            difference => diff
        );

    ---------------------------------------------------------------------------
    -- Quadrador: Alternativa 1 — multiplicador
    ---------------------------------------------------------------------------
    sq_i : entity work.square_mult
        generic map(
            DIFF_W   => DIFF_W,
            SQUARE_W => SQUARE_W
        )
        port map(
            diff   => diff,
            square => square
        );

    ---------------------------------------------------------------------------
    -- Acumulador: acc ← 0 (clr) | acc + square (en) | acc (hold)
    ---------------------------------------------------------------------------
    acc_d <= (others => '0')              when control.clr_acc = '1' else
             acc_q + resize(square, ACC_W) when control.en_acc  = '1' else
             acc_q;

    reg_acc : entity work.unsigned_register
        generic map(N => ACC_W)
        port map(
            clk    => clk,
            enable => '1',      -- sempre registra (mux antes do reg)
            d      => acc_d,
            q      => acc_q
        );

    ---------------------------------------------------------------------------
    -- Contador de pixels: cnt ← 0 (clr) | cnt + 1 (inc) | cnt (hold)
    ---------------------------------------------------------------------------
    cnt_d <= (others => '0') when control.clr_cnt = '1' else
             cnt_q + 1        when control.inc_cnt = '1' else
             cnt_q;

    reg_cnt : entity work.unsigned_register
        generic map(N => ACC_W)
        port map(
            clk    => clk,
            enable => '1',
            d      => cnt_d,
            q      => cnt_q
        );

    -- Sinal de status: contador atingiu o último pixel
    status.cnt_done <= '1' when cnt_q = to_unsigned(N_PIXELS - 1, ACC_W)
                       else '0';

p_mse_reg : process(clk, rst)
begin
    if rst = '1' then
        mse_q <= (others => '0');
    elsif rising_edge(clk) then
        if control.load_mse = '1' then
            mse_q <= resize(acc_q / to_unsigned(N_PIXELS, ACC_W), OUT_W);
        end if;
    end if;
end process p_mse_reg;

mse_out <= std_logic_vector(mse_q);

end architecture structure;
