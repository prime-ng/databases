// @ts-check
const express = require('express');
const { spawn } = require('child_process');
const path = require('path');

const app = express();
const PORT = process.env.RUNNER_PORT || 3050;

app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));
app.use('/test-results', express.static(path.join(__dirname, 'test-results')));

// Active child process reference
let currentProc = null;

const ALL_FLOW_FILES = [
  'tests/00_setup_auth.spec.js',
  'tests/01_sections.spec.js',
  'tests/02_class.spec.js',
  'tests/03_subject_type.spec.js',
  'tests/04_study_format.spec.js',
  'tests/05_subject.spec.js',
  'tests/06_subject_study_format.spec.js',
  'tests/07_class_group.spec.js',
  'tests/08_subject_group.spec.js',
  'tests/09_stream.spec.js'
];

app.post('/api/run', (req, res) => {
  const { file, filter, headed = true, all = false } = req.body;

  // Kill any running process before starting a new run
  if (currentProc) {
    try {
      process.kill(-currentProc.pid, 'SIGKILL');
    } catch (e) {
      try { currentProc.kill('SIGKILL'); } catch (err) {}
    }
    currentProc = null;
  }

  const args = ['playwright', 'test'];
  if (all) {
    args.push(...ALL_FLOW_FILES);
  } else {
    const testFile = file || 'tests/01_sections.spec.js';
    args.push(testFile);
    if (filter) {
      args.push('-g', filter);
    }
  }
  if (headed) {
    args.push('--headed');
  }

  res.setHeader('Content-Type', 'text/event-stream');
  res.setHeader('Cache-Control', 'no-cache');
  res.setHeader('Connection', 'keep-alive');

  res.write(`data: ${JSON.stringify({ type: 'start', cmd: `npx ${args.join(' ')}` })}\n\n`);

  const proc = spawn('npx', args, {
    cwd: __dirname,
    detached: true,
    env: { ...process.env, PATH: `${process.env.PATH}:/home/shailesh/.local/bin:/home/shailesh/.local/node/bin` }
  });

  currentProc = proc;

  proc.stdout.on('data', (data) => {
    res.write(`data: ${JSON.stringify({ type: 'log', text: data.toString() })}\n\n`);
  });

  proc.stderr.on('data', (data) => {
    res.write(`data: ${JSON.stringify({ type: 'error', text: data.toString() })}\n\n`);
  });

  proc.on('close', (code) => {
    currentProc = null;
    res.write(`data: ${JSON.stringify({ type: 'done', code, passed: code === 0 })}\n\n`);
    res.end();
  });

  req.on('close', () => {
    // Client disconnected
  });
});

// Stop / Kill current run API endpoint
app.post('/api/stop', (req, res) => {
  if (currentProc) {
    try {
      process.kill(-currentProc.pid, 'SIGKILL');
    } catch (e) {
      try { currentProc.kill('SIGKILL'); } catch (err) {}
    }
    currentProc = null;
    return res.json({ status: 'stopped', message: 'Process killed successfully' });
  }
  return res.json({ status: 'idle', message: 'No active process running' });
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`=======================================================`);
  console.log(` Playwright School Setup Test Dashboard is running at:`);
  console.log(` http://localhost:${PORT}`);
  console.log(`=======================================================`);
});
