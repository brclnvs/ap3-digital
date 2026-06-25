library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity square_mult is
    generic(
        DIFF_W   : positive := 9;  -- largura da diferença (signed)
        SQUARE_W : positive := 16  -- largura do quadrado (unsigned)
    );
    port(
        diff   : in  signed(DIFF_W - 1 downto 0);
        square : out unsigned(SQUARE_W - 1 downto 0)
    );
end entity square_mult;

architecture behavior of square_mult is
begin
    -- diff * diff é sempre ≥ 0, então o cast para unsigned é seguro.
    -- O produto de dois signed(DIFF_W-1:0) tem 2*DIFF_W bits;
    -- truncamos para SQUARE_W bits (suficiente pois |diff| ≤ 255 → diff² ≤ 65025 < 2^16).
    square <= resize(unsigned(std_logic_vector(diff * diff)), SQUARE_W);
end architecture behavior;
