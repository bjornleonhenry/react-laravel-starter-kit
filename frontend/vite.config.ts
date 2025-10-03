import { reactRouter } from "@react-router/dev/vite";
import tailwindcss from "@tailwindcss/vite";
import { defineConfig } from 'vite';
import tsconfigPaths from 'vite-tsconfig-paths';
import devtoolsJson from 'vite-plugin-devtools-json';
import path from 'path';
export default defineConfig({
    logLevel: 'error',
    plugins: [
        tailwindcss(),
        reactRouter(),
        tsconfigPaths(),
        devtoolsJson()
    ],
    resolve: {
        alias: {
            '~': path.resolve(__dirname, './app'),
        },
    },
    build: {
        sourcemap: process.env.NODE_ENV === 'development',
    },
    server: {
        host: true, // Allow external connections
        port: 5173, // or whatever port you're using
        cors: true, // Allow all origins
        strictPort: false, // Allow different port if 5173 is taken
    },
});