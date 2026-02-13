import { defineConfig, Plugin } from 'vite'
import vue from '@vitejs/plugin-vue'
import fs from 'fs'
import path from 'path'

const filterPublicFiles = (): Plugin => {
  return {
    name: 'filter-public-files',
    enforce: 'pre',
    async buildStart() {
      const publicDir = path.resolve(__dirname, 'public')
      const problematicPatterns = [
        /image copy.*\.png$/,
        /ges-com-logo\.png$/
      ]

      try {
        const files = fs.readdirSync(publicDir)
        for (const file of files) {
          const isProblematic = problematicPatterns.some(pattern => pattern.test(file))
          if (isProblematic && file !== 'image.png') {
            const filePath = path.join(publicDir, file)
            try {
              fs.unlinkSync(filePath)
            } catch (err) {
              console.warn(`Could not remove ${file}:`, err)
            }
          }
        }
      } catch (err) {
        console.warn('Could not clean public directory:', err)
      }
    }
  }
}

export default defineConfig({
  plugins: [vue(), filterPublicFiles()],
  build: {
    rollupOptions: {
      output: {
        entryFileNames: `assets/[name]-[hash].js`,
        chunkFileNames: `assets/[name]-[hash].js`,
        assetFileNames: `assets/[name]-[hash].[ext]`
      }
    },
    manifest: true,
  },
  publicDir: 'public',
  server: {
    headers: {
      'Cache-Control': 'no-store',
    },
  },
})
