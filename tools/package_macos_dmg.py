"""Package and inspect the release app. Development signatures remain labeled."""
from pathlib import Path
import json
import shutil
import subprocess
import tempfile

root = Path.cwd()
app = root / 'build/releases/v26.9.1/Pet Fiasco.app'
if not app.is_dir():
    app = root / 'build/macos/Build/Products/Release/Pet Fiasco.app'
if not app.is_dir():
    app = root / 'build/releases/v26.9.1/PetFiasco.xcarchive/Products/Applications/Pet Fiasco.app'
if not app.is_dir():
    raise SystemExit('Fresh Pet Fiasco.app required.')
subprocess.run(['codesign','--verify','--deep','--strict',str(app)],check=True)
details = subprocess.run(['codesign','-dvv',str(app)],capture_output=True,text=True,check=True).stderr
public = 'Authority=Developer ID Application:' in details
suffix = '' if public else '-LOCAL-PREVIEW'
output = root / f'build/releases/v26.9.1/pet-fiasco-macos-v26.9.1{suffix}.dmg'
if output.exists():
    raise SystemExit('An existing DMG will not be overwritten.')
with tempfile.TemporaryDirectory(prefix='pet-fiasco-dmg-') as directory:
    stage = Path(directory)
    subprocess.run(['ditto',str(app),str(stage/app.name)],check=True)
    (stage/'Applications').symlink_to('/Applications')
    subprocess.run(['hdiutil','create','-volname','Pet Fiasco','-srcfolder',str(stage),'-format','UDZO',str(output)],check=True)
subprocess.run(['hdiutil','verify',str(output)],check=True)
print(json.dumps({'dmg':str(output),'public_distribution_ready':public,
                  'note':'Developer ID required for public release' if not public else 'Developer ID signature present'}))
