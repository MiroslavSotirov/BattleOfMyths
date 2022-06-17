import os
import sys
import subprocess
from pathlib import Path

print(Path(sys.argv[1]).resolve());
mainpath = Path(sys.argv[1]).resolve();
for root, _, files in os.walk(mainpath):
    for filename in files:
        print(filename);
        command = [
        "cwebp",
        "-q", "50",
        "-alpha_q", "50",
        root+"/"+filename,
        "-o", root+"/"+Path(filename).stem + ".webp"
        ]
        subprocess.call(command)
