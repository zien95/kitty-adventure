// Uses the Firebase CLI's existing login without printing credentials.
const fs = require('node:fs');
const {execFileSync} = require('node:child_process');
const config = JSON.parse(fs.readFileSync(require('node:path').join(require('node:os').homedir(),'.config/configstore/firebase-tools.json'),'utf8'));
const token = config.tokens.access_token;
const [method, url, body] = process.argv.slice(2);
if (!url.startsWith('https://') || !new URL(url).hostname.endsWith('.googleapis.com')) throw Error('Google API URL required');
const args = ['--silent','--show-error','--fail-with-body','--config','-','-X',method,'-H','Content-Type: application/json',url];
if(body) args.push('--data-binary',body);
try {
  const raw = execFileSync('/usr/bin/curl',args,{input:`header = "Authorization: Bearer ${token}"\n`,maxBuffer:5*1024*1024});
  const result = JSON.parse(raw);
  if (result.signIn) delete result.signIn.hashConfig;
  if (result.client) delete result.client.apiKey;
  process.stdout.write(JSON.stringify(result,null,2)+'\n');
} catch(e) {process.stdout.write(e.stdout || ''); process.exit(1);}
