<script lang="ts">
  /**
   * Harness das stories: envolve o gráfico e põe o botão de download acima
   * dele. Só é usado pelas stories — nenhuma página do relatório o importa.
   *
   * O botão fica fora do `<svg>`: tudo o que o componente desenha vive dentro
   * dele e seria serializado no arquivo exportado.
   *
   * O SVG é procurado no DOM em vez de vir por `bind:svgEl` porque o autodocs
   * renderiza todas as stories numa página só: cada moldura acha o gráfico que
   * está dentro dela, sem precisar de um registro de referências por story.
   * `querySelector` devolve o primeiro `<svg>` da subárvore, que é o de fora —
   * os `<Text>` do design system aninham os deles mais fundo.
   */
  import type { Snippet } from 'svelte';
  import { downloadSvg } from 'sniic-design-system';

  let { name, children }: { name: string; children: Snippet } = $props();

  let root: HTMLDivElement;

  function save() {
    const svg = root.querySelector('svg');
    if (svg) downloadSvg(svg as SVGSVGElement, `${name}.svg`);
  }
</script>

<div class="story" bind:this={root}>
  <button class="export" onclick={save}>Baixar SVG</button>
  {@render children()}
</div>

<style>
  .story {
    display: flex;
    flex-direction: column;
    gap: 8px;
  }

  .export {
    align-self: flex-end;
    font: 500 12px/1 'General Sans Variable', system-ui, sans-serif;
    color: #4d5148;
    background: transparent;
    border: 1px solid #cec2bb;
    border-radius: 4px;
    padding: 7px 12px;
    cursor: pointer;
  }

  .export:hover {
    color: #33382e;
    border-color: #4d5148;
  }
</style>
