#!/usr/bin/env python3
import subprocess, re, json, os, time

STORE = os.path.expanduser('~/.cache/eww-notifs.json')
MAX = 15
try:
    with open(STORE) as f:
        notifs = json.load(f)
except Exception:
    notifs = []

def save():
    try:
        with open(STORE, 'w') as f:
            json.dump(notifs[:MAX], f, ensure_ascii=False)
    except Exception:
        pass

def unescape(s):
    return s.replace('\\"', '"').replace('\\\\', '\\')

def process(block):
    text = "\n".join(block)
    if 'member=Notify' not in text:
        return
    strs = re.findall(r'string "((?:[^"\\]|\\.)*)"', text)
    if len(strs) >= 4:
        if unescape(strs[0]) in ('Teclado', 'Portapapeles'):
            return
        app, summary, body = unescape(strs[0]), unescape(strs[2]), unescape(strs[3])
        if summary or body:
            notifs.insert(0, {'app': app or 'Sistema', 'summary': summary, 'body': body, 'time': time.strftime('%H:%M')})
            del notifs[MAX:]
            save()

proc = subprocess.Popen(
    ['dbus-monitor', "interface='org.freedesktop.Notifications',member='Notify'"],
    stdout=subprocess.PIPE, text=True, bufsize=1)

block = []
for line in proc.stdout:
    if line.startswith('method call') or line.startswith('signal ') or line.startswith('method return'):
        process(block); block = [line]
    else:
        block.append(line)
