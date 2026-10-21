"""Upload a draft, verify every asset, then optionally publish and check public URLs."""
import argparse
import hashlib
import json
import plistlib
from pathlib import Path
import subprocess
import tempfile
import time
from urllib.parse import quote

REPO = 'zien95/kitty-adventure'
API = f'https://api.github.com/repos/{REPO}'


def curl(url, *, token=None, method='GET', data=None, upload=None, output=None):
    config = '' if token is None else f'header = "Authorization: Bearer {token}"\n'
    args = ['/usr/bin/curl', '--silent', '--show-error', '--fail-with-body',
            '--location', '--config', '-', '--max-time', '600', '-X', method,
            '-H', 'Accept: application/vnd.github+json', url]
    if data is not None:
        args += ['-H', 'Content-Type: application/json', '--data-binary', json.dumps(data)]
    if upload:
        args += ['-H', 'Content-Type: application/octet-stream', '--data-binary', '@' + str(upload)]
    if output:
        args += ['--output', str(output)]
    result = subprocess.run(args, input=config, text=True, capture_output=True)
    if result.returncode:
        raise RuntimeError(f'HTTP request failed for {url}: {result.stderr.strip()}')
    return json.loads(result.stdout) if result.stdout else None


def sha256(path):
    with path.open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()


def verify_public_mac_signing(dmg, allow_adhoc=False):
    # Firebase Auth uses the protected keychain. A single-device development
    # profile is useful for testing but must not become a public Mac installer.
    with tempfile.TemporaryDirectory(prefix='pet-fiasco-dmg-check-') as mount:
        subprocess.run(['hdiutil', 'attach', '-readonly', '-nobrowse',
                        '-mountpoint', mount, str(dmg)], check=True, capture_output=True)
        try:
            apps = list(Path(mount).glob('*.app'))
            if len(apps) != 1:
                raise RuntimeError('DMG must contain exactly one app bundle.')
            subprocess.run(['codesign', '--verify', '--deep', '--strict', str(apps[0])], check=True)
            signature = subprocess.run(['codesign', '-dvv', str(apps[0])],
                                       capture_output=True, text=True, check=True).stderr
            if 'Authority=Developer ID Application:' not in signature and not (allow_adhoc and 'Signature=adhoc' in signature):
                raise RuntimeError('Public Mac release blocked: install a Developer ID Application signing certificate and rebuild the DMG.')
            profile = apps[0] / 'Contents/embedded.provisionprofile'
            if profile.exists():
                decoded = subprocess.check_output(['security', 'cms', '-D', '-i', str(profile)])
                details = plistlib.loads(decoded)
                if details.get('ProvisionedDevices') and not details.get('ProvisionsAllDevices'):
                    raise RuntimeError('Public Mac release blocked: the embedded profile is restricted to registered development devices.')
        finally:
            subprocess.run(['hdiutil', 'detach', mount], check=True, capture_output=True)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--publish', action='store_true')
    parser.add_argument('--allow-adhoc-macos', action='store_true', help='Explicitly distribute an unnotarized ad-hoc Mac package.')
    args = parser.parse_args()
    manifest = json.loads(Path('web/latest.json').read_text())
    version = manifest['version']
    tag = 'v' + version
    directory = Path('build/releases') / tag
    assets = {manifest[key].rsplit('/', 1)[-1]: manifest[key]
              for key in ['apk_url', 'ipa_url', 'macos_url', 'web_zip_url']}
    for name in assets:
        if not (directory / name).is_file():
            raise RuntimeError(f'Missing artifact: {name}')
    if args.publish:
        verify_public_mac_signing(directory / manifest['macos_url'].rsplit('/', 1)[-1], args.allow_adhoc_macos)
    source_paths = ['lib', 'assets', 'pubspec.yaml', 'pubspec.lock', 'README.md',
                    'web', 'updates', 'ios', 'macos', 'android/app/src',
                    'android/app/build.gradle.kts', 'android/settings.gradle.kts',
                    'android/app/google-services.json', 'firebase.json', 'firestore.rules',
                    'mobile-tauri', 'test', 'tools', 'CHANGELOG.md', 'RELEASE_STATUS.md']
    dirty = subprocess.check_output(['git', 'status', '--porcelain', '--', *source_paths], text=True)
    if dirty:
        raise RuntimeError('Release source is uncommitted. Commit the reviewed release files before creating the GitHub tag.')
    commit = subprocess.check_output(['git', 'rev-parse', 'HEAD'], text=True).strip()
    credential = subprocess.check_output(['git', 'credential', 'fill'],
        input='protocol=https\nhost=github.com\n\n', text=True)
    fields = dict(line.split('=', 1) for line in credential.splitlines() if '=' in line)
    token = fields.get('password')
    if not token:
        raise RuntimeError('GitHub login is missing. Configure the github.com Git credential.')
    releases = curl(API + '/releases', token=token)
    release = next((r for r in releases if r['tag_name'] == tag), None)
    if release and not release['draft']:
        raise RuntimeError(f'{tag} already exists publicly; refusing to replace it.')
    if release and release['target_commitish'] != commit:
        raise RuntimeError('Existing draft points to a different source commit.')
    if not release:
        body = ('Exploration Update: Part 1 expands the pet world with nine interactive '
                'destinations, functional Enter/Action controls, and a visible pet family '
                'where companions can be tapped to take control.\n\n'
                'The Android APK and unsigned Sideloadly IPA are mobile-only Tauri shells '
                'that require internet and load the hosted game. The macOS app is '
                'ad-hoc signed for Apple Silicon (arm64), without notarization. macOS may require explicit approval in Privacy & Security.\n\n'
                f'Source: `{commit}`. Every asset was verified before publication.')
        release = curl(API + '/releases', token=token, method='POST', data={
            'tag_name': tag, 'target_commitish': commit, 'draft': True,
            'name': manifest['title'], 'body': body,
        })
    upload_url = release['upload_url'].split('{')[0]
    for name in assets:
        if not any(a['name'] == name for a in release['assets']):
            curl(upload_url + '?name=' + quote(name), token=token,
                 method='POST', upload=directory / name)
            print(f'Uploaded {name}', flush=True)
    release = curl(API + '/releases/' + str(release['id']), token=token)
    if {a['name'] for a in release['assets']} != set(assets):
        raise RuntimeError('Draft asset set does not match the four verified packages.')
    for asset in release['assets']:
        local = directory / asset['name']
        expected = 'sha256:' + sha256(local)
        if asset['state'] != 'uploaded' or asset['size'] != local.stat().st_size or asset.get('digest') != expected:
            raise RuntimeError('Draft asset validation failed: ' + asset['name'])
        print('Verified draft SHA-256: ' + asset['name'], flush=True)
    if not args.publish:
        print('Draft ready; public release remains unpublished.')
        return
    curl(API + '/releases/' + str(release['id']), token=token,
         method='PATCH', data={'draft': False, 'make_latest': 'true'})
    try:
        for name, url in assets.items():
            for attempt in range(3):
                try:
                    with tempfile.TemporaryDirectory(prefix='pet-fiasco-download-') as temp:
                        path = Path(temp) / name
                        curl(url, output=path)
                        if sha256(path) != sha256(directory / name):
                            raise RuntimeError('Public download checksum differs: ' + name)
                    print('Verified public download: ' + name, flush=True)
                    break
                except RuntimeError:
                    if attempt == 2:
                        raise
                    time.sleep(5)
    except Exception:
        curl(API + '/releases/' + str(release['id']), token=token,
             method='PATCH', data={'draft': True})
        raise
    print(f'Published and verified: https://github.com/{REPO}/releases/tag/{tag}')


if __name__ == '__main__':
    main()
