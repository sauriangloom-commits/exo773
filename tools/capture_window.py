"""Capture a window by title for local QA screenshots.

Usage: python tools/capture_window.py "Ravenloft Foundation" docs/screenshots/menu.png
Requires Pillow. This is a development helper, not part of the shipped game.
"""

import ctypes
import sys
import time
from ctypes import wintypes

from PIL import ImageGrab


def enable_dpi_awareness() -> None:
    try:
        ctypes.windll.shcore.SetProcessDpiAwareness(1)
    except Exception:
        try:
            ctypes.windll.user32.SetProcessDPIAware()
        except Exception:
            pass


def find_window(title: str) -> int:
    user32 = ctypes.windll.user32
    hwnd = user32.FindWindowW(None, title)
    if hwnd:
        return hwnd
    found = []

    @ctypes.WINFUNCTYPE(wintypes.BOOL, wintypes.HWND, wintypes.LPARAM)
    def enum_proc(hwnd, _lparam):
        length = user32.GetWindowTextLengthW(hwnd)
        if length:
            buf = ctypes.create_unicode_buffer(length + 1)
            user32.GetWindowTextW(hwnd, buf, length + 1)
            if title.lower() in buf.value.lower():
                found.append(hwnd)
        return True

    user32.EnumWindows(enum_proc, 0)
    return found[0] if found else 0


def main() -> int:
    if len(sys.argv) < 3:
        print("usage: capture_window.py <window title> <output.png>")
        return 2
    title, output = sys.argv[1], sys.argv[2]
    enable_dpi_awareness()
    user32 = ctypes.windll.user32
    hwnd = find_window(title)
    if not hwnd:
        print(f"window not found: {title}")
        return 1
    user32.ShowWindow(hwnd, 9)
    user32.SetForegroundWindow(hwnd)
    time.sleep(1.0)
    rect = wintypes.RECT()
    user32.GetWindowRect(hwnd, ctypes.byref(rect))
    width = rect.right - rect.left
    height = rect.bottom - rect.top
    image = ImageGrab.grab(
        bbox=(rect.left, rect.top, rect.right, rect.bottom), all_screens=True
    )
    image.save(output)
    print(f"saved {output} ({width}x{height})")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
