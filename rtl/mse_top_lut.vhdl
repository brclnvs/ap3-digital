library ieee;
use ieee.std_logic_1164.all;
use work.mse_pack.all;

entity mse_top_lut is
    generic(
        N_PIXELS        : positive := 64;
        BITS_PER_SAMPLE : positive := 8
    );
    port(
        clk        : in  std_logic;
        rst        : in  std_logic;
        start      : in  std_logic;
        pixel_a_in : in  std_logic_vector(BITS_PER_SAMPLE - 1 downto 0);
        pixel_b_in : in  std_logic_vector(BITS_PER_SAMPLE - 1 downto 0);
        mse_out    : out std_logic_vector(mse_out_width - 1 downto 0);
        busy       : out std_logic;
        done       : out std_logic
    );
end entity mse_top_lut;

architecture structure of mse_top_lut is
    signal control_s : mse_control_t;
    signal status_s  : mse_status_t;
begin

    bc_i : entity work.mse_bc
        port map(
            clk     => clk,
            rst     => rst,
            start   => start,
            status  => status_s,
            control => control_s,
            busy    => busy,
            done    => done
        );

    bo_i : entity work.mse_bo_lut
        generic map(
            N_PIXELS        => N_PIXELS,
            BITS_PER_SAMPLE => BITS_PER_SAMPLE
        )
        port map(
            clk        => clk,
            rst        => rst,
            control    => control_s,
            pixel_a_in => pixel_a_in,
            pixel_b_in => pixel_b_in,
            status     => status_s,
            mse_out    => mse_out
        );

end architecture structure;
