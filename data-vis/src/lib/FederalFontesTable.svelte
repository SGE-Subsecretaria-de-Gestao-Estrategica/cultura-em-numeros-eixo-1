<script lang="ts">
  /**
   * A matriz completa: as oito fontes, ano a ano.
   *
   * Existe porque o gráfico não pode carregá-la. Oito categorias que todas
   * carregam significado passam do teto em que a cor ainda distingue séries, e
   * os 184 valores não cabem em coluna nenhuma nesta largura de banda — a
   * recomendação, nesse caso, é gráfico *mais* tabela, com o gráfico contando a
   * trajetória e a tabela guardando os números.
   *
   * É HTML, não SVG: não entra no export do gráfico, e ganha de graça a
   * semântica de tabela que um leitor de tela sabe navegar.
   */
  import { BRL } from 'sniic-design-system';

  type Row = { label: string; [fonte: string]: string | number };

  interface Props {
    data: Row[];
    keys: string[];
    /** Nomes curtos para o cabeçalho; cai no nome completo quando ausente. */
    labels?: Record<string, string>;
    caption?: string;
    /** Cor por fonte, na ordem de `keys` — o pontinho ao lado do cabeçalho. */
    colors?: Record<string, string>;
  }

  let { data, keys, labels = {}, caption, colors = {} }: Props = $props();

  const valor = (row: Row, key: string) => Number(row[key]) || 0;
  const total = (row: Row) => keys.reduce((s, k) => s + valor(row, k), 0);

  /** Um traço, não um zero: a fonte não existia naquele ano. */
  const fmt = (v: number) => (v > 0 ? BRL.format(v) : '–');
</script>

<figure class="wrap">
  {#if caption}<figcaption>{caption}</figcaption>{/if}

  <div class="scroll">
    <table>
      <thead>
        <tr>
          <th scope="col" class="ano">Ano</th>
          {#each keys as key (key)}
            <th scope="col">
              {#if colors[key]}
                <span class="dot" style="background:{colors[key]}"></span>
              {/if}{labels[key] ?? key}
            </th>
          {/each}
          <th scope="col" class="total">Total</th>
        </tr>
      </thead>
      <tbody>
        {#each data as row (row.label)}
          <tr>
            <th scope="row" class="ano">{row.label}</th>
            {#each keys as key (key)}
              <td class:vazio={valor(row, key) === 0}>{fmt(valor(row, key))}</td>
            {/each}
            <td class="total">{fmt(total(row))}</td>
          </tr>
        {/each}
      </tbody>
    </table>
  </div>
</figure>

<style>
  .wrap {
    margin: 0;
    font: 400 13px/1.45 'General Sans Variable', system-ui, sans-serif;
    color: #33382e;
  }

  figcaption {
    font-size: 12px;
    color: #6b6f64;
    margin-bottom: 10px;
  }

  /* a tabela é larga; ela rola dentro do próprio contêiner e não empurra a página */
  .scroll {
    overflow-x: auto;
  }

  table {
    border-collapse: collapse;
    font-variant-numeric: tabular-nums;
    white-space: nowrap;
  }

  th,
  td {
    padding: 5px 12px;
    text-align: right;
    border-bottom: 1px solid #eae5e1;
  }

  thead th {
    font-weight: 600;
    font-size: 12px;
    color: #4d5148;
    border-bottom: 1px solid #cec2bb;
    vertical-align: bottom;
  }

  .ano {
    text-align: left;
    font-weight: 600;
    position: sticky;
    left: 0;
    background: #fff;
  }

  .total {
    font-weight: 600;
    border-left: 1px solid #eae5e1;
  }

  .vazio {
    color: #a8a49c;
  }

  .dot {
    display: inline-block;
    width: 8px;
    height: 8px;
    border-radius: 2px;
    margin-right: 6px;
    vertical-align: baseline;
  }

  tbody tr:hover td,
  tbody tr:hover .ano {
    background: #f7f5f2;
  }
</style>
