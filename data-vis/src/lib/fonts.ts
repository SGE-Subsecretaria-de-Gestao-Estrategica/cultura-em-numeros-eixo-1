import { fontFamily } from './tokens';

/**
 * Forces the chart typeface in before anything renders.
 *
 * The charts measure text on a canvas to decide line breaks, whether a value
 * fits inside its segment, and how wide a legend chip is. Until General Sans is
 * really loaded that canvas reports a fallback face — and nothing re-measures
 * afterwards, so every one of those decisions stays wrong.
 *
 * `document.fonts.ready` alone does not do it: a webfont is only fetched once
 * something on the page asks for it, so before the first chart exists there is
 * nothing pending and `ready` resolves immediately. `load()` is what actually
 * requests the file. The weights below are the ones the charts draw in; one
 * request covers them all, since the family ships as a single variable file.
 */
export async function loadChartFont(): Promise<void> {
  if (typeof document === 'undefined' || !document.fonts) return;

  await Promise.all(
    [400, 500, 600].map((weight) =>
      document.fonts.load(`${weight} 12px "${fontFamily}"`),
    ),
  );
  await document.fonts.ready;
}
