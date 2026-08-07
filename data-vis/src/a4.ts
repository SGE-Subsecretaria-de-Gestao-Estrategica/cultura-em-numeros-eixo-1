import { mount } from 'svelte';
import '../node_modules/sniic-design-system/dist/sniic.css';
import './a4.css';
import A4 from './A4.svelte';
import { loadChartFont } from './lib/fonts';

// The charts measure text against the font they draw in, and only measure once.
await loadChartFont();

const app = mount(A4, {
  target: document.getElementById('app')!,
});

export default app;
