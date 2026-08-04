<script lang="ts">
  import { Text } from 'sniic-design-system';
  import type { Callout, CalloutStyle } from './callouts';

  interface Props {
    callout: Callout;
    style: CalloutStyle;
    /** Box fill — the chart background, so the box reads as a sticker. */
    background: string;
    textColor: string;
    fontFamily?: string;
    fontWeight?: string | number;
  }

  let { callout, style, background, textColor, fontFamily, fontWeight }: Props = $props();
</script>

<rect
  x={callout.x}
  y={callout.y}
  width={callout.width}
  height={callout.height}
  fill={background}
  stroke={callout.color}
  stroke-width={1}
/>

<Text
  x={callout.x + callout.width / 2}
  y={callout.y + callout.height / 2}
  textAnchor="middle"
  verticalAnchor="middle"
  fontSize={style.fontSize}
  {fontWeight}
  {fontFamily}
  fill={textColor}
  text={callout.label}
/>
