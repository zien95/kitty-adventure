// Disposable end-to-end check. No password, token, or user data is logged.
const fs = require('node:fs');
const crypto = require('node:crypto');
const {execFileSync} = require('node:child_process');
const options = fs.readFileSync('lib/firebase_options.dart','utf8');
const key = options.match(/static const FirebaseOptions web[^]*?apiKey: '([^']+)'/)[1];
const project = 'kitty-adventure-zona';
async function request(method,url,body,token) {
  let config = 'header = "Content-Type: application/json"\n';
  if(token) config += `header = "Authorization: Bearer ${token}"\n`;
  if(body) config += `data = ${JSON.stringify(JSON.stringify(body))}\n`;
  const output = execFileSync('/usr/bin/curl',['-sS','--config','-','-X',method,url],{input:config,maxBuffer:2*1024*1024});
  return JSON.parse(output);
}
(async()=>{
  const auth = 'https://identitytoolkit.googleapis.com/v1/accounts:';
  const email = `pet-fiasco-qa-${Date.now()}@example.invalid`;
  const password = crypto.randomBytes(24).toString('base64url');
  let token,uid,document;
  try {
    const created = await request('POST',`${auth}signUp?key=${key}`,{email,password,returnSecureToken:true});
    if(created.error) throw Error(`Create account: ${created.error.message}`);
    token=created.idToken; uid=created.localId;
    console.log('PASS email/password registration');
    const signed = await request('POST',`${auth}signInWithPassword?key=${key}`,{email,password,returnSecureToken:true});
    if(signed.localId !== uid) throw Error('Sign-in did not restore the account');
    token=signed.idToken;
    console.log('PASS email/password sign-in');
    document = `projects/${project}/databases/(default)/documents/players/${uid}/saves/current`;
    const payload = JSON.stringify({kittyCatCollection:'[]',dailyStreakCount:3});
    const write = await request('POST',`https://firestore.googleapis.com/v1/projects/${project}/databases/(default)/documents:commit`,{writes:[{
      update:{name:document,fields:{schema:{integerValue:'1'},payload:{stringValue:payload},revision:{integerValue:'1'},appVersion:{stringValue:'26.9.1'}}},
      updateTransforms:[{fieldPath:'updatedAt',setToServerValue:'REQUEST_TIME'}],
    }]},token);
    if(write.error) throw Error(`Save: ${write.error.message}`);
    const read=await request('GET',`https://firestore.googleapis.com/v1/${document}`,null,token);
    if(read.fields?.payload?.stringValue !== payload) throw Error('Cloud save round trip differs');
    console.log('PASS authenticated Firestore save and restore');
    const anonymous=await request('GET',`https://firestore.googleapis.com/v1/${document}`);
    if(anonymous.error?.code !== 403) throw Error('Anonymous read was not denied');
    const foreign=await request('GET',`https://firestore.googleapis.com/v1/projects/${project}/databases/(default)/documents/players/not-this-user/saves/current`,null,token);
    if(foreign.error?.code !== 403) throw Error('Another player read was not denied');
    console.log('PASS unauthenticated and cross-account reads denied');
  } finally {
    if(document && token) await request('DELETE',`https://firestore.googleapis.com/v1/${document}`,null,token);
    if(token) {
      const deleted=await request('POST',`${auth}delete?key=${key}`,{idToken:token});
      if(deleted.error) throw Error('Could not remove disposable QA account');
      console.log('Removed disposable QA save and account.');
    }
  }
})().catch(e=>{console.error(e.message);process.exitCode=1;});
