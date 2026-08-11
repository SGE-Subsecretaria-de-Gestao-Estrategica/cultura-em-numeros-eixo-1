/**
 * Layout da faixa de legenda, fora do componente que a desenha.
 *
 * O cartão precisa saber quantas linhas a legenda vai ocupar *antes* de se
 * diagramar — é isso que decide a margem inferior e, portanto, a altura da
 * folha. Se a conta vivesse dentro de `LegendChips`, o pai teria de adivinhá-la
 * ou repeti-la, e uma legenda de cinco categorias longas estouraria a borda do
 * cartão sem que nada percebesse.
 */

import { measureLabel } from './tokens';

export type LegendItem = { label: string; color: string };

export type LegendChip = LegendItem & {
  x: number;
  y: number;
  width: number;
  /** Primeiro e último da sua linha — só essas pontas são arredondadas. */
  first: boolean;
  last: boolean;
};

export interface LegendLayout {
  chips: LegendChip[];
  rows: number;
  /** Altura de uma pastilha. */
  chipHeight: number;
  /** Altura da faixa inteira, pastilhas e vãos entre linhas. */
  height: number;
}

export interface LegendOptions {
  fontSize: number;
  fontWeight?: number;
  /** Espaço horizontal entre o texto e a borda da pastilha. */
  padX?: number;
  /** Largura disponível; a faixa quebra para uma nova linha ao ultrapassá-la. */
  maxWidth: number;
  /** Espaço vertical entre duas linhas de pastilhas. */
  rowGap?: number;
}

/**
 * Distribui as pastilhas em linhas, cada uma começando em x = 0.
 *
 * As pastilhas de uma mesma linha ficam encostadas umas nas outras — é o que dá
 * à faixa a aparência de uma barra segmentada — então a quebra de linha é o
 * único respiro que a legenda tem. Uma pastilha mais larga que `maxWidth`
 * sozinha ocupa a sua linha em vez de ser cortada.
 */
export function layoutLegend(items: LegendItem[], options: LegendOptions): LegendLayout {
  const { fontSize, fontWeight = 600, padX = 10, maxWidth, rowGap = 4 } = options;
  const chipHeight = Math.round(fontSize * 1.9);

  const chips: LegendChip[] = [];
  let cursor = 0;
  let row = 0;

  for (const item of items) {
    const width = measureLabel(item.label, fontSize, fontWeight) + padX * 2;
    if (cursor > 0 && cursor + width > maxWidth) {
      row += 1;
      cursor = 0;
    }
    chips.push({
      ...item,
      x: cursor,
      y: row * (chipHeight + rowGap),
      width,
      first: cursor === 0,
      last: false,
    });
    cursor += width;
  }

  // o último de cada linha só se conhece depois que a linha fechou
  for (let i = 0; i < chips.length; i++) {
    chips[i].last = i === chips.length - 1 || chips[i + 1].y !== chips[i].y;
  }

  const rows = row + 1;
  return { chips, rows, chipHeight, height: rows * chipHeight + (rows - 1) * rowGap };
}
