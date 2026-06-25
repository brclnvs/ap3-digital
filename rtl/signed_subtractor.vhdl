library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity signed_subtractor is
	generic(
		N : positive := 8 
	);
	port(
		input_a    : in  signed(N - 1 downto 0); 
		input_b    : in  signed(N - 1 downto 0); 
		difference : out signed(N - 1 downto 0)  
	);
end signed_subtractor;

architecture arch of signed_subtractor is
    
begin
    difference <= input_a - input_b;
end architecture arch;