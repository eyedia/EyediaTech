import { defineConfig, loadEnv, type Plugin } from 'vite'
import { dirname, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'

const __dirname = dirname(fileURLToPath(import.meta.url))

function googleAnalyticsPlugin(measurementId: string): Plugin {
  if (!measurementId) {
    return { name: 'google-analytics' }
  }

  const snippet = `    <!-- Google tag (gtag.js) -->
    <script async src="https://www.googletagmanager.com/gtag/js?id=${measurementId}"></script>
    <script>
      window.dataLayer = window.dataLayer || [];
      function gtag(){dataLayer.push(arguments);}
      gtag('js', new Date());
      gtag('config', '${measurementId}');
    </script>`

  return {
    name: 'google-analytics',
    transformIndexHtml(html) {
      return html.replace('</head>', `${snippet}\n  </head>`)
    },
  }
}

export default defineConfig(({ mode }) => {
  const env = loadEnv(mode, process.cwd(), '')
  const measurementId = env.GA_MEASUREMENT_ID ?? ''

  return {
    appType: 'mpa',
    plugins: [googleAnalyticsPlugin(measurementId)],
    build: {
      rollupOptions: {
        input: {
          home: resolve(__dirname, 'index.html'),
          products: resolve(__dirname, 'products/index.html'),
          blog: resolve(__dirname, 'blog/index.html'),
          articleBeyondMegapixels: resolve(__dirname, 'blog/beyond-the-megapixels.html'),
          articleNotJustPhotos: resolve(__dirname, 'blog/your-photos-are-not-just-photos-anymore.html'),
        },
      },
    },
  }
})