<script lang="ts">
  import { getContrastColor, Text } from 'sniic-design-system';
  import { layoutLegend, type LegendItem } from './legend';
  // aliased: `fontSize` and `fontFamily` are prop names below
  import { fontFamily as defaultFontFamily, fontSize as scale } from './tokens';

  interface Props {
    items?: LegendItem[];
    top?: number;
    left?: number;
    fontSize?: number;
    fontFamily?: string;
    fontWeight?: string | number;
    /** Horizontal padding between the text and the chip edge. */
    padX?: number;
    /** Rounds the two ends of each row only — see `chipPath`. */
    radius?: number;
    /**
     * Available width; the strip wraps to a new row past it. `Infinity` keeps
     * the single-row behaviour. The caller reserves the vertical space with
     * `layoutLegend`, which is the same layout this component draws.
     */
    maxWidth?: number;
    /** Vertical space between two rows of chips. */
    rowGap?: number;
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
    maxWidth = Infinity,
    rowGap = 4,
  }: Props = $props();

  const layout = $derived(
    layoutLegend(items, { fontSize, fontWeight: Number(fontWeight), padX, maxWidth, rowGap }),
  );

  /**
   * As pastilhas ficam encostadas umas nas outras, então arredondar todos os
   * cantos entalharia as junções — só as pontas de cada linha são arredondadas.
   */
  function chipPath(
    x: number,
    y: number,
    width: number,
    height: number,
    left: number,
    right: number,
  ) {
    return [
      `M${x + left},${y}`,
      `H${x + width - right}`,
      right ? `A${right},${right} 0 0 1 ${x + width},${y + right}` : '',
      `V${y + height - right}`,
      right ? `A${right},${right} 0 0 1 ${x + width - right},${y + height}` : '',
      `H${x + left}`,
      left ? `A${left},${left} 0 0 1 ${x},${y + height - left}` : '',
      `V${y + left}`,
      left ? `A${left},${left} 0 0 1 ${x + left},${y}` : '',
      'Z',
    ]
      .filter(Boolean)
      .join(' ');
  }
</script>

<g class="legend">
  {#each layout.chips as chip (chip.label)}
    {@const x = left + chip.x}
    {@const y = top + chip.y}

    <path
      d={chipPath(
        x,
        y,
        chip.width,
        layout.chipHeight,
        chip.first ? radius : 0,
        chip.last ? radius : 0,
      )}
      fill={chip.color}
    />

    <Text
      x={x + chip.width / 2}
      y={y + layout.chipHeight / 2}
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
