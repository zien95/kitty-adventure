"""Copy and validate the fresh unsigned Tauri mobile IPA."""
from pathlib import Path
import shutil
import subprocess

source = Path('mobile-tauri/src-tauri/gen/apple/build/arm64/Pet Fiasco.ipa').resolve()
output = Path('build/releases/v26.11.0/pet-fiasco-Sideloadly-v26.11.0.ipa').resolve()
if not source.is_file() or output.exists():
    raise SystemExit('Fresh Tauri IPA required; existing IPA will not be overwritten.')
output.parent.mkdir(parents=True, exist_ok=True)
shutil.copy2(source, output)
subprocess.run(['unzip', '-tq', str(output)], check=True)
print(output)
