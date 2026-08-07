<script lang="ts">
  /**
   * A pre-wrapped run of text, one `<Text>` per line.
   *
   * The lines come in already broken (see `wrapText`) rather than being handed
   * to `<Text>`'s own `width`, so the caller knows the line count in advance
   * and can reserve the vertical space the block will take.
   */
  import { Text } from 'sniic-design-system';

  interface Props {
    lines: string[];
    x: number;
    /** Top of the first line — every line uses `verticalAnchor="start"`. */
    y: number;
    lineHeight: number;
    fontSize?: string | number;
    fontFamily?: string;
    fontWeight?: string | number;
    fill?: string;
    textAnchor?: 'start' | 'middle' | 'end';
  }

  let {
    lines,
    x,
    y,
    lineHeight,
    fontSize,
    fontFamily,
    fontWeight,
    fill,
    textAnchor = 'start',
  }: Props = $props();
</script>

{#each lines as line, index (index)}
  <Text
    {x}
    y={y + index * lineHeight}
    {textAnchor}
    verticalAnchor="start"
    {fontSize}
    {fontWeight}
    {fontFamily}
    {fill}
    text={line}
  />
{/each}
