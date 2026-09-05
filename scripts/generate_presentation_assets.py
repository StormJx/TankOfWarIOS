#!/usr/bin/env python3
"""Generate NES-palette pixel sprites, app icon, and 8-bit WAV cues."""

from __future__ import annotations

import math
import struct
import wave
import zlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1] / "war of tank" / "war of tank"
ATLAS = ROOT / "Assets.xcassets" / "Sprites.spriteatlas"
ICON = ROOT / "Assets.xcassets" / "AppIcon.appiconset"
AUDIO = ROOT / "Resources" / "Audio"
LAUNCH = ROOT / "Assets.xcassets" / "LaunchLogo.imageset"

PALETTE = {
    ".": None,
    "0": (0, 0, 0),
    "1": (252, 252, 252),
    "2": (184, 184, 184),
    "3": (124, 124, 124),
    "4": (248, 216, 120),
    "5": (252, 152, 56),
    "6": (228, 92, 16),
    "7": (168, 16, 0),
    "8": (88, 248, 152),
    "9": (0, 168, 0),
    "A": (0, 88, 0),
    "B": (60, 188, 252),
    "C": (0, 120, 248),
    "D": (0, 0, 188),
    "E": (248, 56, 0),
    "F": (216, 0, 204),
}


def png_chunk(tag: bytes, data: bytes) -> bytes:
    return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)


def write_png(path: Path, pixels: list[list[str]]) -> None:
    height = len(pixels)
    width = len(pixels[0])
    raw = bytearray()
    for row in pixels:
        raw.append(0)
        for cell in row:
            color = PALETTE[cell]
            if color is None:
                raw.extend((0, 0, 0, 0))
            else:
                raw.extend((*color, 255))
    path.write_bytes(
        b"\x89PNG\r\n\x1a\n"
        + png_chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0))
        + png_chunk(b"IDAT", zlib.compress(bytes(raw), 9))
        + png_chunk(b"IEND", b"")
    )


def grid(*rows: str) -> list[list[str]]:
    return [list(row) for row in rows]


def scale(pixels: list[list[str]], factor: int) -> list[list[str]]:
    out: list[list[str]] = []
    for row in pixels:
        scaled = []
        for cell in row:
            scaled.extend([cell] * factor)
        for _ in range(factor):
            out.append(scaled[:])
    return out


def write_atlas(name: str, pixels: list[list[str]]) -> None:
    write_png(ATLAS / f"{name}.png", pixels)


def tank(body: str, track: str, barrel: str, tread: str, frame: int) -> list[list[str]]:
    """16x16 朝上。黑描边 + 独立炮塔 + 3px 履带；两帧只错履带条纹。"""
    # 只靠条纹相位区分帧，不再对调颜色，避免相位与对调互相抵消
    rows = [["."] * 16 for _ in range(16)]

    def put(x: int, y: int, color: str) -> None:
        if 0 <= x < 16 and 0 <= y < 16:
            rows[y][x] = color

    def track_color(x: int, y: int) -> str:
        # 横向条纹 + 帧偏移，比棋盘格更像履带，也更少噪点
        phase = y + frame
        return tread if phase % 2 == 0 else track

    # --- 履带（左右各 3px，y=5..14）---
    for y in range(5, 15):
        for x in (1, 2, 3, 12, 13, 14):
            put(x, y, track_color(x, y))

    # --- 车体 ---
    for y in range(6, 14):
        for x in range(4, 12):
            put(x, y, body)
    for x in range(5, 11):  # 前端收窄一格
        put(x, 5, body)

    # 体积：左上高光、右下暗部
    put(4, 6, barrel)
    put(5, 6, barrel)
    put(10, 12, track)
    put(11, 12, track)
    put(10, 13, track)
    put(11, 13, track)

    # --- 炮塔（压在车体中央）---
    for y in range(8, 12):
        for x in range(5, 11):
            put(x, y, track)
    put(5, 8, barrel)
    put(6, 8, barrel)
    # 舱盖
    put(7, 9, "0")
    put(8, 9, "0")
    put(7, 10, "0")
    put(8, 10, "0")

    # --- 炮管（y=0..4，避免与车头抢像素）---
    for y in range(0, 5):
        put(5, y, "0")
        put(10, y, "0")
        for x in range(6, 10):
            put(x, y, barrel)
    # 炮口高光
    for x in range(6, 10):
        put(x, 0, "1")
    put(5, 0, barrel)
    put(10, 0, barrel)
    # 炮管根部接到炮塔
    for x in range(6, 10):
        put(x, 5, barrel)
    put(5, 5, "0")
    put(10, 5, "0")

    # --- 黑描边：只描轮廓外一圈空像素，不改已有颜色 ---
    opaque = {(x, y) for y in range(16) for x in range(16) if rows[y][x] != "."}
    for x, y in list(opaque):
        for dx, dy in ((-1, 0), (1, 0), (0, -1), (0, 1)):
            nx, ny = x + dx, y + dy
            if 0 <= nx < 16 and 0 <= ny < 16 and rows[ny][nx] == ".":
                rows[ny][nx] = "0"

    return rows



