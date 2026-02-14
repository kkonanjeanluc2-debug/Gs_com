// vite.config.ts
import { defineConfig } from "file:///home/project/node_modules/vite/dist/node/index.js";
import vue from "file:///home/project/node_modules/@vitejs/plugin-vue/dist/index.mjs";
import fs from "fs";
import path from "path";
var __vite_injected_original_dirname = "/home/project";
var filterPublicFiles = () => {
  return {
    name: "filter-public-files",
    enforce: "pre",
    async buildStart() {
      const publicDir = path.resolve(__vite_injected_original_dirname, "public");
      const filesToKeep = ["image.png", "logo-ges-com.png"];
      const problematicPatterns = [
        /image copy.*\.png$/,
        /ges-com-logo\.png$/
      ];
      try {
        const files = fs.readdirSync(publicDir);
        for (const file of files) {
          if (filesToKeep.includes(file)) {
            continue;
          }
          const isProblematic = problematicPatterns.some((pattern) => pattern.test(file));
          if (isProblematic) {
            const filePath = path.join(publicDir, file);
            try {
              fs.unlinkSync(filePath);
            } catch (err) {
              console.warn(`Could not remove ${file}:`, err);
            }
          }
        }
      } catch (err) {
        console.warn("Could not clean public directory:", err);
      }
    }
  };
};
var vite_config_default = defineConfig({
  plugins: [vue(), filterPublicFiles()],
  build: {
    rollupOptions: {
      output: {
        entryFileNames: `assets/[name]-[hash].js`,
        chunkFileNames: `assets/[name]-[hash].js`,
        assetFileNames: `assets/[name]-[hash].[ext]`
      }
    },
    manifest: true
  },
  publicDir: "public",
  server: {
    headers: {
      "Cache-Control": "no-store"
    }
  }
});
export {
  vite_config_default as default
};
//# sourceMappingURL=data:application/json;base64,ewogICJ2ZXJzaW9uIjogMywKICAic291cmNlcyI6IFsidml0ZS5jb25maWcudHMiXSwKICAic291cmNlc0NvbnRlbnQiOiBbImNvbnN0IF9fdml0ZV9pbmplY3RlZF9vcmlnaW5hbF9kaXJuYW1lID0gXCIvaG9tZS9wcm9qZWN0XCI7Y29uc3QgX192aXRlX2luamVjdGVkX29yaWdpbmFsX2ZpbGVuYW1lID0gXCIvaG9tZS9wcm9qZWN0L3ZpdGUuY29uZmlnLnRzXCI7Y29uc3QgX192aXRlX2luamVjdGVkX29yaWdpbmFsX2ltcG9ydF9tZXRhX3VybCA9IFwiZmlsZTovLy9ob21lL3Byb2plY3Qvdml0ZS5jb25maWcudHNcIjtpbXBvcnQgeyBkZWZpbmVDb25maWcsIFBsdWdpbiB9IGZyb20gJ3ZpdGUnXG5pbXBvcnQgdnVlIGZyb20gJ0B2aXRlanMvcGx1Z2luLXZ1ZSdcbmltcG9ydCBmcyBmcm9tICdmcydcbmltcG9ydCBwYXRoIGZyb20gJ3BhdGgnXG5cbmNvbnN0IGZpbHRlclB1YmxpY0ZpbGVzID0gKCk6IFBsdWdpbiA9PiB7XG4gIHJldHVybiB7XG4gICAgbmFtZTogJ2ZpbHRlci1wdWJsaWMtZmlsZXMnLFxuICAgIGVuZm9yY2U6ICdwcmUnLFxuICAgIGFzeW5jIGJ1aWxkU3RhcnQoKSB7XG4gICAgICBjb25zdCBwdWJsaWNEaXIgPSBwYXRoLnJlc29sdmUoX19kaXJuYW1lLCAncHVibGljJylcbiAgICAgIGNvbnN0IGZpbGVzVG9LZWVwID0gWydpbWFnZS5wbmcnLCAnbG9nby1nZXMtY29tLnBuZyddXG4gICAgICBjb25zdCBwcm9ibGVtYXRpY1BhdHRlcm5zID0gW1xuICAgICAgICAvaW1hZ2UgY29weS4qXFwucG5nJC8sXG4gICAgICAgIC9nZXMtY29tLWxvZ29cXC5wbmckL1xuICAgICAgXVxuXG4gICAgICB0cnkge1xuICAgICAgICBjb25zdCBmaWxlcyA9IGZzLnJlYWRkaXJTeW5jKHB1YmxpY0RpcilcbiAgICAgICAgZm9yIChjb25zdCBmaWxlIG9mIGZpbGVzKSB7XG4gICAgICAgICAgaWYgKGZpbGVzVG9LZWVwLmluY2x1ZGVzKGZpbGUpKSB7XG4gICAgICAgICAgICBjb250aW51ZVxuICAgICAgICAgIH1cbiAgICAgICAgICBjb25zdCBpc1Byb2JsZW1hdGljID0gcHJvYmxlbWF0aWNQYXR0ZXJucy5zb21lKHBhdHRlcm4gPT4gcGF0dGVybi50ZXN0KGZpbGUpKVxuICAgICAgICAgIGlmIChpc1Byb2JsZW1hdGljKSB7XG4gICAgICAgICAgICBjb25zdCBmaWxlUGF0aCA9IHBhdGguam9pbihwdWJsaWNEaXIsIGZpbGUpXG4gICAgICAgICAgICB0cnkge1xuICAgICAgICAgICAgICBmcy51bmxpbmtTeW5jKGZpbGVQYXRoKVxuICAgICAgICAgICAgfSBjYXRjaCAoZXJyKSB7XG4gICAgICAgICAgICAgIGNvbnNvbGUud2FybihgQ291bGQgbm90IHJlbW92ZSAke2ZpbGV9OmAsIGVycilcbiAgICAgICAgICAgIH1cbiAgICAgICAgICB9XG4gICAgICAgIH1cbiAgICAgIH0gY2F0Y2ggKGVycikge1xuICAgICAgICBjb25zb2xlLndhcm4oJ0NvdWxkIG5vdCBjbGVhbiBwdWJsaWMgZGlyZWN0b3J5OicsIGVycilcbiAgICAgIH1cbiAgICB9XG4gIH1cbn1cblxuZXhwb3J0IGRlZmF1bHQgZGVmaW5lQ29uZmlnKHtcbiAgcGx1Z2luczogW3Z1ZSgpLCBmaWx0ZXJQdWJsaWNGaWxlcygpXSxcbiAgYnVpbGQ6IHtcbiAgICByb2xsdXBPcHRpb25zOiB7XG4gICAgICBvdXRwdXQ6IHtcbiAgICAgICAgZW50cnlGaWxlTmFtZXM6IGBhc3NldHMvW25hbWVdLVtoYXNoXS5qc2AsXG4gICAgICAgIGNodW5rRmlsZU5hbWVzOiBgYXNzZXRzL1tuYW1lXS1baGFzaF0uanNgLFxuICAgICAgICBhc3NldEZpbGVOYW1lczogYGFzc2V0cy9bbmFtZV0tW2hhc2hdLltleHRdYFxuICAgICAgfVxuICAgIH0sXG4gICAgbWFuaWZlc3Q6IHRydWUsXG4gIH0sXG4gIHB1YmxpY0RpcjogJ3B1YmxpYycsXG4gIHNlcnZlcjoge1xuICAgIGhlYWRlcnM6IHtcbiAgICAgICdDYWNoZS1Db250cm9sJzogJ25vLXN0b3JlJyxcbiAgICB9LFxuICB9LFxufSlcbiJdLAogICJtYXBwaW5ncyI6ICI7QUFBeU4sU0FBUyxvQkFBNEI7QUFDOVAsT0FBTyxTQUFTO0FBQ2hCLE9BQU8sUUFBUTtBQUNmLE9BQU8sVUFBVTtBQUhqQixJQUFNLG1DQUFtQztBQUt6QyxJQUFNLG9CQUFvQixNQUFjO0FBQ3RDLFNBQU87QUFBQSxJQUNMLE1BQU07QUFBQSxJQUNOLFNBQVM7QUFBQSxJQUNULE1BQU0sYUFBYTtBQUNqQixZQUFNLFlBQVksS0FBSyxRQUFRLGtDQUFXLFFBQVE7QUFDbEQsWUFBTSxjQUFjLENBQUMsYUFBYSxrQkFBa0I7QUFDcEQsWUFBTSxzQkFBc0I7QUFBQSxRQUMxQjtBQUFBLFFBQ0E7QUFBQSxNQUNGO0FBRUEsVUFBSTtBQUNGLGNBQU0sUUFBUSxHQUFHLFlBQVksU0FBUztBQUN0QyxtQkFBVyxRQUFRLE9BQU87QUFDeEIsY0FBSSxZQUFZLFNBQVMsSUFBSSxHQUFHO0FBQzlCO0FBQUEsVUFDRjtBQUNBLGdCQUFNLGdCQUFnQixvQkFBb0IsS0FBSyxhQUFXLFFBQVEsS0FBSyxJQUFJLENBQUM7QUFDNUUsY0FBSSxlQUFlO0FBQ2pCLGtCQUFNLFdBQVcsS0FBSyxLQUFLLFdBQVcsSUFBSTtBQUMxQyxnQkFBSTtBQUNGLGlCQUFHLFdBQVcsUUFBUTtBQUFBLFlBQ3hCLFNBQVMsS0FBSztBQUNaLHNCQUFRLEtBQUssb0JBQW9CLElBQUksS0FBSyxHQUFHO0FBQUEsWUFDL0M7QUFBQSxVQUNGO0FBQUEsUUFDRjtBQUFBLE1BQ0YsU0FBUyxLQUFLO0FBQ1osZ0JBQVEsS0FBSyxxQ0FBcUMsR0FBRztBQUFBLE1BQ3ZEO0FBQUEsSUFDRjtBQUFBLEVBQ0Y7QUFDRjtBQUVBLElBQU8sc0JBQVEsYUFBYTtBQUFBLEVBQzFCLFNBQVMsQ0FBQyxJQUFJLEdBQUcsa0JBQWtCLENBQUM7QUFBQSxFQUNwQyxPQUFPO0FBQUEsSUFDTCxlQUFlO0FBQUEsTUFDYixRQUFRO0FBQUEsUUFDTixnQkFBZ0I7QUFBQSxRQUNoQixnQkFBZ0I7QUFBQSxRQUNoQixnQkFBZ0I7QUFBQSxNQUNsQjtBQUFBLElBQ0Y7QUFBQSxJQUNBLFVBQVU7QUFBQSxFQUNaO0FBQUEsRUFDQSxXQUFXO0FBQUEsRUFDWCxRQUFRO0FBQUEsSUFDTixTQUFTO0FBQUEsTUFDUCxpQkFBaUI7QUFBQSxJQUNuQjtBQUFBLEVBQ0Y7QUFDRixDQUFDOyIsCiAgIm5hbWVzIjogW10KfQo=
