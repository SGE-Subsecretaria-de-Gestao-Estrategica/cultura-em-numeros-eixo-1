/**
 * Shared setup for the "fontes de recurso" figures — the Storybook stories and
 * the A4 proof page draw the same charts, so the palettes, the short names and
 * the print sizing live here rather than in any one of them.
 */

import { categorical8, colorScales, purple } from 'sniic-design-system';
import { a4Scale } from './tokens';

/**
 * Recurso próprio takes the library's purple; the four transfers share a
 * green family, so the chart reads as own revenue against everything that
 * was transferred in.
 *
 * The greens alternate between the lime and teal scales while stepping
 * steadily darker (L* 84 → 74 → 64 → 35). Alternating is what keeps them
 * apart: the closest pair here is ΔE 31 in Lab, against ΔE 12 for four
 * consecutive steps of a single scale, which would blur under the ribbons'
 * 55% opacity.
 */
export const fonteColors = [
  purple, // Recurso próprio
  colorScales.lime[1], // Emendas
  colorScales.teal[1], // LAB 1
  colorScales.lime[2], // LPG
  colorScales.teal[3], // PNAB
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
 * Validadas contra os seis checks: banda de luminosidade, piso de croma,
 * separação sob daltonismo (pior par ΔE 9,4 em protanopia, acima do mínimo de
 * 8), piso de visão normal e contraste contra a superfície.
 *
 * Azul e laranja mantêm a identidade que MinC e Rouanet já têm no ribbon chart;
 * o roxo é o extraordinário, o dinheiro que só existe quando uma lei o cria.
 *
 * Ficam aqui, e não em cada figura, porque o combo de linhas e colunas e o
 * gráfico de linhas desenham os mesmos três grupos: duas paletas iguais copiadas
 * em dois arquivos só esperam a hora de divergir.
 */
export const grupoFederalColors = ['#4271b5', '#ea662f', '#a44c7f'];

/** Só o terceiro encurta — por extenso, ele não cabe ao lado da linha. */
export const grupoFederalLabels: Record<string, string> = {
  'Execução direta': 'Execução direta',
  'Renúncia fiscal': 'Renúncia fiscal',
  'Transferências a estados e municípios': 'Transferências a entes',
};

/**
 * As oito fontes federais na ordem em que o JSON as traz, com a cor que cada
 * uma tem no ribbon chart — a permutação existe para que a tabela, o ribbon e
 * o gráfico de linhas possam ser lidos um ao lado do outro.
 *
 * Oito séries passam do que a rampa do pilar sustenta (três matizes), então a
 * paleta é a categórica do design system.
 */
const ORDEM_CATEGORICA = [0, 1, 6, 2, 3, 5, 4, 7];

export const fonteFederalColors = (keys: readonly string[]): Record<string, string> =>
  Object.fromEntries(keys.map((k, i) => [k, categorical8[ORDEM_CATEGORICA[i]]]));

/**
 * Três degraus da paleta descem um tom quando as fontes são desenhadas como
 * traço fino, e não como faixa.
 *
 * A escala categórica é afinada para o ribbon chart, onde a cor preenche área
 * e ainda passa por 55% de opacidade — o amarelo `#f6c341` e o lavanda
 * `#c9b6c5` funcionam ali. Num traço de 2 px, e sobretudo no nome da série
 * escrito na cor dela, os dois rendem menos de 2:1 contra o cartão claro e
 * saem ilegíveis; o lima `#81a72f` fica em 2,8:1, no limite.
 *
 * A troca é pelo degrau imediatamente mais escuro da mesma família, então a
 * matiz — que é o que identifica a fonte entre as figuras — não muda: amarelo
 * vira ocre, lima vira oliva, lavanda vira malva, e os três passam de 3,4:1.
 */
const CONTRASTE_EM_TRACO: Record<string, string> = {
  [categorical8[3]]: colorScales.yellow[3],
  [categorical8[5]]: colorScales.lime[3],
  [categorical8[7]]: colorScales.lavender[3],
};

export const fonteFederalLineColors = (keys: readonly string[]): Record<string, string> =>
  Object.fromEntries(
    Object.entries(fonteFederalColors(keys)).map(([k, cor]) => [k, CONTRASTE_EM_TRACO[cor] ?? cor]),
  );

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
