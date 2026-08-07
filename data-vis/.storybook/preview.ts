import type { Preview } from '@storybook/svelte-vite'
import '../node_modules/sniic-design-system/dist/sniic.css'
import '../src/app.css'
import { loadChartFont } from '../src/lib/fonts'

const preview: Preview = {
  // The charts measure text against the font they draw in, and only measure
  // once — see loadChartFont.
  loaders: [async () => { await loadChartFont(); return {}; }],

  parameters: {
    controls: {
      matchers: {
       color: /(background|color)$/i,
       date: /Date$/i,
      },
    },

    a11y: {
      // 'todo' - show a11y violations in the test UI only
      // 'error' - fail CI on a11y violations
      // 'off' - skip a11y checks entirely
      test: 'todo'
    }
  },
};

export default preview;