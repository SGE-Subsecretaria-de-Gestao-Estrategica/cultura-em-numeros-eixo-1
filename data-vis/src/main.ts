import { mount } from 'svelte'
import '../node_modules/sniic-design-system/dist/sniic.css'
import './app.css'
import App from './App.svelte'
import { loadChartFont } from './lib/fonts'

// The charts measure text against the font they draw in, and only measure once.
await loadChartFont()

const app = mount(App, {
  target: document.getElementById('app')!,
})

export default app
