"""Dump current Android UI tree: clickable nodes with center coords."""
import re
import subprocess
import sys

ADB = r"C:\Users\xuant\AppData\Local\Android\sdk\platform-tools\adb.exe"

subprocess.run([ADB, "shell", "uiautomator", "dump", "/sdcard/ui.xml"],
               capture_output=True)
xml = subprocess.run([ADB, "shell", "cat", "/sdcard/ui.xml"],
                     capture_output=True).stdout.decode("utf-8", "replace")

for node in re.findall(r"<node[^>]+>", xml):
    text = re.search(r'text="([^"]*)"', node)
    desc = re.search(r'content-desc="([^"]*)"', node)
    label = (text.group(1) if text and text.group(1)
             else desc.group(1) if desc else "")
    bounds = re.search(r'bounds="\[(\d+),(\d+)\]\[(\d+),(\d+)\]"', node)
    clickable = 'clickable="true"' in node
    if bounds and (label or clickable):
        x1, y1, x2, y2 = map(int, bounds.groups())
        if label:
            print(f"[{(x1+x2)//2},{(y1+y2)//2}] {label}")
        elif (x2 - x1) > 80 and (y2 - y1) > 60:
            print(f"[{(x1+x2)//2},{(y1+y2)//2}] <clickable {x2-x1}x{y2-y1}>")
