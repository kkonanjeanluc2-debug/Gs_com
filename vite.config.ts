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
      const filesToKeep = ['image.png', 'logo-ges-com.png']
      const problematicPatterns = [
        /image copy.*\.png$/,
        /ges-com-logo\.png$/
      ]

      try {
        const files = fs.readdirSync(publicDir)
        for (const file of files) {
          if (filesToKeep.includes(file)) {
            continue
          }
          const isProblematic = problematicPatterns.some(pattern => pattern.test(file))
          if (isProblematic) {
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
  base: './',
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
