# AP3-05235A-Grupo-D

## Integrantes

- Bruno dos Santos Navas — Matrícula: 26150425
- Bruno Alcântara — Matrícula: 19205027
- Chancel Olivier Sèdjro Affanchao — Matrícula: 20150665

## Descrição do projeto

O projeto consiste no desenvolvimento de um sistema digital em VHDL para cálculo da métrica de erro quadrático médio, conhecida como MSE (*Mean Squared Error*), aplicada à comparação entre dois blocos de pixels de uma imagem ou vídeo. Essa métrica é utilizada em processamento digital de sinais, compressão de imagens e codificação de vídeo para medir a diferença entre um bloco original e um bloco reconstruído ou processado.

O sistema receberá dois blocos de pixels, calculará a diferença entre os valores correspondentes, elevará cada diferença ao quadrado, acumulará esses valores e, ao final, realizará a normalização pelo número total de pixels do bloco. A saída do circuito será o valor de MSE, permitindo avaliar digitalmente o nível de distorção entre os dois blocos.
