import { defineConfig } from 'vite'
import { resolve } from 'node:path'

export default defineConfig({
  appType: 'mpa',
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
})