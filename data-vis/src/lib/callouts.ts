/**
 * Placement for value callouts — the little boxed labels used when a segment is
 * too small to carry its value inside it. Shared by the stacked and ribbon
 * charts, which differ in how they lay segments out but not in how a callout
 * should behave: centred on its own column, nudged up until it clears the
 * inline labels and every callout already placed.
 */

import { fontSize } from './tokens';

export type Box = { x: number; y: number; width: number; height: number };

export type CalloutInput = {
  key: string;
  label: string;
  color: string;
  /** Top edge of the annotated segment, in plot pixels. */
  segmentTop: number;
  segmentHeight: number;
};

/** One column's worth of work: what to annotate and what to stay clear of. */
export type CalloutColumn = {
  /** Horizontal centre of the column — boxes are centred on it. */
  centerX: number;
  /** Where the leader line runs; off-centre keeps it clear of inline labels. */
  lineX: number;
  items: CalloutInput[];
  obstacles: Box[];
};

export type CalloutStyle = {
  fontSize: number;
  height: number;
  /** Horizontal padding inside the box. */
  padX: number;
  /** Distance from the segment to a box placed above it. */
  gap: number;
  /** Extra spacing applied when pushing a box off another. */
  stack: number;
};

export type Callout = Box &
  Pick<CalloutInput, 'key' | 'label' | 'color'> & {
    lineX: number;
    lineFromY: number;
  };

export const DEFAULT_CALLOUT_STYLE: CalloutStyle = {
  fontSize: fontSize.xs,
  height: 16,
  padX: 6,
  gap: 10,
  stack: 4,
};

const overlaps = (a: Box, b: Box) =>
  a.x < b.x + b.width &&
  b.x < a.x + a.width &&
  a.y < b.y + b.height &&
  b.y < a.y + a.height;

/**
 * Lays out every column's callouts in one pass. Boxes are checked against those
 * already placed — including ones from neighbouring columns, which can reach
 * across when a column is narrower than its label.
 */
export function placeCallouts(
  columns: CalloutColumn[],
  measure: (label: string, fontSize: number) => number,
  style: CalloutStyle = DEFAULT_CALLOUT_STYLE,
): Callout[] {
  const placed: Callout[] = [];

  for (const { centerX, lineX, items, obstacles } of columns) {
    // bottom-up, so the lowest segment keeps the box closest to it
    const ordered = [...items].sort((a, b) => b.segmentTop - a.segmentTop);

    for (const item of ordered) {
      const width = measure(item.label, style.fontSize) + style.padX * 2;
      // A segment tall enough to hold the box keeps its value inside it; only
      // the short ones need to sit above the segment on a leader.
      const inside = item.segmentHeight >= style.height + style.gap;

      const box: Box = {
        x: centerX - width / 2,
        y: inside
          ? item.segmentTop + item.segmentHeight / 2 - style.height / 2
          : item.segmentTop - style.gap - style.height,
        width,
        height: style.height,
      };

      while ([...obstacles, ...placed].some((o) => overlaps(box, o)) && box.y > 0) {
        box.y -= style.height + style.stack;
      }

      placed.push({
        ...box,
        key: item.key,
        label: item.label,
        color: item.color,
        lineX,
        lineFromY: inside ? box.y + box.height : item.segmentTop,
      });
    }
  }

  return placed;
}
