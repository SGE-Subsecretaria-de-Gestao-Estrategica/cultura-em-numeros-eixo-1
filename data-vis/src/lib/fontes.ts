/**
 * Shared setup for the "fontes de recurso" figures — the Storybook stories and
 * the A4 proof page draw the same charts, so the palettes, the short names and
 * the print sizing live here rather than in any one of them.
 */

import { rampaAzul, rampaRosa, rampaVermelha, sniic } from './cores';
import { a4Scale, colorGradients } from './tokens';

/**
 * As cinco fontes de recurso sub-nacionais, em três matizes da marca.
 *
 * A matiz carrega de onde o dinheiro vem, e a luminosidade separa as fontes
 * dentro de cada origem. É a mesma lógica das figuras federais, para que a
 * coleção inteira possa ser lida com uma chave só:
 *
 * - **Azul, o orçamento do próprio ente.** O recurso próprio, a linha de base
 *   sobre a qual todo o resto entra.
 * - **Rosa, o que vem da União fora de uma lei de emergência.** As emendas
 *   parlamentares — no federal, é a matiz da renúncia fiscal, o outro dinheiro
 *   que a União move sem ser pela porta do orçamento do ente. O rosa, e não o
 *   verde, porque esta paleta convive com três vermelhos: um verde médio some
 *   ao lado de um vermelho sob protanopia e deuteranopia, e o rosa é a matiz
 *   restante que se separa dos três sob todas as formas de daltonismo.
 * - **Vermelhos, as três leis de emergência.** Do mais claro ao mais escuro na
 *   ordem em que entram: LAB 1 (2020), LPG (2023), PNAB (2024). A rampa é
 *   espaçada em luminosidade, então a ordem sobrevive à impressão em escala de
 *   cinza, e os três degraus escolhidos são os de separação máxima que ainda
 *   sustentam um traço sobre o cartão claro.
 *
 * Os 11 pontos de luminosidade entre os degraus vermelhos do meio são o que
 * resolve o único cruzamento da figura de linhas: a LPG despencando e a PNAB
 * subindo se atravessam em 2025.
 *
 * Este é o conjunto de preenchimento, para as fitas: nele as emendas ficam com
 * o degrau claro do rosa, que a 55% de opacidade ainda se lê. O pior par é
 * LAB 1 contra LPG, a ΔE 5,8 depois da opacidade — os dois degraus vermelhos
 * vizinhos —, e é por isso que a figura de fitas escreve o nome da fonte dentro
 * do segmento: aqui a cor reforça a identidade, não a carrega sozinha.
 */
export const fonteColors = [
  rampaAzul[2], // Recurso próprio — o azul da marca
  rampaRosa[4], // Emendas — o degrau claro do rosa
  rampaVermelha[3], // LAB 1
  rampaVermelha[2], // LPG — o vermelho da marca
  rampaVermelha[0], // PNAB
];

/**
 * As mesmas cinco fontes para as figuras de evolução estadual — as linhas e as
 * colunas empilhadas, que são a mesma tabela e por isso têm de sair na mesma
 * paleta.
 *
 * Difere de `fonteColors` num degrau só: o rosa claro rende 1,8:1 sobre o
 * cartão e não sustenta um traço de 2 px, então as emendas descem para um
 * degrau escuro. A matiz — que é o que identifica a fonte entre as figuras —
 * não muda.
 *
 * Nesta versão nenhum par cai abaixo de ΔE 9,3 em visão normal nem de 6,0 sob
 * qualquer forma de daltonismo, e o pior deles é o par vermelho vizinho.
 */
export const fonteMarcaColors = [
  rampaAzul[2], // Recurso próprio
  rampaRosa[1], // Emendas — o rosa escuro, para aguentar o traço
  rampaVermelha[3], // LAB 1
  rampaVermelha[2], // LPG — o vermelho da marca
  rampaVermelha[0], // PNAB
];

/** Covers both datasets — the own-revenue key differs by sphere. */
export const fonteLabels: Record<string, string> = {
  'Recurso Próprio (Estadual)': 'Recurso próprio',
  'Recurso Próprio (Municipal)': 'Recurso próprio',
  'Emendas Parlamentares (Cultura)': 'Emendas',
  'Lei Aldir Blanc 1 (LAB 1)': 'LAB 1',
  'Lei Paulo Gustavo (LPG)': 'LPG',
  'PNAB (Aldir Blanc 2)': 'PNAB',
};

