<script lang="ts">
  import { getContrastColor, Text } from 'sniic-design-system';
  // aliased: `fontSize` and `fontFamily` are prop names below
  import {
    fontFamily as defaultFontFamily,
    fontSize as scale,
    measureLabel,
  } from './tokens';

  interface Props {
    items?: { label: string; color: string }[];
    top?: number;
    left?: number;
    fontSize?: number;
    fontFamily?: string;
    fontWeight?: string | number;
    /** Horizontal padding between the text and the chip edge. */
    padX?: number;
    /** Rounds the two ends of the strip only — see `chipPath`. */
    radius?: number;
  }

  let {
    items = [],
    top = 0,
    left = 0,
    fontSize = scale.sm,
    fontFamily = defaultFontFamily,
    fontWeight = 600,
    padX = 10,
    radius = 4,
  }: Props = $props();

  const height = $derived(Math.round(fontSize * 1.9));

  const chips = $derived.by(() => {
    let cursor = left;
    return items.map((item, index) => {
      const width = measureLabel(item.label, fontSize, Number(fontWeight)) + padX * 2;
      const x = cursor;
      cursor += width;
      return {
        ...item,
        index,
        x,
        width,
        first: index === 0,
        last: index === items.length - 1,
      };
    });
  });

  /**
   * The chips sit flush against each other, so rounding every corner would
   * notch the joins — only the outer ends of the strip are rounded.
   */
  function chipPath(x: number, width: number, left: number, right: number) {
    return [
      `M${x + left},${top}`,
      `H${x + width - right}`,
      right ? `A${right},${right} 0 0 1 ${x + width},${top + right}` : '',
      `V${top + height - right}`,
      right ? `A${right},${right} 0 0 1 ${x + width - right},${top + height}` : '',
      `H${x + left}`,
      left ? `A${left},${left} 0 0 1 ${x},${top + height - left}` : '',
      `V${top + left}`,
      left ? `A${left},${left} 0 0 1 ${x + left},${top}` : '',
      'Z',
    ]
      .filter(Boolean)
      .join(' ');
  }
</script>

<g class="legend">
  {#each chips as chip (chip.label)}
    <path
      d={chipPath(chip.x, chip.width, chip.first ? radius : 0, chip.last ? radius : 0)}
      fill={chip.color}
    />

    <Text
      x={chip.x + chip.width / 2}
      y={top + height / 2}
      textAnchor="middle"
      verticalAnchor="middle"
      {fontSize}
      {fontFamily}
      {fontWeight}
      fill={getContrastColor(chip.color)}
      text={chip.label}
    />
  {/each}
</g>
