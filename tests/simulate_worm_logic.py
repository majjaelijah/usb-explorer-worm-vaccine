"""Harmless re-implementation of the worm's infectDisk() drive logic, rebuilt from its
disassembled bytecode. Used to check that the vaccine works. It never touches real drives:
it only works inside a temporary folder.

Usage: python3 tests/simulate_worm_logic.py
"""
import os
import shutil
import tempfile

WHITELIST = ['Explorer', 'USB-Explorer.exe', 'autorun.inf', 'System Volume Information']


def infect(disk, app):
    if not os.path.exists(disk + 'Explorer'):
        os.makedirs(disk + 'Explorer/MAYUNDO')
    if not os.path.exists(disk + 'USB-Explorer.exe'):
        shutil.copy(app, disk + 'USB-Explorer.exe')
    if os.path.exists(disk + 'Explorer'):
        for f in os.listdir(disk):
            if f not in WHITELIST:
                try:
                    shutil.move(disk + f, disk + 'Explorer/MAYUNDO')
                except Exception:
                    pass


def run(vaccinated):
    with tempfile.TemporaryDirectory() as root:
        disk = os.path.join(root, 'drive') + '/'
        os.mkdir(disk)
        app = os.path.join(root, 'GPLControl.exe')
        open(app, 'w').write('stand-in, not the worm')
        os.mkdir(disk + 'Documents')
        open(disk + 'notes.pdf', 'w').close()
        if vaccinated:
            open(disk + 'Explorer', 'w').close()
            os.mkdir(disk + 'USB-Explorer.exe')
        infect(disk, app)
        files_safe = os.path.isdir(disk + 'Documents') and os.path.isfile(disk + 'notes.pdf')
        dropped = os.path.isfile(disk + 'USB-Explorer.exe') or \
            os.path.exists(disk + 'USB-Explorer.exe/GPLControl.exe')
        return files_safe, dropped


if __name__ == '__main__':
    safe, dropped = run(vaccinated=False)
    print(f'unprotected: files left in place={safe}, worm dropped={dropped}')
    assert not safe and dropped
    safe, dropped = run(vaccinated=True)
    print(f'vaccinated:  files left in place={safe}, worm dropped={dropped}')
    assert safe and not dropped
    print('PASS: the vaccine blocks the worm logic')
