# AP3-05235A-Grupo-D

## Integrantes

- Bruno dos Santos Navas — Matrícula: 26150425
- Bruno Alcântara — Matrícula: 19205027
- Chancel Olivier Sèdjro Affanchao — Matrícula: 20150665

## Descrição do projeto

O projeto consiste no desenvolvimento de um sistema digital em VHDL para cálculo da métrica de erro quadrático médio, conhecida como MSE (*Mean Squared Error*), aplicada à comparação entre dois blocos de pixels de uma imagem ou vídeo. Essa métrica é utilizada em processamento digital de sinais, compressão de imagens e codificação de vídeo para medir a diferença entre um bloco original e um bloco reconstruído ou processado.

O sistema receberá dois blocos de pixels, calculará a diferença entre os valores correspondentes, elevará cada diferença ao quadrado, acumulará esses valores e, ao final, realizará a normalização pelo número total de pixels do bloco. A saída do circuito será o valor de MSE, permitindo avaliar digitalmente o nível de distorção entre os dois blocos.

## Arquiteturas Implementadas

Para fins de análise comparativa de compromisso (*trade-off*) entre área de silício e velocidade operacional na FPGA, o cálculo crítico da potência $(A_i - B_i)^2$ foi explorado através de duas abordagens distintas no Bloco Operacional:

1. **Abordagem MULT (`mse_top_mult`):** * Utiliza um **Multiplicador Aritmético** dedicado (`square_mult.vhdl`).
   * **Vantagem:** Totalmente escalável para maiores larguras de bit sem impacto exponencial na lógica.
   * **Desvantagem:** Consumo de blocos DSP dedicados da FPGA.

2. **Abordagem LUT (`mse_top_lut`):** * Utiliza uma **Look-Up Table** (`square_lut.vhdl`) mapeada como memória ROM combinacional pré-calculada.
   * **Vantagem:** Latência combinacional mínima e poupança absoluta de multiplicadores de hardware.
   * **Desvantagem:** Crescimento exponencial de área (bits de endereçamento) caso a resolução do pixel aumente.


## Metodologia de Verificação

A verificação funcional do sistema foi desenhada com foco em **determinismo e portabilidade**, contornando ambiguidades de bibliotecas de I/O de ficheiros do compilador:

* **Golden Model Comportamental:** Foi embutida uma função matemática pura (`calc_mse`) no interior do *Testbench* principal (`mse_tb.vhdl`). Esta função calcula em tempo de execução o valor exato esperado para qualquer vetor de teste injetado, servindo como "verdade absoluta" de verificação.
* **Estímulos (*Corner Cases*):** A bateria de testes cobre exaustivamente os cenários críticos:
  1. Amostras idênticas ($\Delta = 0 \rightarrow MSE = 0$)
  2. Amostras com diferença unitária permanente ($\Delta = 1 \rightarrow MSE = 1$)
  3. Diferença máxima extrema ($255\text{ vs } 0 \rightarrow MSE = 65025$)
  4. Vetores de valores arbitrários validados matematicamente.
* **Isolamento de Falhas:** Além do testbench unificado, cada arquitetura possui o seu próprio ambiente de simulação isolado (`mse_tb_mult.vhdl` e `mse_tb_lut.vhdl`), permitindo inspeção limpa de sinais no analisador de ondas.


