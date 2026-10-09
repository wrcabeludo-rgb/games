#!/usr/bin/env python3
"""Вшивает иконку (.ico) в Windows .exe без rcedit: tools/set_exe_icon.py <exe> <ico>.
Нужен pe_tools (pip install pe_tools). Иконка Godot (группа GODOT_ICON) заменяется нашей."""
import struct
import subprocess
import sys
import tempfile
from pathlib import Path

exe, ico = sys.argv[1], Path(sys.argv[2]).read_bytes()
_, _, count = struct.unpack_from("<HHH", ico, 0)
tmp = Path(tempfile.mkdtemp())
args = ["peresed"]
group = struct.pack("<HHH", 0, 1, count)
for i in range(count):
    w, h, colors, _, planes, bpp, size, offset = struct.unpack_from("<BBBBHHII", ico, 6 + 16 * i)
    (tmp / f"{i + 1}.bin").write_bytes(ico[offset:offset + size])
    args += ["--set-resource", "RT_ICON", f"#{i + 1}", "1033", str(tmp / f"{i + 1}.bin")]
    group += struct.pack("<BBBBHHIH", w, h, colors, 0, planes, bpp, size, i + 1)
(tmp / "group.bin").write_bytes(group)
args += ["--set-resource", "RT_GROUP_ICON", "GODOT_ICON", "1033", str(tmp / "group.bin"), exe]
subprocess.run(args, check=True)
print(f"Иконка вшита: {count} размеров")
