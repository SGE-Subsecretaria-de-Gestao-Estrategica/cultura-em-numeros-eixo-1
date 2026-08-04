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
export const tickLabelProps = (fill: string, size: number = fontSize.md) => ({
  fontFamily,
  fontSize: size,
  fontWeight: 500,
  fill,
  'font-family': fontFamily,
  'font-size': size,
  'font-weight': 500,
});
