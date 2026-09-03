import { spawn } from 'child_process';
import path from 'path';

console.log('🚀 Launching PharmaGo Ecosystem...');

// 1. Start Backend API Server
const server = spawn('node', ['src/index.js'], {
  cwd: path.resolve('c:/Users/jasam/Desktop/PharmaGo/pharmago_server'),
  stdio: 'inherit',
  shell: true,
});

// 2. Start Web Portal Dashboard
const web = spawn('npm', ['run', 'dev'], {
  cwd: path.resolve('c:/Users/jasam/Desktop/PharmaGo/pharmago_web'),
  stdio: 'inherit',
  shell: true,
});

console.log('📡 Backend API: http://localhost:5000');
console.log('🌐 Web Dashboard: http://localhost:5173');

process.on('SIGINT', () => {
  server.kill();
  web.kill();
  process.exit();
});
