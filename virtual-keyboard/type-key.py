import subprocess
import sys
import time
import re
import os
import json
import glob

# ---------- CONSTANTS ----------
KEYCODES = {
  "ESC": 1,
  "1": 2,
  "2": 3,
  "3": 4,
  "4": 5,
  "5": 6,
  "6": 7,
  "7": 8,
  "8": 9,
  "9": 10,
  "0": 11,
  "MINUS": 12,
  "EQUAL": 13,
  "BACKSPACE": 14,
  "TAB": 15,
  "Q": 16,
  "W": 17,
  "E": 18,
  "R": 19,
  "T": 20,
  "Y": 21,
  "U": 22,
  "I": 23,
  "O": 24,
  "P": 25,
  "LEFTBRACE": 26,
  "RIGHTBRACE": 27,
  "ENTER": 28,
  "LEFTCTRL": 29,
  "A": 30,
  "S": 31,
  "D": 32,
  "F": 33,
  "G": 34,
  "H": 35,
  "J": 36,
  "K": 37,
  "L": 38,
  "SEMICOLON": 39,
  "APOSTROPHE": 40,
  "GRAVE": 41,
  "LEFTSHIFT": 42,
  "BACKSLASH": 43,
  "Z": 44,
  "X": 45,
  "C": 46,
  "V": 47,
  "B": 48,
  "N": 49,
  "M": 50,
  "COMMA": 51,
  "DOT": 52,
  "SLASH": 53,
  "RIGHTSHIFT": 54,
  "KPASTERISK": 55,
  "LEFTALT": 56,
  "SPACE": 57,
  "CAPSLOCK": 58,
  "F1": 59,
  "F2": 60,
  "F3": 61,
  "F4": 62,
  "F5": 63,
  "F6": 64,
  "F7": 65,
  "F8": 66,
  "F9": 67,
  "F10": 68,
  "NUMLOCK": 69,
  "SCROLLLOCK": 70,
  "KP7": 71,
  "KP8": 72,
  "KP9": 73,
  "KPMINUS": 74,
  "KP4": 75,
  "KP5": 76,
  "KP6": 77,
  "KPPLUS": 78,
  "KP1": 79,
  "KP2": 80,
  "KP3": 81,
  "KP0": 82,
  "KPDOT": 83,
  "ZENKAKUHANKAKU": 85,
  "102ND": 86,
  "F11": 87,
  "F12": 88,
  "RO": 89,
  "KATAKANA": 90,
  "HIRAGANA": 91,
  "HENKAN": 92,
  "KATAKANAHIRAGANA": 93,
  "MUHENKAN": 94,
  "KPJPCOMMA": 95,
  "KPENTER": 96,
  "RIGHTCTRL": 97,
  "KPSLASH": 98,
  "SYSRQ": 99,
  "RIGHTALT": 100,
  "HOME": 102,
  "UP": 103,
  "PAGEUP": 104,
  "LEFT": 105,
  "RIGHT": 106,
  "END": 107,
  "DOWN": 108,
  "PAGEDOWN": 109,
  "INSERT": 110,
  "DELETE": 111,
  "MUTE": 113,
  "VOLUMEDOWN": 114,
  "VOLUMEUP": 115,
  "POWER": 116,
  "KPEQUAL": 117,
  "PAUSE": 119,
  "KPCOMMA": 121,
  "HANGUEL": 122,
  "HANJA": 123,
  "YEN": 124,
  "LEFTMETA": 125,
  "RIGHTMETA": 126,
  "COMPOSE": 127,
  "STOP": 128,
  "AGAIN": 129,
  "PROPS": 130,
  "UNDO": 131,
  "FRONT": 132,
  "COPY": 133,
  "OPEN": 134,
  "PASTE": 135,
  "FIND": 136,
  "CUT": 137,
  "HELP": 138,
  "MENU": 139,
  "CALC": 140,
  "SLEEP": 142,
  "WAKEUP": 143,
  "FILE": 144,
  "WWW": 150,
  "SCREENLOCK": 152,
  "MAIL": 155,
  "BOOKMARKS": 156,
  "BACK": 158,
  "FORWARD": 159,
  "EJECTCD": 161,
  "NEXTSONG": 163,
  "PLAYPAUSE": 164,
  "PREVIOUSSONG": 165,
  "STOPCD": 166,
  "RECORD": 167,
  "REWIND": 168,
  "PHONE": 169,
  "CONFIG": 171,
  "HOMEPAGE": 172,
  "REFRESH": 173,
  "EXIT": 174,
  "EDIT": 176,
  "SCROLLUP": 177,
  "SCROLLDOWN": 178,
  "KPLEFTPAREN": 179,
  "KPRIGHTPAREN": 180,
  "NEW": 181,
  "F13": 183,
  "F14": 184,
  "F15": 185,
  "F16": 186,
  "F17": 187,
  "F18": 188,
  "F19": 189,
  "F20": 190,
  "F21": 191,
  "F22": 192,
  "F23": 193,
  "F24": 194,
  "CLOSE": 206,
  "PLAY": 207,
  "FASTFORWARD": 208,
  "BASSBOOST": 209,
  "PRINT": 210,
  "CAMERA": 212,
  "CHAT": 216,
  "SEARCH": 217,
  "FINANCE": 219,
  "BRIGHTNESSDOWN": 224,
  "BRIGHTNESSUP": 225,
  "KBDILLUMTOGGLE": 228,
  "KBDILLUMDOWN": 229,
  "KBDILLUMUP": 230,
  "SAVE": 234,
  "DOCUMENTS": 235,
  "UNKNOWN": 240,
  "VIDEO_NEXT": 241,
  "BRIGHTNESS_ZERO": 244,
  "PLANE_MODE": 247,
  "MUTE_MIC": 248,
  "BTN_0": 256,
  "SELECT": 353,
  "GOTO": 354,
  "INFO": 358,
  "PROGRAM": 362,
  "PVR": 366,
  "SUBTITLE": 370,
  "ZOOM": 372,
  "KEYBOARD": 374,
  "SCREEN": 375,
  "PC": 376,
  "TV": 377,
  "TV2": 378,
  "VCR": 379,
  "VCR2": 380,
  "SAT": 381,
  "CD": 383,
  "TAPE": 384,
  "TUNER": 386,
  "PLAYER": 387,
  "DVD": 389,
  "AUDIO": 392,
  "VIDEO": 393,
  "MEMO": 396,
  "CALENDAR": 397,
  "RED": 398,
  "GREEN": 399,
  "YELLOW": 400,
  "BLUE": 401,
  "CHANNELUP": 402,
  "CHANNELDOWN": 403,
  "LAST": 405,
  "NEXT": 407,
  "RESTART": 408,
  "SLOW": 409,
  "SHUFFLE": 410,
  "PREVIOUS": 412,
  "VIDEOPHONE": 416,
  "GAMES": 417,
  "ZOOMIN": 418,
  "ZOOMOUT": 419,
  "ZOOMRESET": 420,
  "WORDPROCESSOR": 421,
  "EDITOR": 422,
  "SPREADSHEET": 423,
  "GRAPHICSEDITOR": 424,
  "PRESENTATION": 425,
  "DATABASE": 426,
  "NEWS": 427,
  "VOICEMAIL": 428,
  "ADDRESSBOOK": 429,
  "MESSENGER": 430,
  "DISPLAYTOGGLE": 431,
  "SPELLCHECK": 432,
  "LOGOFF": 433,
  "MEDIA_REPEAT": 439,
  "IMAGES": 442,
  "FN": 464,
  "BUTTONCONFIG": 576,
  "TASKMANAGER": 577,
  "JOURNAL": 578,
  "CONTROLPANEL": 579,
  "APPSELECT": 580,
  "SCREENSAVER": 581,
  "VOICECOMMAND": 582,
  "ASSISTANT": 583,
  "EMOJI_PICKER": 585,
  "DICTATE": 586,
  "CAMERA_ACCESS_ENABLE": 587,
  "CAMERA_ACCESS_DISABLE": 588,
  "CAMERA_ACCESS_TOGGLE": 589,
  "BRIGHTNESS_MIN": 592,
  "BRIGHTNESS_MAX": 593
}

