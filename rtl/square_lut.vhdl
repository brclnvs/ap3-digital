library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.mse_pack.all;

entity square_lut is
    generic(
        DIFF_W   : positive := 9;
        SQUARE_W : positive := 16
    );
    port(
        diff   : in  signed(DIFF_W - 1 downto 0);
        square : out unsigned(SQUARE_W - 1 downto 0)
    );
end entity square_lut;

architecture behavior of square_lut is

    -- ROM inicializada em tempo de elaboração via função do pacote
    constant SQUARE_ROM : square_lut_t := init_square_lut;

    -- Valor absoluto de diff para indexar a ROM (0..255)
    signal abs_diff : unsigned(DIFF_W - 2 downto 0); -- N bits suficientes

begin

    -- Calcula |diff|: se negativo, inverte; caso contrário usa direto.
    -- diff é signed(8:0); |diff| cabe em 8 bits (0..255).
    abs_diff <= unsigned(-diff(DIFF_W - 2 downto 0)) when diff(DIFF_W - 1) = '1'
            else unsigned(diff(DIFF_W - 2 downto 0));

    -- Leitura assíncrona da ROM (puramente combinacional)
    square <= SQUARE_ROM(to_integer(abs_diff));

end architecture behavior;
