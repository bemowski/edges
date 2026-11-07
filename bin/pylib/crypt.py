"""Shared gpg helpers for the encrypt, decrypt and recrypt scripts.

Files are symmetrically encrypted with a passphrase file. The key's file name
(e.g. crypt.key.28oct2026) is recorded in a 'Comment: key=...' armor header.
The header is not authenticated, so only ~/.ssh/crypt.key.* names are trusted.
"""
import argparse
import os
import re
import subprocess
import sys
from pathlib import Path

DEFAULT_KEY = Path(os.environ.get("PASSPHRASE_FILE", "~/.ssh/crypt.key")).expanduser()
KEY_DIR = Path("~/.ssh").expanduser()
KEY_NAME = re.compile(r"crypt\.key\.[\w.-]+")
KEY_COMMENT = "key="
KEY_HEADER = f"Comment: {KEY_COMMENT}"


class CryptError(Exception):
    pass


def asc_file(value):
    """argparse type: a path ending in .asc."""
    path = Path(value)
    if path.suffix != ".asc":
        raise argparse.ArgumentTypeError(f"{value}: expected a .asc file")
    return path


def key_from_header(data):
    """Return ~/.ssh/<name> from the armor header of encrypted data, or None."""
    for line in data.decode(errors="replace").splitlines()[1:]:
        if not line:
            break  # a blank line ends the armor headers
        if line.startswith(KEY_HEADER):
            name = line.removeprefix(KEY_HEADER)
            if not KEY_NAME.fullmatch(name):
                raise CryptError(f"refusing untrusted key name {name!r}")
            return KEY_DIR / name
    return None


def key_comment(key):
    """gpg args recording the key's real file name, if it is a crypt.key.* file."""
    name = key.resolve().name
    return ["--comment", KEY_COMMENT + name] if KEY_NAME.fullmatch(name) else []


def gpg(args, data):
    """Run gpg in batch mode on data and return its output."""
    result = subprocess.run(["gpg", "--batch", "--quiet", *args],
                            input=data, stdout=subprocess.PIPE)
    if result.returncode:
        raise CryptError(f"gpg failed (exit {result.returncode})")
    return result.stdout


def decrypt(data, key):
    return gpg(["--decrypt", "--passphrase-file", key], data)


def encrypt(data, key):
    return gpg(["--symmetric", "--armor", "--passphrase-file", key, *key_comment(key)], data)


def process(files, action):
    """Run action on each file, logging failures; exit non-zero if any failed."""
    failed = False
    for file in files:
        try:
            action(file)
        except (CryptError, OSError) as e:
            print(f"{file}: {e}", file=sys.stderr)
            failed = True
    sys.exit(failed)