def boss(size: int, body: str, dark: str, accent: str, frame: int) -> list[list[str]]:
    """多 tile Boss：加宽履带、炮塔中心块、全身描边，体量比小坦克更清晰。"""
    mid = size // 2
    barrel_w = 6 if size >= 32 else 4
    barrel_h = max(8, size // 3)
    left = mid - barrel_w // 2
    right = mid + barrel_w // 2 - 1
    rows: list[list[str]] = []
    for y in range(size):
        row: list[str] = []
        for x in range(size):
            if y < barrel_h and left <= x <= right:
                if x in (left, right):
                    row.append("0")
                elif y <= 1:
                    row.append("1")
                else:
                    row.append(accent)
            elif x < 4 or x >= size - 4 or y >= size - 4:
                stripe = ((x + y + frame * 2) // 2) % 2 == 0
                row.append(dark if stripe else accent)
            elif mid - 3 <= x <= mid + 2 and mid - 2 <= y <= mid + 2:
                row.append(dark)
            elif mid - 1 <= x <= mid and mid - 1 <= y <= mid:
                row.append("0")
            else:
                # 轻微体积：右下偏暗
                if x > mid + size // 6 and y > mid + size // 6:
                    row.append(dark)
                else:
                    row.append(body)
        rows.append(row)

    filled = [(x, y) for y in range(size) for x in range(size) if rows[y][x] != "."]
    for x, y in filled:
        for dx, dy in ((-1, 0), (1, 0), (0, -1), (0, 1)):
            nx, ny = x + dx, y + dy
            if 0 <= nx < size and 0 <= ny < size and rows[ny][nx] == ".":
                rows[ny][nx] = "0"
    return rows



def brick() -> list[list[str]]:
    rows = []
    for y in range(16):
        row = []
        for x in range(16):
            mortar = y % 8 == 7 or (y < 8 and x == 7) or (y >= 8 and x in (3, 12))
            row.append("0" if mortar else ("6" if (x + y) % 5 == 0 else "7"))
        rows.append(row)
    return rows


def steel() -> list[list[str]]:
    """浅灰金属板 + 黑框铆钉十字，和棕色砖墙一眼能分开。"""
    rivets = {
        (2, 2), (13, 2), (2, 13), (13, 13),
        (7, 2), (8, 2), (7, 13), (8, 13),
        (2, 7), (2, 8), (13, 7), (13, 8),
    }
    rows = []
    for y in range(16):
        row = []
        for x in range(16):
            if x in (0, 15) or y in (0, 15):
                row.append("0")
            elif (x, y) in rivets:
                row.append("1")
            elif x in (7, 8) or y in (7, 8):
                row.append("3")
            elif x in (1, 14) or y in (1, 14):
                row.append("2")
            else:
                row.append("1" if (x + y) % 7 == 0 else "2")
        rows.append(row)
    return rows


def water(frame: int) -> list[list[str]]:
    rows = []
    for y in range(16):
        row = []
        for x in range(16):
            wave = (x + y + frame * 3) % 6
            if wave in (0, 1):
                row.append("B")
            elif wave in (2, 3):
                row.append("C")
            else:
                row.append("D")
        rows.append(row)
    return rows


def grass() -> list[list[str]]:
    rows = []
    for y in range(16):
        row = []
        for x in range(16):
            n = (x * 3 + y * 5) % 7
            row.append("8" if n == 0 else ("9" if n in (1, 2) else "A"))
        rows.append(row)
    return rows


def ice() -> list[list[str]]:
    rows = []
    for y in range(16):
        row = []
        for x in range(16):
            if x + y in (4, 10, 16) or (x, y) in {(2, 2), (13, 4), (5, 12)}:
                row.append("1")
            elif x in (0, 15) or y in (0, 15):
                row.append("C")
            else:
                row.append("B")
        rows.append(row)
    return rows


def base() -> list[list[str]]:
    rows = [["0"] * 16 for _ in range(16)]
    for y in range(16):
        for x in range(16):
            if x in (0, 15) or y in (0, 15):
                rows[y][x] = "6"
            else:
                rows[y][x] = "4"
    eagle = {
        (8, 3), (7, 4), (8, 4), (9, 4),
        (6, 5), (8, 5), (10, 5),
        (5, 6), (6, 6), (7, 6), (8, 6), (9, 6), (10, 6), (11, 6),
        (6, 7), (8, 7), (10, 7),
        (7, 8), (8, 8), (9, 8),
        (8, 9), (8, 10), (7, 11), (8, 11), (9, 11),
    }
    for x, y in eagle:
        rows[y][x] = "7"
    return rows


def powerup(fill: str, mark: str, ink: str = "0") -> list[list[str]]:
    rows = []
    for y in range(16):
        row = []
        for x in range(16):
            if x in (0, 15) or y in (0, 15):
                row.append("1")
            elif x in (1, 14) or y in (1, 14):
                row.append(ink)
            else:
                row.append(fill)
        rows.append(row)
    glyphs = {
        "S": [(8, 4), (7, 4), (6, 5), (7, 6), (8, 7), (9, 8), (8, 9), (7, 10), (8, 11), (9, 11)],
        "H": [(6, 4), (6, 5), (6, 6), (6, 7), (6, 8), (6, 9), (6, 10), (6, 11),
              (9, 4), (9, 5), (9, 6), (9, 7), (9, 8), (9, 9), (9, 10), (9, 11),
              (7, 7), (8, 7)],
        "T": [(6, 4), (7, 4), (8, 4), (9, 4), (8, 5), (8, 6), (8, 7), (8, 8), (8, 9), (8, 10), (7, 10), (9, 10)],
        "G": [(8, 4), (7, 5), (6, 6), (6, 7), (6, 8), (6, 9), (7, 10), (8, 11), (9, 10), (9, 8), (8, 8)],
        "C": [(8, 4), (7, 4), (6, 5), (6, 6), (6, 7), (6, 8), (6, 9), (6, 10), (7, 11), (8, 11), (9, 10)],
        "V": [(6, 4), (6, 5), (6, 6), (6, 7), (7, 8), (8, 9), (9, 8), (10, 7), (10, 6), (10, 5), (10, 4), (8, 10), (8, 11)],
    }
    for x, y in glyphs[mark]:
        rows[y][x] = ink
    return rows


def explosion(frame: int) -> list[list[str]]:
    rows = [["."] * 16 for _ in range(16)]
    radius = [2, 4, 6, 5, 3][frame]
    colors = ["4", "5", "E", "6", "3"]
    for y in range(16):
        for x in range(16):
            d = math.hypot(x - 7.5, y - 7.5)
            if d <= radius * 0.45:
                rows[y][x] = "1"
            elif d <= radius * 0.75:
                rows[y][x] = colors[frame]
            elif d <= radius:
                rows[y][x] = "7" if frame < 3 else "0"
    return rows


def bullet() -> list[list[str]]:
    rows = [["."] * 8 for _ in range(8)]
    for y in range(2, 6):
        for x in range(2, 6):
            rows[y][x] = "1" if 3 <= x <= 4 and 3 <= y <= 4 else "4"
    return rows


def write_wav(path: Path, samples: list[float], rate: int = 22050) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(path), "w") as wav:
        wav.setnchannels(1)
        wav.setsampwidth(2)
        wav.setframerate(rate)
        frames = b"".join(struct.pack("<h", max(-32767, min(32767, int(s * 32767)))) for s in samples)
        wav.writeframes(frames)


def tone(freq: float, duration: float, volume: float = 0.22, rate: int = 22050, decay: bool = True) -> list[float]:
    n = int(duration * rate)
    out = []
    for i in range(n):
        t = i / rate
        env = (1 - i / n) if decay else 1
        duty = 1 if ((t * freq) % 1) < 0.125 else -1
        out.append(duty * volume * env)
    return out


def noise(duration: float, volume: float = 0.2, rate: int = 22050) -> list[float]:
    n = int(duration * rate)
    seed = 1
    out = []
    for i in range(n):
        seed = (seed * 1103515245 + 12345) & 0x7FFFFFFF
        env = 1 - i / n
        out.append(((seed / 0x7FFFFFFF) * 2 - 1) * volume * env)
    return out


def concat(*parts: list[float]) -> list[float]:
    merged: list[float] = []
    for part in parts:
        merged.extend(part)
    return merged


def looped(pattern: list[float], times: int) -> list[float]:
    return pattern * times


def write_atlas_contents(names: list[str]) -> None:
    images = ",\n".join(
        f'    {{\n      "filename" : "{name}.png",\n      "idiom" : "universal"\n    }}'
        for name in names
    )
    (ATLAS / "Contents.json").write_text(
        "{\n  \"images\" : [\n"
        + images
        + "\n  ],\n  \"info\" : {\n    \"author\" : \"xcode\",\n    \"version\" : 1\n  },\n"
        + '  \"properties\" : {\n    \"compression-type\" : \"lossless\"\n  }\n}\n',
        encoding="utf-8",
    )


def main() -> None:
    ATLAS.mkdir(parents=True, exist_ok=True)
    ICON.mkdir(parents=True, exist_ok=True)
    AUDIO.mkdir(parents=True, exist_ok=True)
    LAUNCH.mkdir(parents=True, exist_ok=True)

    names: list[str] = []

    def add(name: str, pixels: list[list[str]]) -> None:
        write_atlas(name, pixels)
        names.append(name)

    add("tile_brick", brick())
    add("tile_steel", steel())
    add("tile_water_0", water(0))
    add("tile_water_1", water(1))
    add("tile_grass", grass())
    add("tile_ice", ice())
    add("tile_base", base())
    add("bullet", bullet())
    for index in range(5):
        add(f"explosion_{index}", explosion(index))

    tanks = {
        "player": ("4", "5", "1", "3"),
        "normal": ("2", "3", "1", "0"),
        "fast": ("B", "C", "1", "D"),
        "armored_green": ("9", "A", "8", "0"),
        "armored_yellow": ("4", "5", "1", "0"),
        "armored_gray": ("3", "2", "1", "0"),
        "armored_red": ("E", "7", "1", "0"),
    }
    for name, colors in tanks.items():
        add(f"tank_{name}_0", tank(*colors, 0))
        add(f"tank_{name}_1", tank(*colors, 1))

    add("boss_mini_0", boss(32, "E", "7", "5", 0))
    add("boss_mini_1", boss(32, "E", "7", "5", 1))
    add("boss_final_0", boss(48, "E", "7", "F", 0))
    add("boss_final_1", boss(48, "E", "7", "F", 1))

    add("powerup_star", powerup("4", "S"))
    add("powerup_helmet", powerup("2", "H"))
    add("powerup_tank", powerup("9", "T"))
    add("powerup_grenade", powerup("E", "G"))
    add("powerup_timer", powerup("B", "C"))
    add("powerup_shovel", powerup("5", "V"))

    write_atlas_contents(names)

    icon = scale(tank("4", "5", "6", "3", 0), 64)
    write_png(ICON / "AppIcon.png", icon)
    (ICON / "Contents.json").write_text(
        """{
  "images" : [
    { "filename" : "AppIcon.png", "idiom" : "universal", "platform" : "ios", "size" : "1024x1024" },
    { "appearances" : [{ "appearance" : "luminosity", "value" : "dark" }], "filename" : "AppIcon.png", "idiom" : "universal", "platform" : "ios", "size" : "1024x1024" },
    { "appearances" : [{ "appearance" : "luminosity", "value" : "tinted" }], "filename" : "AppIcon.png", "idiom" : "universal", "platform" : "ios", "size" : "1024x1024" }
  ],
  "info" : { "author" : "xcode", "version" : 1 }
}
""",
        encoding="utf-8",
    )

    logo = scale(tank("4", "5", "6", "3", 0), 8)
    write_png(LAUNCH / "LaunchLogo.png", logo)
    (LAUNCH / "Contents.json").write_text(
        """{
  "images" : [{ "filename" : "LaunchLogo.png", "idiom" : "universal", "scale" : "1x" }],
  "info" : { "author" : "xcode", "version" : 1 }
}
""",
        encoding="utf-8",
    )

    write_wav(AUDIO / "fire.wav", concat(tone(880, 0.04, 0.18), tone(440, 0.05, 0.12)))
    write_wav(AUDIO / "hit_brick.wav", concat(noise(0.06, 0.16), tone(180, 0.05, 0.12)))
    write_wav(AUDIO / "hit_steel.wav", concat(tone(1200, 0.04, 0.16, decay=True), tone(800, 0.05, 0.08)))
    write_wav(AUDIO / "explosion_small.wav", noise(0.18, 0.22))
    write_wav(AUDIO / "explosion_big.wav", concat(noise(0.28, 0.26), tone(90, 0.2, 0.12)))
    write_wav(AUDIO / "powerup_pickup.wav", concat(tone(523, 0.07, 0.16), tone(659, 0.07, 0.16), tone(784, 0.1, 0.18)))
    write_wav(AUDIO / "powerup_appear.wav", concat(tone(784, 0.06, 0.12), tone(988, 0.08, 0.12)))
    write_wav(AUDIO / "player_death.wav", concat(tone(392, 0.12, 0.18), tone(294, 0.14, 0.16), tone(196, 0.2, 0.14)))
    write_wav(AUDIO / "boss_phase.wav", concat(tone(196, 0.1, 0.2), tone(247, 0.1, 0.2), tone(330, 0.16, 0.22)))
    write_wav(AUDIO / "stage_start.wav", concat(tone(392, 0.08, 0.16), tone(523, 0.08, 0.16), tone(659, 0.16, 0.18)))
    write_wav(AUDIO / "game_over.wav", concat(tone(330, 0.16, 0.16), tone(262, 0.18, 0.14), tone(196, 0.28, 0.12)))

    menu = concat(
        tone(392, 0.2, 0.1, decay=False),
        tone(494, 0.2, 0.1, decay=False),
        tone(523, 0.2, 0.1, decay=False),
        tone(392, 0.2, 0.1, decay=False),
        tone(349, 0.2, 0.08, decay=False),
        tone(392, 0.4, 0.1, decay=False),
    )
    battle = concat(
        tone(262, 0.12, 0.1, decay=False),
        tone(330, 0.12, 0.1, decay=False),
        tone(392, 0.12, 0.1, decay=False),
        tone(330, 0.12, 0.1, decay=False),
        tone(294, 0.12, 0.09, decay=False),
        tone(262, 0.12, 0.09, decay=False),
        tone(196, 0.24, 0.1, decay=False),
    )
    boss_bgm = concat(
        tone(196, 0.16, 0.12, decay=False),
        tone(185, 0.16, 0.12, decay=False),
        tone(165, 0.16, 0.12, decay=False),
        tone(147, 0.32, 0.14, decay=False),
        tone(196, 0.16, 0.12, decay=False),
        tone(247, 0.32, 0.13, decay=False),
    )
    write_wav(AUDIO / "bgm_menu.wav", looped(menu, 4))
    write_wav(AUDIO / "bgm_battle.wav", looped(battle, 6))
    write_wav(AUDIO / "bgm_boss.wav", looped(boss_bgm, 6))


if __name__ == "__main__":
    main()
