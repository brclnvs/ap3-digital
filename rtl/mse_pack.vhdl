library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

package mse_pack is

    ---------------------------------------------------------------------------
    -- Funções auxiliares de largura de barramentos
    ---------------------------------------------------------------------------

    -- Largura da diferença com sinal: pixel_a - pixel_b.
    -- Pixels de N bits unsigned → diferença varia de -(2^N-1) a +(2^N-1),
    -- precisando de N+1 bits signed.
    function diff_width(bits_per_sample : positive) return positive;

    -- Largura do quadrado da diferença.
    -- |diff| ≤ 2^N - 1  →  diff² ≤ (2^N-1)² < 2^(2N)  →  2N bits unsigned.
    function square_width(bits_per_sample : positive) return positive;

    -- Largura do acumulador: soma de n_pixels quadrados de square_width bits.
    -- Cresce ceil(log2(n_pixels)) bits além do quadrado.
    function acc_width(bits_per_sample : positive; n_pixels : positive)
    return positive;

    -- Largura fixa da saída mse_out: 16 bits conforme diagrama.
    function mse_out_width return positive;

    ---------------------------------------------------------------------------
    -- Barramentos de controle e status (BC ↔ BO)
    ---------------------------------------------------------------------------

    -- Sinais gerados pelo BC e enviados ao BO.
    type mse_control_t is record
        clr_acc  : std_logic; -- zera o acumulador
        en_acc   : std_logic; -- habilita acumulação
        clr_cnt  : std_logic; -- zera o contador de pixels
        inc_cnt  : std_logic; -- incrementa o contador
        load_mse : std_logic; -- carrega resultado normalizado em mse_out
    end record;

    -- Sinais gerados pelo BO e enviados ao BC.
    type mse_status_t is record
        cnt_done : std_logic; -- contador atingiu N_PIXELS - 1
    end record;

    ---------------------------------------------------------------------------
    -- Lookup table de quadrados
    -- Índice: valor absoluto da diferença (0 a 255, para pixels de 8 bits)
    -- Conteúdo: índice², representado em 16 bits unsigned
    ---------------------------------------------------------------------------

    constant LUT_SIZE : positive := 256;
    type square_lut_t is array (0 to LUT_SIZE - 1) of unsigned(15 downto 0);

    -- Inicializa a LUT em tempo de elaboração: lut(i) = i²
    function init_square_lut return square_lut_t;

end package mse_pack;


package body mse_pack is

    function diff_width(bits_per_sample : positive) return positive is
    begin
        return bits_per_sample + 1;
    end function;

    function square_width(bits_per_sample : positive) return positive is
    begin
        return 2 * bits_per_sample;
    end function;

    function acc_width(bits_per_sample : positive; n_pixels : positive)
    return positive is
    begin
        return square_width(bits_per_sample)
               + integer(ceil(log2(real(n_pixels))));
    end function;

    function mse_out_width return positive is
    begin
        return 16;
    end function;

    function init_square_lut return square_lut_t is
        variable lut : square_lut_t;
    begin
        for i in 0 to LUT_SIZE - 1 loop
            lut(i) := to_unsigned(i * i, 16);
        end loop;
        return lut;
    end function;

end package body mse_pack;
