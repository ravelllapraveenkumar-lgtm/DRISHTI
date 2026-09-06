import tailwindcss from '@tailwindcss/vite';
import react from '@vitejs/plugin-react';
import path from 'path';
import { defineConfig } from 'vite';
import http from 'http';
import { spawn } from 'child_process';

function fastapiDevPlugin() {
  return {
    name: 'fastapi-dev-plugin',
    configureServer() {
      const checkBackend = () => {
        const req = http.get('http://127.0.0.1:8001/health', (res) => {
          if (res.statusCode === 200) {
            console.log('[DRISHTI] FastAPI backend online on port 8001');
          }
        });
        req.on('error', () => {
          console.log('[DRISHTI] Spawning FastAPI backend on port 8001...');
          try {
            const proc = spawn('python3', ['-m', 'uvicorn', 'backend.app.main:app', '--host', '127.0.0.1', '--port', '8001'], {
              detached: true,
              stdio: 'ignore'
            });
            proc.unref();
          } catch (e) {
            console.error('[DRISHTI] Failed to spawn FastAPI:', e);
          }
        });
      };
      checkBackend();
    }
  };
}

export default defineConfig(() => {
  return {
    plugins: [react(), tailwindcss(), fastapiDevPlugin()],
    resolve: {
      alias: {
        '@': path.resolve(__dirname, '.'),
      },
    },
    server: {
      port: 3000,
      host: '0.0.0.0',
      proxy: {
        '/api': {
          target: 'http://127.0.0.1:8001',
          changeOrigin: true,
        },
        '/health': {
          target: 'http://127.0.0.1:8001',
          changeOrigin: true,
        },
      },
      hmr: process.env.DISABLE_HMR !== 'true',
      watch: process.env.DISABLE_HMR === 'true' ? null : {
        ignored: ['**/mobile/**', '**/build/**', '**/.dart_tool/**', '**/.gradle/**'],
      },
    },
  };
});
