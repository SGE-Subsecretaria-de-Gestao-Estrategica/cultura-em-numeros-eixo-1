/**
 * Falha se alguma letra desenhada dentro de um gráfico sair em outra fonte que
 * não a General Sans Variable.
 *
 * Declarar a família em todo `<text>` não basta como garantia: o design system
 * traz a Rawline no tema e a Arial em alguns defaults, o `<Text>` dele resolve
 * `fontFamily` por mesclagem, e uma família declarada mas não carregada é
 * substituída em silêncio — em Figma, pela Inter. Nenhuma dessas trocas
 * aparece no atributo; todas aparecem no glifo.
 *
 * Por isso a checagem não lê o SVG, e sim pergunta ao Chrome que arquivo de
 * fonte ele de fato usou em cada nó, via `CSS.getPlatformFontsForNode`.
 *
 *     node scripts/check-fonts.mjs
 */

import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { chromium } from 'playwright';
import { createServer } from 'vite';

const PROJECT_DIR = path.dirname(path.dirname(fileURLToPath(import.meta.url)));
const PORT = 5234;

/** As mesmas páginas que a exportação rasteriza. */
const PAGES = ['/a4.html', '/gestao.html'];

const ESPERADA = 'General Sans Variable';

const server = await createServer({
  root: PROJECT_DIR,
  server: { port: PORT, strictPort: true },
  logLevel: 'warn',
});
await server.listen();

const browser = await chromium.launch();
let intrusos = 0;
try {
  const page = await browser.newPage({ viewport: { width: 1200, height: 1600 } });
  const cdp = await page.context().newCDPSession(page);
  await cdp.send('DOM.enable');
  await cdp.send('CSS.enable');

  for (const url of PAGES) {
    await page.goto(`http://localhost:${PORT}${url}`, { waitUntil: 'networkidle' });
    // as páginas só montam depois da fonte; isto cobre a pintura seguinte
    await page.waitForFunction(() => document.fonts.status === 'loaded');
    await page.waitForTimeout(500);

    const { root } = await cdp.send('DOM.getDocument', { depth: -1, pierce: true });
    const { nodeIds } = await cdp.send('DOM.querySelectorAll', {
      nodeId: root.nodeId,
      selector: 'figure svg text',
    });

    const tally = new Map();
    for (const nodeId of nodeIds) {
      const { fonts } = await cdp.send('CSS.getPlatformFontsForNode', { nodeId });
      for (const { familyName, glyphCount } of fonts) {
        tally.set(familyName, (tally.get(familyName) ?? 0) + glyphCount);
      }
    }

    const resumo = [...tally].map(([f, n]) => `${f} (${n})`).join(', ');
    const outras = [...tally.keys()].filter((f) => f !== ESPERADA);
    intrusos += outras.length;
    console.log(`${outras.length ? '✗' : '✓'} ${url}  ${resumo || 'nenhum texto encontrado'}`);
  }
} finally {
  await browser.close();
  await server.close();
}

if (intrusos) {
  console.error(`\nHá texto de gráfico fora da ${ESPERADA}.`);
  process.exit(1);
}