MODIFIER_KEYS = ["LEFTSHIFT", "RIGHTSHIFT", "LEFTCTRL", "RIGHTCTRL", "LEFTALT", "RIGHTALT", "LEFTMETA", "RIGHTMETA", "FN"]

# ---------- SYSTEM HELPERS ----------
def run(cmd):
    subprocess.run(cmd, capture_output=False)

def check_ydotool_service():
    try:
        status = subprocess.run(
            ["systemctl", "--user", "is-active", "ydotool.service"],
            capture_output=True, text=True
        ).stdout.strip()
        if status != "active":
            print("[INFO] Starting ydotool service...")
            run(["systemctl", "--user", "start", "ydotool.service"])
            time.sleep(1)
    except:
        sys.exit("[ERROR] Could not manage ydotool service")

def get_fn_key(fn):
    match fn:
        case "F1":
            return "BRIGHTNESSDOWN"
        case "F2":
            return "BRIGHTNESSUP"
        case "F3":
            return "MUTE_MIC"
        case "F6":
            return "MUTE"
        case "F7":
            return "VOLUMEDOWN"
        case "F8":
            return "VOLUMEUP"
        case "F11":
            return "PLANE_MODE"
        case "F12":
            return "SLEEP"
        case "DELETE":
            return "INSERT"
        case "UP":
            return "PAGEUP"
        case "DOWN":
            return "PAGEDOWN"
        case "LEFT":
            return "HOME"
        case "RIGHT":
            return "END"


# ---------- KEY ACTIONS ----------
def press_key(code, down=True):
    run(["ydotool", "key", f"{code}:{1 if down else 0}"])

# ---------- SEND KEY ----------
def send_key(layout, key, modifiers):

    # Press modifiers (with special case for "fn")
    if "FN" in modifiers and key in ["F1", "F2", "F3", "F6", "F7", "F8", "F11", "F12", "DELETE", "UP", "DOWN", "LEFT", "RIGHT"]:
        key = get_fn_key(key)
        
    for m in modifiers:
        if m in MODIFIER_KEYS:
            press_key(KEYCODES[m], True)

    # type keycode
    if key in KEYCODES:
        code = KEYCODES[key]
        press_key(code, True)
        press_key(code, False)
    else:
        run(["ydotool", "type", key])

    print(f"Sent: {' '.join(modifiers)} {key}")

    # Release modifiers
    for m in reversed(modifiers):
        if m in MODIFIER_KEYS:
            press_key(KEYCODES[m], False)

# ---------- RESET ----------
def reset():
    # Release all toggled modifiers
    for key, value in MODIFIER_KEYS.items():
        press_key(value, False)

# ---------- MAIN ----------
if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python type-key.py <layout> <key_name> [modifiers...]")
        sys.exit(1)

    layout = sys.argv[1]
    key = sys.argv[2]
    mods = [m.upper() for m in sys.argv[3:]]

    if key == "reset":
        reset()
        sys.exit(0)

    check_ydotool_service()
    send_key(layout, key.upper(), mods)
