/**
 * Rasterizes the print charts to PNG at press resolution.
 *
 * The cards are vector and carry their own background, so quality is decided
 * entirely by the raster grid we ask for. `SCALE` multiplies each card's
 * viewBox: at 4x a 1368-unit card comes out 5472 px wide, which is 818 dpi
 * across the 170 mm A4 text column the charts are sized for — well past the
 * 300 dpi a press asks for, and the same width as the widest existing export.
 *
 * Boots its own Vite dev server, so no build and no running server needed:
 *     node scripts/export-png.mjs [--scale 4] [--out exports]
 */

import { mkdir } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { chromium } from 'playwright';
import { createServer } from 'vite';

const PROJECT_DIR = path.dirname(path.dirname(fileURLToPath(import.meta.url)));

const PORT = 5233;

/**
 * The A4 proof pages — one chart per sheet, at their authored sizes. `bg=0`
 * drops the cards' own background so the exports composite onto whatever page
 * they are placed in. Open the same URL to see exactly what is rasterized.
 *
 * `names` is positional: one output name per figure, in the order the figures
 * appear on that page. A page whose figure count stops matching its name list
 * fails the run rather than writing a chart under a neighbour's name.
 */
const PAGES = [
  {
    page: '/a4.html?bg=0',
    names: [
      'a4-cabo-de-guerra-efeito-indutor-substituicao',
      'a4-perfil-mudanca-municipal-por-porte',
      'a4-municipal-por-fonte-ribbon',
    ],
  },
  {
    page: '/gestao.html?bg=0',
    names: [
      'a4-tripe-institucional',
      'a4-tripe-mapa',
      'a4-tripe-regiao',
      'a4-estrutura-orgao-gestor',
      'a4-estrutura-mapa',
      'a4-genero-titulares',
      'a4-escolaridade-tripe',
      'a4-execucao-aldir-blanc',
      'a4-execucao-aldir-blanc-regiao',
      'a4-equipamentos-culturais',
    ],
  },
];

function arg(flag, fallback) {
  const i = process.argv.indexOf(flag);
  return i === -1 ? fallback : process.argv[i + 1];
}

const SCALE = Number(arg('--scale', 4));
const OUT_DIR = path.resolve(PROJECT_DIR, arg('--out', 'exports'));

const server = await createServer({
  root: PROJECT_DIR,
  server: { port: PORT, strictPort: true },
  logLevel: 'warn',
});
await server.listen();

const browser = await chromium.launch();
try {
  await mkdir(OUT_DIR, { recursive: true });

  const page = await browser.newPage({ viewport: { width: 1200, height: 1600 } });
  const failures = [];
  page.on('pageerror', (e) => failures.push(String(e)));

  for (const { page: url, names } of PAGES) {
    await page.goto(`http://localhost:${PORT}${url}`, { waitUntil: 'networkidle' });
    // the page awaits the chart font before mounting; this covers the paint after
    await page.waitForFunction(() => document.fonts.status === 'loaded');
    await page.waitForTimeout(500);

    // The cards are already transparent via `bg=0`, but the proof page still
    // paints a sheet and a desk behind them, and `omitBackground` only drops the
    // browser's own default white.
    //
    // Hiding the rest of the page matters for the same reason: an element
    // screenshot captures whatever is painted in that region, and through a
    // transparent card that means the sheet's heading and the next chart show up
    // inside the export.
    await page.addStyleTag({
      content: `
        :root, body, .sheet { background: transparent !important; }
        body * { visibility: hidden !important; }
        .export-target, .export-target * { visibility: visible !important; }
      `,
    });

    const charts = await page.locator('figure > div > svg').all();
    if (charts.length !== names.length) {
      throw new Error(`esperava ${names.length} gráficos em ${url}, encontrei ${charts.length}`);
    }

    for (const [index, chart] of charts.entries()) {
      // Blow the card up to the target raster size. The sheet is laid out in
      // millimetres, so the enlarged card would overflow it and get clipped —
      // hence `position: fixed`, which takes it out of that flow entirely.
      const size = await chart.evaluate((el, scale) => {
        const box = el.viewBox.baseVal;
        const width = Math.round(box.width * scale);
        const height = Math.round(box.height * scale);
        el.style.cssText = `position:fixed;top:0;left:0;width:${width}px;height:${height}px;max-width:none;z-index:9999`;
        el.classList.add('export-target');
        return { width, height };
      }, SCALE);

      const file = path.join(OUT_DIR, `${names[index]}.png`);
      // no page background: the card's own rounded corners stay transparent
      await chart.screenshot({ path: file, omitBackground: true });

      await chart.evaluate((el) => {
        el.style.cssText = '';
        el.classList.remove('export-target');
      });

      const mm = 170;
      const dpi = Math.round(size.width / (mm / 25.4));
      console.log(
        `${path.relative(PROJECT_DIR, file)}  ${size.width}×${size.height} px  (${dpi} dpi a ${mm} mm)`,
      );
    }
  }

  if (failures.length) throw new Error(`erros nas páginas: ${failures.join(' · ')}`);
} finally {
  await browser.close();
  await server.close();
}