/**
 * Os três grupos institucionais da série federal, na ordem em que as figuras os
 * desenham: execução direta, renúncia fiscal, transferências a entes.
 *
 * É uma matiz da marca para cada grupo, e é daqui que sai a chave de leitura de
 * todas as outras figuras federais: azul é o orçamento executado pela União,
 * rosa é a renúncia fiscal, vermelho é o dinheiro que desce para estados e
 * municípios. As oito fontes abaixo herdam a matiz do grupo a que pertencem, e
 * as figuras sub-nacionais seguem a mesma chave.
 *
 * Como traço, a renúncia fica no rosa escuro: nenhum par cai abaixo de ΔE 17
 * em visão normal, nem de 15 sob qualquer forma de daltonismo — a maior
 * separação que três séries com dois quentes podem ter nesta paleta.
 *
 * Ficam aqui, e não em cada figura, porque o combo de linhas e colunas e o
 * gráfico de linhas desenham os mesmos três grupos: duas paletas iguais copiadas
 * em dois arquivos só esperam a hora de divergir.
 */
export const grupoFederalColors = [
  rampaAzul[2], // Execução direta
  rampaRosa[1], // Renúncia fiscal
  rampaVermelha[2], // Transferências a estados e municípios
];

/** Só o terceiro encurta — por extenso, ele não cabe ao lado da linha. */
export const grupoFederalLabels: Record<string, string> = {
  'Execução direta': 'Execução direta',
  'Renúncia fiscal': 'Renúncia fiscal',
  'Transferências a estados e municípios': 'Transferências a entes',
};

/**
 * As oito fontes federais nos gradientes da marca — a paleta que o histomap
 * desenha.
 *
 * Oito séries passam do que três matizes sustentam sozinhas, então a paleta usa
 * as duas dimensões que tem: a **matiz diz a que grupo institucional a fonte
 * pertence** e a **luminosidade separa as fontes dentro do grupo**. Quem lê a
 * legenda no topo da figura, que sai na ordem de empilhamento, já chega ao plot
 * com os três grupos na cabeça.
 *
 * - **Azuis e roxo, a execução direta.** O MinC no degrau mais escuro do azul,
 *   por ser a maior faixa; os Outros Órgãos num azul claro — a extinção do MinC
 *   lê-se como clareamento dentro da mesma massa, que é o que ela foi; e o FSA
 *   no roxo escuro, a única troca de matiz do grupo. Ela existe porque o
 *   gradiente azul não separa três faixas: com o FSA em azul, o MinC e os
 *   Outros Órgãos ficariam a ΔE 5 um do outro na legenda, encostados e quase
 *   iguais, e são justamente os dois que o leitor precisa distinguir.
 * - **Rosas, a renúncia fiscal.** A Lei Rouanet no degrau escuro e a ANCINE no
 *   mais claro — as duas ficam sempre encostadas na pilha, e essa distância é o
 *   que impede que se fundam numa faixa só, que é exatamente a leitura errada:
 *   metade do investimento federal é renúncia, e a figura precisa mostrar de
 *   qual das duas.
 * - **Vermelhos, o que desce para estados e municípios.** A LPG no degrau mais
 *   escuro e a PNAB no mais claro, que é o par que de fato se toca (2023), com
 *   a LAB 1 no meio — ela vive sozinha em 2020 e só encosta na ANCINE.
 *
 * O que a paleta garante é a adjacência, que é o que uma figura empilhada pede:
 * nenhum par que chegue a se tocar na pilha cai abaixo de ΔE 15,1 em visão
 * normal nem de 14,5 sob qualquer forma de daltonismo. O que ela não garante é
 * o par distante: os gradientes desta marca são estreitos em luminosidade, e
 * sob protanopia ou deuteranopia um rosa claro e um vermelho claro que nunca se
 * encostam ficam a ΔE 3,7. Daí a legenda no topo e o nome escrito dentro da
 * faixa: aqui a cor reforça a identidade, não a carrega sozinha.
 */
