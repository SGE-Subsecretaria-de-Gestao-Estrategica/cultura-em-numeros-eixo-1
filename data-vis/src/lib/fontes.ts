/**
 * Shared setup for the "fontes de recurso" ribbon figures — the Storybook
 * stories and the A4 proof page draw the same chart, so the palette, the short
 * names and the print sizing live here rather than in either of them.
 */

import { colorScales, purple } from 'sniic-design-system';
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
