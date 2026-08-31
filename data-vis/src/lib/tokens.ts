/**
 * Type tokens for the charts.
 *
 * The design system's theme only carries `md` and `lg`. The two smaller steps
 * exist for text written inside chart geometry — values in a thin segment, a
 * callout box — where 12px does not fit.
 */

import { measureTextWidth } from 'sniic-design-system';

export const fontSize = {
  xs: 9,
  sm: 10.5,
  md: 12,
  lg: 16,
};

/**
 * The theme's family. Named here so every label can ask for it explicitly
 * rather than relying on inheritance: charts are exported as a standalone SVG,
 * where nothing outside the chart is around to inherit from.
 */
export const fontFamily = 'General Sans Variable';

/**
 * `measureTextWidth` defaults to the design system's Rawline stack at weight
 * 700, so label fits were being measured in a font the chart never draws.
 * Bind the family once; callers pass the weight they actually render at.
 */
export const measureLabel = (text: string, size: number, weight = 600) =>
  measureTextWidth(text, size, fontFamily, weight);

/**
 * The design system's `labelFitsInBar` measures with its own default font, so
 * it answers for text the chart never draws. Same geometry and padding as the
 * original, measured in the family and weight actually rendered.
 */
export const labelFitsInBar = (
  text: string,
  size: number,
  availableWidth: number,
  weight = 600,
  padding = 6,
  rightMargin = 4,
) =>
  availableWidth > 0 &&
  availableWidth >= padding + measureLabel(text, size, weight) + rightMargin;

/** Text column of an A4 portrait page, in millimetres — the figure width. */
export const A4_TEXT_WIDTH_MM = 170;

/** 9 pt, in millimetres. The size `fontSize.md` is meant to print at. */
const TARGET_MM = 3.175;

/**
 * How much to multiply the type scale — and every fixed measure alongside it —
 * for a card authored at `width` units.
 *
 * Type in an SVG is absolute, so its printed size is decided by the ratio of
 * font size to chart width, not by either alone. This is the same formula the
 * RibbonChart A4 stories use, so a card authored through it prints at exactly
 * the sizes those figures do: `md` 9 pt, `sm` 7.9 pt, `xs` 6.8 pt, and a 20-unit
 * title 15 pt.
 *
 * Everything fixed scales with it, not just the glyphs: margins, gaps, corner
 * radii, band heights. Scaling the type alone would leave the chrome
 * proportionally larger and squeeze the plot.
 */
export const a4Scale = (width: number) => (TARGET_MM / A4_TEXT_WIDTH_MM) * (width / fontSize.md);

/**
 * Greedy word wrap, measured in the family the chart actually draws.
 *
 * `<Text>` takes a `width` and wraps on its own, but it measures with the
 * design system's default stack rather than the one it renders in, so its line
 * breaks land in the wrong place. Wrapping here also makes the line count known
 * before the chart is laid out, which is what lets the card reserve the right
 * margin for a title that turns out to need two lines.
 *
 * A word longer than `maxWidth` gets a line to itself rather than being cut.
 */
export const wrapText = (
  text: string,
  size: number,
  maxWidth: number,
  weight = 400,
): string[] => {
  if (!text) return [];

  const lines: string[] = [];
  let current = '';

  for (const word of text.split(/\s+/)) {
    const candidate = current ? `${current} ${word}` : word;
    if (current && measureLabel(candidate, size, weight) > maxWidth) {
      lines.push(current);
      current = word;
    } else {
      current = candidate;
    }
  }
  if (current) lines.push(current);

  return lines;
};

/**
 * Axis tick styling, passed explicitly on every `<Axis>` — in both spellings,
 * which is not redundant.
 *
 * The axis merges its `tickLabelProps` deeply across props, theme and defaults,
 * and the theme keys them in kebab-case. So the two spellings coexist on the
 * resolved object and go to different places: `Text` pulls the camelCase ones
 * into named props (they land on the wrapper `<svg>` and drive the renderer's
 * label-offset math) and passes the kebab-case ones straight through as
 * attributes on the `<text>` itself, where they win. Send only camelCase and
 * the theme's kebab-case values silently override the size you asked for.
 */
export const tickLabelProps = (
  fill: string,
  size: number = fontSize.md,
  weight: number = 500,
) => ({
  fontFamily,
  fontSize: size,
  fontWeight: weight,
  fill,
  'font-family': fontFamily,
  'font-size': size,
  'font-weight': weight,
});


export const colors = {
  primary : "#D5362A",
  primaryVariant : "#EC6596",
  secondary:"#4B2F92",
  secondaryVariant: "#4F68DA",
  accent: "#4ACA5D",
}

export const colorGradients = {
  // Gradiente original (fornecido como referência)
  primary: ["#C4352E", "#CD4640", "#D65651", "#DF6362", "#E77474"],

  // Base: #EC6596 (primaryVariant)
  primaryVariant: ["#E75B8E", "#E779A1", "#EC8DB0", "#F2A1BF", "#F6B6CE"],

  // Base: #4B2F92 (secondary)
  secondary: ["#472F83", "#553C96", "#5E41AA", "#6846BE", "#7654C9"],

  // Base: #4F68DA (secondaryVariant)
  secondaryVariant: ["#4660D2", "#6378D4", "#7588DB", "#8798E3", "#99A8EA"],

  // Base: #4ACA5D (accent)
  accent: ["#42C255", "#5EC56D", "#6FCE7D", "#7FD78C", "#90E09C"]
};