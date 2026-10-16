"""Package the fresh unsigned device app without modifying its bundle."""
from pathlib import Path
import shutil
import subprocess
import tempfile

app = Path('build/ios/iphoneos/Runner.app').resolve()
output = Path('build/releases/v26.10.0/pet-fiasco-Sideloadly-v26.10.0.ipa').resolve()
if not app.is_dir() or output.exists():
    raise SystemExit('Fresh Runner.app required; existing IPA will not be overwritten.')
with tempfile.TemporaryDirectory(prefix='pet-fiasco-ipa-') as directory:
    payload = Path(directory) / 'Payload'
    payload.mkdir()
    shutil.copytree(app, payload / 'Runner.app', symlinks=True)
    subprocess.run(['zip', '-qry', str(output), 'Payload'], cwd=directory, check=True)
subprocess.run(['unzip', '-tq', str(output)], check=True)
print(output)
