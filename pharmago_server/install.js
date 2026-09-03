import { execSync } from 'child_process';
import path from 'path';

console.log('Running npm install via Node child_process...');
try {
  const output = execSync('npm install', {
    cwd: path.resolve('c:/Users/jasam/Desktop/PharmaGo/pharmago_server'),
    encoding: 'utf-8',
    stdio: 'inherit'
  });
  console.log('npm install finished successfully!');
} catch (err) {
  console.error('Error during npm install:', err.message);
}
