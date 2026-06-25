library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.mse_pack.all;

entity mse_bo_lut is
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
end entity mse_bo_lut;

architecture structure of mse_bo_lut is

    constant DIFF_W   : positive := diff_width(BITS_PER_SAMPLE);
    constant SQUARE_W : positive := square_width(BITS_PER_SAMPLE);
    constant ACC_W    : positive := acc_width(BITS_PER_SAMPLE, N_PIXELS);
    constant OUT_W    : positive := mse_out_width;

    signal diff       : signed(DIFF_W - 1 downto 0);
    signal square     : unsigned(SQUARE_W - 1 downto 0);
    signal acc_d      : unsigned(ACC_W - 1 downto 0);
    signal acc_q      : unsigned(ACC_W - 1 downto 0);
    signal cnt_d      : unsigned(ACC_W - 1 downto 0);
    signal cnt_q      : unsigned(ACC_W - 1 downto 0);
    signal mse_next   : unsigned(ACC_W - 1 downto 0);
    signal mse_d      : unsigned(OUT_W - 1 downto 0);
    signal mse_q      : unsigned(OUT_W - 1 downto 0);

begin

    ---------------------------------------------------------------------------
    -- Subtrator (idêntico ao mse_bo_mult)
    ---------------------------------------------------------------------------
    sub_i : entity work.signed_subtractor
        generic map(N => DIFF_W)
        port map(
            input_a    => signed(resize(unsigned(pixel_a_in), DIFF_W)),
            input_b    => signed(resize(unsigned(pixel_b_in), DIFF_W)),
            difference => diff
        );

    ---------------------------------------------------------------------------
    -- Quadrador: Alternativa 2 — lookup table
    ---------------------------------------------------------------------------
    sq_i : entity work.square_lut
        generic map(
            DIFF_W   => DIFF_W,
            SQUARE_W => SQUARE_W
        )
        port map(
            diff   => diff,
            square => square
        );

    ---------------------------------------------------------------------------
    -- Acumulador (idêntico ao mse_bo_mult)
    ---------------------------------------------------------------------------
    acc_d <= (others => '0')               when control.clr_acc = '1' else
             acc_q + resize(square, ACC_W)  when control.en_acc  = '1' else
             acc_q;

    reg_acc : entity work.unsigned_register
        generic map(N => ACC_W)
        port map(clk => clk, enable => '1', d => acc_d, q => acc_q);

    ---------------------------------------------------------------------------
    -- Contador (idêntico ao mse_bo_mult)
    ---------------------------------------------------------------------------
    cnt_d <= (others => '0') when control.clr_cnt = '1' else
             cnt_q + 1        when control.inc_cnt = '1' else
             cnt_q;

    reg_cnt : entity work.unsigned_register
        generic map(N => ACC_W)
        port map(clk => clk, enable => '1', d => cnt_d, q => cnt_q);

    status.cnt_done <= '1' when cnt_q = to_unsigned(N_PIXELS - 1, ACC_W)
                       else '0';

    ---------------------------------------------------------------------------
    -- Normalizador e registrador de saída (idênticos ao mse_bo_mult)
    ---------------------------------------------------------------------------
    mse_next <= acc_q / to_unsigned(N_PIXELS, ACC_W);
    mse_d    <= resize(mse_next, OUT_W);

    reg_mse : entity work.unsigned_register
        generic map(N => OUT_W)
        port map(clk => clk, enable => control.load_mse, d => mse_d, q => mse_q);

    mse_out <= std_logic_vector(mse_q);

end architecture structure;