export const fonteFederalPalette: Record<string, string> = {
  'Ministério da Cultura (Órgão 42000)': colorGradients.secondaryVariant[0],
  'Outros Órgãos (Cidadania/Turismo)': colorGradients.secondaryVariant[3],
  'FSA (UO 74912)': colorGradients.secondary[0],
  'Lei Rouanet': colorGradients.primaryVariant[0],
  'Incentivo (ANCINE)': colorGradients.primaryVariant[4],
  'Lei Aldir Blanc 1': colorGradients.primary[2],
  'Lei Paulo Gustavo': colorGradients.primary[0],
  'PNAB (UO 73120)': colorGradients.primary[4],
};

/**
 * As cores na ordem em que as chaves forem pedidas.
 *
 * A paleta é indexada pelo nome da fonte, e não pela posição no JSON, porque a
 * figura empilha na ordem dos grupos institucionais e não na ordem das chaves:
 * indexar por posição faria a cor seguir a tabela em vez de seguir a fonte.
 */
export const fonteFederalColors = (keys: readonly string[]): Record<string, string> =>
  Object.fromEntries(keys.map((k) => [k, fonteFederalPalette[k] ?? sniic.vermelho]));

/**
 * Fica como função, e não como sinônimo, porque é a assinatura que as figuras
 * empilhadas chamam — e porque é aqui que uma correção entraria, se algum ano
 * futuro puser duas fontes de matizes vizinhas encostadas.
 */
export const fonteFederalStackColors = fonteFederalColors;

/**
 * Nomes curtos das fontes federais.
 *
 * As leis vêm por extenso e o resto por sigla, e não é inconsistência: numa
 * figura sobre fonte de recurso, "Lei Paulo Gustavo" e "Lei Aldir Blanc 1" são
 * o assunto, e são justamente as que acabam dentro do plot, onde o nome longo
 * cabe. As que chegam a 2025 põem o nome na margem direita, que toda série
 * paga em largura de plot — lá a sigla é o que evita a calha larga.
 */
export const fonteFederalLabels: Record<string, string> = {
  'Ministério da Cultura (Órgão 42000)': 'MinC',
  'Lei Rouanet': 'Lei Rouanet',
  'Incentivo (ANCINE)': 'ANCINE',
  'FSA (UO 74912)': 'FSA',
  'PNAB (UO 73120)': 'PNAB',
  'Lei Paulo Gustavo': 'Lei Paulo Gustavo',
  'Lei Aldir Blanc 1': 'Lei Aldir Blanc 1',
  'Outros Órgãos (Cidadania/Turismo)': 'Outros órgãos',
};

/**
 * Print sizing for a figure running the full text width of A4 portrait.
 *
 * Type in an SVG is absolute, so its printed size is decided by the ratio of
 * font size to chart width, not by either alone; `a4Scale` is that ratio for a
 * card authored at this width, and lands the value labels at 9 pt.
 *
 * Widening the columns is not cosmetic: a value label is 3.94 px wide per px
 * of font, and a column is only 5.83% of the chart at `columnRatio` 0.42 —
 * so at 9 pt the labels cannot fit inside a column at any authoring size.
 * 0.6 buys the room back, at the cost of thinner ribbons.
 *
 * It stops at 0.6 on purpose. Fitting the longest labels — `R$ 12,6 bi` and
 * the `mi` values — would take 0.70 and 0.84, and past ~0.68 the ribbons are
 * slivers and the callouts stack over the columns: the chart stops being a
 * ribbon chart. The labels that miss the cut fall back to 7.9 pt, which still
 * prints legibly. Dropping `R$ ` from the in-segment values would fit every
 * one of them at 9 pt without widening anything further.
 */
export const A4_RIBBON = {
  responsive: false,
  width: 1368,
  height: 620,
  fontScale: a4Scale(1368),
  columnRatio: 0.6,
  // the legend and axis grow with the type, so the gutter under the plot has to
  margin: { bottom: 132 },
};

/**
 * The federal series runs 23 years against the sub-national seven, so it gets
 * the landscape figure: at 170 mm the year ticks alone would need more than a
 * band is wide. Same 9 pt target, measured against the 257 mm text width.
 */
const A4_LANDSCAPE_TEXT_WIDTH_MM = 257;
export const A4_RIBBON_LANDSCAPE = {
  responsive: false,
  width: 1900,
  height: 760,
  fontScale: (3.175 / A4_LANDSCAPE_TEXT_WIDTH_MM) * (1900 / 12),
  columnRatio: 0.5,
  margin: { bottom: 132 },
};
