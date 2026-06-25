library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.mse_pack.all;

entity mse_tb is
    generic (
        BPS   : positive := 8;
        N_PIX : positive := 4 -- Usando 4 para testar rápido e não travar
    );
end entity mse_tb;

architecture sim of mse_tb is
    constant CLK_PERIOD : time := 10 ns;
    constant OUT_W      : positive := mse_out_width;

    signal clk        : std_logic := '0';
    signal rst        : std_logic := '0';
    signal start      : std_logic := '0';
    signal pixel_a_in : std_logic_vector(BPS - 1 downto 0) := (others => '0');
    signal pixel_b_in : std_logic_vector(BPS - 1 downto 0) := (others => '0');
    signal mse_out    : std_logic_vector(OUT_W - 1 downto 0);
    signal busy       : std_logic;
    signal done       : std_logic;

    -- Tipo necessário para a tua função Golden Model
    type pixel_vec_t is array (0 to N_PIX - 1) of natural;

    -- A TUA FUNÇÃO (O Golden Model oficial rodando dentro do VHDL)
    function calc_mse(
        pa, pb : pixel_vec_t
    ) return natural is
        variable soma : natural := 0;
        variable diff : integer;
    begin
        for i in 0 to N_PIX - 1 loop
            diff := integer(pa(i)) - integer(pb(i));
            soma := soma + natural(diff * diff);
        end loop;
        return soma / N_PIX;
    end function;

    -- Procedimento local para aplicar os vetores no hardware sequencialmente
    procedure run_hardware_test(
        constant pa_vals : in pixel_vec_t;
        constant pb_vals : in pixel_vec_t;
        signal clk_s     : in std_logic;
        signal rst_s     : out std_logic;
        signal start_s   : out std_logic;
        signal p_a_s     : out std_logic_vector;
        signal p_b_s     : out std_logic_vector;
        signal done_s    : in std_logic
    ) is
    begin
        -- 1. Reset do circuito
        rst_s <= '1';
        wait for 2 * CLK_PERIOD;
        rst_s <= '0';
        wait for CLK_PERIOD;

        -- 2. Pulso de Start
        start_s <= '1';
        wait for CLK_PERIOD;
        start_s <= '0';
        wait for CLK_PERIOD; -- Aguarda o estado INIT ir para ACCUM

        -- 3. Alimenta os pixels um por um a cada ciclo de clock
        for i in 0 to N_PIX - 1 loop
            p_a_s <= std_logic_vector(to_unsigned(pa_vals(i), BPS));
            p_b_s <= std_logic_vector(to_unsigned(pb_vals(i), BPS));
            wait for CLK_PERIOD;
        end loop;

        -- 4. Espera o sinal 'done' do hardware subir
        if done_s = '0' then
            wait until done_s = '1';
        end if;
        wait for CLK_PERIOD;
    end procedure;

begin
    -- Geração do Clock
    clk <= not clk after CLK_PERIOD / 2;

    -- Instanciação do teu componente (DUT) - Aqui testando a versão LUT
    dut_lut : entity work.mse_top_lut
        generic map(N_PIXELS => N_PIX, BITS_PER_SAMPLE => BPS)
        port map(
            clk        => clk, 
            rst        => rst,     
            start      => start,    
            pixel_a_in => pixel_a_in,
            pixel_b_in => pixel_b_in,
            mse_out    => mse_out,  
            busy       => busy,
            done       => done
        );

    -- Processo de estímulos com casos dinâmicos baseados no Golden Model
    p_stim : process
        variable pa_test, pb_test : pixel_vec_t;
        variable expected_mse     : natural;
        variable obtained_mse     : natural;
        variable total_errors     : natural := 0;
    begin
        wait for 2 * CLK_PERIOD;
        report "=== INICIANDO ANALISE COM GOLDEN MODEL INTERNO ===" severity note;

        -----------------------------------------------------------------------
        -- CASO 1: Pixels Idênticos (Diferença zero)
        -----------------------------------------------------------------------
        pa_test := (100, 200, 50, 10);
        pb_test := (100, 200, 50, 10);
        
        expected_mse := calc_mse(pa_test, pb_test); -- Calcula usando a tua função
        
        run_hardware_test(pa_test, pb_test, clk, rst, start, pixel_a_in, pixel_b_in, done);
        obtained_mse := to_integer(unsigned(mse_out));
        
        assert obtained_mse = expected_mse
            report "FALHA CASO 1: HW=" & integer'image(obtained_mse) & " Golden=" & integer'image(expected_mse)
            severity error;
        if obtained_mse /= expected_mse then total_errors := total_errors + 1; end if;

        -----------------------------------------------------------------------
        -- CASO 2: Diferença Máxima (255 vs 0)
        -----------------------------------------------------------------------
        pa_test := (255, 255, 255, 255);
        pb_test := (0, 0, 0, 0);
        
        expected_mse := calc_mse(pa_test, pb_test); -- Calcula automaticamente
        
        run_hardware_test(pa_test, pb_test, clk, rst, start, pixel_a_in, pixel_b_in, done);
        obtained_mse := to_integer(unsigned(mse_out));
        
        assert obtained_mse = expected_mse
            report "FALHA CASO 2: HW=" & integer'image(obtained_mse) & " Golden=" & integer'image(expected_mse)
            severity error;
        if obtained_mse /= expected_mse then total_errors := total_errors + 1; end if;

        -----------------------------------------------------------------------
        -- CASO 3: Valores Arbitrários
        -----------------------------------------------------------------------
        pa_test := (110, 180, 55, 7);
        pb_test := (100, 200, 50, 10);
        
        expected_mse := calc_mse(pa_test, pb_test); -- Calcula automaticamente
        
        run_hardware_test(pa_test, pb_test, clk, rst, start, pixel_a_in, pixel_b_in, done);
        obtained_mse := to_integer(unsigned(mse_out));
        
        assert obtained_mse = expected_mse
            report "FALHA CASO 3: HW=" & integer'image(obtained_mse) & " Golden=" & integer'image(expected_mse)
            severity error;
        if obtained_mse /= expected_mse then total_errors := total_errors + 1; end if;

        -----------------------------------------------------------------------
        -- FIM DOS TESTES
        -----------------------------------------------------------------------
        if total_errors = 0 then
            report "SUCESSO ABSOLUTO: O Hardware bate com o Golden Model em todos os casos!" severity note;
        else
            report "ERRO: O Hardware divergiu do Golden Model!" severity failure;
        end if;

        wait;
    end process p_stim;

end architecture sim;
