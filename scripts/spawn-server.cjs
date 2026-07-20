const { spawn } = require("child_process");

const scriptPath = process.argv[2];
const cwd = process.argv[3];
const port = process.argv[4];

if (!scriptPath || !cwd || !port) {
  process.stderr.write("Missing spawn arguments.\n");
  process.exit(1);
}

const child = spawn(process.execPath, [scriptPath], {
  cwd,
  env: { ...process.env, PORT: port },
  detached: true,
  stdio: "ignore",
  windowsHide: true,
});

child.unref();
process.stdout.write(String(child.pid));
