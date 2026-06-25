library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Registrador parametrizável para N bits com controle de enable.
-- O registrador atualiza sua saída `q` com o valor da entrada `d` na borda de
-- subida do sinal `clk`, apenas quando `enable = '1'`.
entity unsigned_register is
	generic(
		N : positive := 4 -- número de bits armazenados
	);
	port(
		clk, enable : in  std_logic;                -- clock (clk) e carga (enable)
		d           : in  unsigned(N - 1 downto 0); -- dado de entrada
		q           : out unsigned(N - 1 downto 0)  -- dado armazenado
	);
end unsigned_register;
-- Não altere a definição da entidade!
-- Ou seja, não modifique o nome da entidade, nome das portas e tipos/tamanhos das portas!

-- Não alterar o nome da arquitetura!
architecture behavior OF unsigned_register is
    signal q_reg : unsigned(N - 1 downto 0) := (others => '0');
begin
    process(clk)
	begin
		if rising_edge(clk) then
			if enable = '1' then
				q_reg <= d;
			end if;
		end if;
	end process;

	q <= q_reg;
end architecture behavior;
