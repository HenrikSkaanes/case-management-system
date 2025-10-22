import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// Vite configuration - this tells Vite how to build our React app
export default defineConfig({
  plugins: [react()],
  server: {
    port: 5173,  // Frontend runs on this port
    proxy: {
      // Proxy API calls to backend during development
      '/api': {
        target: 'http://localhost:8000',  // Backend URL
        changeOrigin: true,
      }
    }
  }
})
