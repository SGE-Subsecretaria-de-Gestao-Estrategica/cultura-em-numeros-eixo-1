/**
 * Shared setup for the "fontes de recurso" figures — the Storybook stories and
 * the A4 proof page draw the same charts, so the palettes, the short names and
 * the print sizing live here rather than in any one of them.
 */

import { rampaAzul, rampaCiana, rampaVermelha } from './cores';
import { a4Scale } from './tokens';

/**
 * As cinco fontes de recurso sub-nacionais, nas três matizes da marca.
 *
 * A matiz carrega de onde o dinheiro vem, e a luminosidade separa as fontes
 * dentro de cada origem. É a mesma lógica das figuras federais, para que a
 * coleção inteira possa ser lida com uma chave só:
 *
 * - **Azul, o orçamento do próprio ente.** O recurso próprio, a linha de base
 *   sobre a qual todo o resto entra.
 * - **Ciano, o que vem da União fora de uma lei de emergência.** As emendas
 *   parlamentares — no federal, é a matiz da renúncia fiscal, o outro dinheiro
 *   que a União move sem ser pela porta do orçamento do ente.
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
 * o ciano da marca, que a 55% de opacidade ainda se lê. O pior par é LAB 1
 * contra LPG, a ΔE 6,6 depois da opacidade — os dois degraus vermelhos vizinhos
 * —, e é por isso que a figura de fitas escreve o nome da fonte dentro do
 * segmento: aqui a cor reforça a identidade, não a carrega sozinha.
 */
export const fonteColors = [
  rampaAzul[2], // Recurso próprio — o azul da marca
  rampaCiana[4], // Emendas — o ciano da marca
  rampaVermelha[3], // LAB 1
  rampaVermelha[2], // LPG — o vermelho da marca
  rampaVermelha[0], // PNAB
];

/**
 * As mesmas cinco fontes para as figuras de evolução estadual — as linhas e as
 * colunas empilhadas, que são a mesma tabela e por isso têm de sair na mesma
 * paleta.
 *
 * Difere de `fonteColors` num degrau só: o ciano da marca rende 1,8:1 sobre o
 * cartão e não sustenta um traço de 2 px, então as emendas descem para o degrau
 * abaixo. A matiz — que é o que identifica a fonte entre as figuras — não muda.
 *
 * Nesta versão nenhum par cai abaixo de ΔE 11,9 em visão normal nem de 11,0 sob
 * qualquer forma de daltonismo, e o pior deles é o par vermelho vizinho.
 */
export const fonteMarcaColors = [
  rampaAzul[2], // Recurso próprio
  rampaCiana[3], // Emendas — o ciano um degrau abaixo, para aguentar o traço
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
 * ciano é a renúncia fiscal, vermelho é o dinheiro que desce para estados e
 * municípios. As oito fontes abaixo herdam a matiz do grupo a que pertencem, e
 * as figuras sub-nacionais seguem a mesma chave.
 *
 * São as três primeiras da escala de traço da marca: nenhum par cai abaixo de
 * ΔE 21 em visão normal, nem de 16 sob qualquer forma de daltonismo — a maior
 * separação que três séries podem ter nesta paleta.
 *
 * Ficam aqui, e não em cada figura, porque o combo de linhas e colunas e o
 * gráfico de linhas desenham os mesmos três grupos: duas paletas iguais copiadas
 * em dois arquivos só esperam a hora de divergir.
 */
export const grupoFederalColors = [
  rampaAzul[2], // Execução direta
  rampaCiana[3], // Renúncia fiscal
  rampaVermelha[2], // Transferências a estados e municípios
];

/** Só o terceiro encurta — por extenso, ele não cabe ao lado da linha. */
export const grupoFederalLabels: Record<string, string> = {
  'Execução direta': 'Execução direta',
  'Renúncia fiscal': 'Renúncia fiscal',
  'Transferências a estados e municípios': 'Transferências a entes',
};

/**
 * As oito fontes federais na ordem em que o JSON as traz. É a mesma paleta na
 * tabela, no ribbon e nos gráficos de linhas e de colunas, para que as quatro
 * figuras possam ser lidas uma ao lado da outra.
 *
 * Oito séries passam do que três matizes sustentam sozinhas, então a paleta usa
 * as duas dimensões que tem: a **matiz diz a que grupo institucional a fonte
 * pertence** — os mesmos três de `grupoFederalColors` — e a **luminosidade
 * separa as fontes dentro do grupo**. Quem já leu a figura dos três grupos
 * chega aqui sabendo metade da legenda.
 *
 * - **Azuis, a execução direta.** MinC no azul da marca, por ser a maior; FSA
 *   no degrau escuro; os outros órgãos no claro.
 * - **Cianos, a renúncia fiscal.** A Lei Rouanet no ciano da marca e a ANCINE
 *   três degraus abaixo — as duas ficam sempre encostadas na pilha, e essa
 *   distância é o que impede que se fundam numa faixa só, que é exatamente a
 *   leitura errada: metade do investimento federal é renúncia, e a figura
 *   precisa mostrar de qual das duas.
 * - **Vermelhos, o que desce para estados e municípios.** As três leis com a
 *   mais nova no degrau mais escuro, que é como as figuras sub-nacionais já as
 *   desenham.
 *
 * Nenhum par cai abaixo de ΔE 12,6 em visão normal nem de 8,9 sob qualquer
 * forma de daltonismo, e nenhuma adjacência da pilha abaixo de 12,6 — todas as
 * seis anteriores estavam abaixo disso, e é por elas que as duas tabelas de
 * correção que existiam aqui saíram.
 */
export const fonteFederalPalette = [
  rampaAzul[2], // Ministério da Cultura
  rampaCiana[4], // Lei Rouanet
  rampaCiana[1], // Incentivo (ANCINE)
  rampaAzul[0], // FSA
  rampaVermelha[0], // PNAB
  rampaVermelha[1], // Lei Paulo Gustavo
  rampaVermelha[3], // Lei Aldir Blanc 1
  rampaAzul[3], // Outros órgãos
];

export const fonteFederalColors = (keys: readonly string[]): Record<string, string> =>
  Object.fromEntries(keys.map((k, i) => [k, fonteFederalPalette[i % fonteFederalPalette.length]]));

/**
 * Um degrau desce quando as fontes são desenhadas como traço fino, e não como
 * faixa.
 *
 * O ciano da marca preenche área muito bem, e ainda aguenta os 55% de opacidade
 * do ribbon chart. Num traço de 2 px, e sobretudo no nome da série escrito na
 * cor dela, ele rende 1,8:1 contra o cartão claro e sai ilegível.
 *
 * A troca é por um degrau mais escuro da mesma família, então a matiz — que é o
 * que identifica a fonte entre as figuras — não muda: a Lei Rouanet passa de
 * 1,8:1 para 3,9:1, e continua sendo o ciano do grupo da renúncia fiscal.
 */
const CONTRASTE_EM_TRACO: Record<string, string> = {
  [rampaCiana[4]]: rampaCiana[2],
};

export const fonteFederalLineColors = (keys: readonly string[]): Record<string, string> =>
  Object.fromEntries(
    Object.entries(fonteFederalColors(keys)).map(([k, cor]) => [k, CONTRASTE_EM_TRACO[cor] ?? cor]),
  );

/**
 * Na pilha, o par que importa não é cada cor contra o cartão, é cada cor contra
 * a sua vizinha — e aí a paleta já serve como está: a menor adjacência é PNAB
 * sob a Lei Paulo Gustavo, dois degraus vermelhos a ΔE 12,6 (10,4 sob
 * protanopia), com o vão de superfície entre as duas.
 *
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
