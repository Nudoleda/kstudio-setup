// ks-exthost.js - Node extension host, speaks NDJSON over stdin/stdout, bridged via ksterm /exthost WS
// Protocol: {"id":1,"method":"activate","extension":"id"} -> {"id":1,"ok":true,"result":{}}
// Methods: activate, executeCommand, provideCompletion, provideHover, provideDiagnostics
const fs = require('fs'), path = require('path');
const EXT_DIR = (process.env.HOME || '') + '/.kstudio/extensions';
const loaded = {};
function loadExt(id) {
  if (loaded[id]) return loaded[id];
  const base = path.join(EXT_DIR, id, 'extension');
  try {
    const candidates = [base + '.js', path.join(base, 'out', 'extension.js'), path.join(base, 'dist', 'extension.js')];
    for (const c of candidates) if (fs.existsSync(c)) { loaded[id] = require(c); return loaded[id]; }
  } catch (e) { return { error: String(e) }; }
  return null;
}
const readline = require('readline');
const rl = readline.createInterface({ input: process.stdin });
const vscodeShim = {
  commands: { registerCommand: (c, f) => { vscodeShim._cmds[c] = f; }, _cmds: {} },
  window: { showInformationMessage: async m => ({ msg: m }) },
  workspace: { getConfiguration: () => ({ get: () => undefined }) },
  languages: { registerCompletionItemProvider: () => ({ dispose(){} }) },
};
global.vscode = vscodeShim;
rl.on('line', async line => {
  let m; try { m = JSON.parse(line); } catch { return; }
  const reply = r => process.stdout.write(JSON.stringify({ id: m.id, ...r }) + '\n');
  try {
    if (m.method === 'activate') { const mod = loadExt(m.extension); if (mod && mod.activate) await mod.activate(vscodeShim); reply({ ok: true }); }
    else if (m.method === 'executeCommand') { const f = vscodeShim._cmds[m.command]; const r = f ? await f(...(m.args || [])) : null; reply({ ok: true, result: r }); }
    else reply({ ok: false, error: 'unknown method' });
  } catch (e) { reply({ ok: false, error: String(e) }); }
});
process.stdout.write(JSON.stringify({ hello: 'ks-exthost', api: ['commands','window','workspace','languages'] }) + '\n');
