"""Bake the iOS loading screen into a silent, independently playable H.264 track."""
from hashlib import sha256
import json
import math
from pathlib import Path
import subprocess
from tempfile import TemporaryDirectory

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / 'assets'
DOCS = ROOT / 'docs'
SIZE = (480, 960)
FPS = 25
TIP_FRAMES = 48
PAGE_COLOR = (36, 37, 56)
GLOW_COLOR = (59, 50, 73)
MOTIF_COLOR = (68, 59, 80)
METER = (62, 532, 418, 548)


def mix(a, b, weight):
    return tuple(round(first + (second - first) * weight) for first, second in zip(a, b))


def edge_weight(x, y):
    return min(1, max(0, min(x, SIZE[0] - x) / 45),
               max(0, min(y, SIZE[1] - y) / 60))


def backdrop():
    width, height = SIZE
    gradient = Image.new('RGB', (width // 4, height // 4))
    for y in range(gradient.height):
        for x in range(gradient.width):
            px, py = 4 * x, 4 * y
            glow = max(0, 1 - math.hypot((px - width / 2) / 400, (py - 65) / 735))
            gradient.putpixel((x, y), mix(PAGE_COLOR, GLOW_COLOR, glow * edge_weight(px, py)))
    image = gradient.resize(SIZE, Image.Resampling.BICUBIC)
    draw = ImageDraw.Draw(image)
    heart = [(0, 3), (0, 0), (6, 0), (6, 3), (12, 3), (12, 0),
             (18, 0), (18, 9), (15, 9), (15, 14), (12, 14), (12, 17),
             (9, 17), (9, 20), (6, 20), (6, 17), (3, 17), (3, 11), (0, 11), (0, 3)]
    star = [(0, 6), (5, 6), (5, 3), (8, 3), (8, 0), (11, 0), (11, 6),
            (16, 6), (16, 9), (11, 9), (11, 15), (8, 15), (8, 11),
            (5, 11), (5, 9), (0, 9), (0, 6)]
    for y in range(5, height, 104):
        for x in range(12, width, 132):
            for dx, dy, motif in ((0, 0, heart), (72, 42, star)):
                ox, oy = x + dx, y + dy
                if ox >= width or oy >= height:
                    continue
                draw.line([(ox + mx, oy + my) for mx, my in motif], fill=MOTIF_COLOR, width=2)
    draw.rounded_rectangle(METER, radius=8, fill='#342c42', outline='#a07890', width=2)
    return image


def prepare_tips(tips, font):
    images = []
    for tip in tips:
        layer = Image.new('RGBA', (400, 76))
        draw = ImageDraw.Draw(layer)
        lines = ['']
        for word in tip.split():
            line = (lines[-1] + ' ' + word).strip()
            if lines[-1] and draw.textlength(line, font=font) > 394:
                lines.append(word)
            else:
                lines[-1] = line
        draw.multiline_text((200, 36), '\n'.join(lines), fill='#f5e3cf',
                            font=font, anchor='mm', align='center', spacing=3)
        images.append(layer)
    return images


def fill_amount(phase):
    # A decorative cycle leaves time for several tips during a slow launch.
    stops = [(0, .035), (.09, .24), (.11, .24), (.26, .49), (.30, .49),
             (.45, .71), (.48, .71), (.66, .88), (.71, .88), (.88, .97), (1, .97)]
    for (begin, value), (end, target) in zip(stops, stops[1:]):
        if phase <= end:
            t = (phase - begin) / (end - begin)
            return value + (target - value) * t * (2 - t)
    return .97


def meter(frame, phase):
    left, top, right, bottom = METER
    width = right - left - 3
    inner = Image.new('RGB', (width, bottom - top - 3), '#342c42')
    draw = ImageDraw.Draw(inner)
    head = round(width * fill_amount(phase))
    # The last highlight wipes the full bar away as the next pass starts.
    handover = max(0, (phase - .96) / .04)
    tail = round(handover * head)
    new_head = round(handover * width * .035)
    glint = ((frame % 96) / 96 * 1.4 - .2) * width
    for x in range(head):
        if new_head <= x < tail:
            continue
        base = mix((161, 117, 148), (239, 188, 208), x / width)
        glow = .6 * max(0, 1 - abs(x - glint) / 35)
        draw.line((x, 0, x, inner.height), fill=mix(base, (255, 236, 219), glow))
    return inner


def encode(path, stills, tips, signature, poster):
    count = len(tips) * TIP_FRAMES
    left, top, right, bottom = METER
    mask = Image.new('L', (right - left - 3, bottom - top - 3))
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, mask.width - 1, mask.height - 1), radius=6, fill=255)
    # Keep the poster neutral across the public and personalized editions.
    if poster is not None:
        image = stills[0].copy()
        image.paste(meter(0, 0), (left + 2, top + 2), mask)
        image.save(poster, optimize=True)
    # FFmpeg composites the small moving region over the same static backdrop.
    # This avoids transferring an entire portrait frame through the pipe at 25 Hz.
    crop = (32, 328, 448, 640)
    with TemporaryDirectory(dir=path.parent) as temporary:
        work = Path(temporary)
        stills[0].save(work / 'backdrop.png')
        encoded = work / path.name
        cmd = ['ffmpeg', '-hide_banner', '-loglevel', 'error', '-y',
               '-loop', '1', '-framerate', str(FPS), '-i', str(work / 'backdrop.png'),
               '-f', 'rawvideo', '-pixel_format', 'rgb24', '-video_size', '416x312',
               '-framerate', str(FPS), '-i', 'pipe:0',
               '-filter_complex_threads', '1', '-filter_complex',
               '[0:v][1:v]overlay=32:328:format=rgb:shortest=1,scale=out_color_matrix=bt709,format=yuv420p',
               '-frames:v', str(count), '-an', '-c:v', 'libx264', '-profile:v', 'baseline',
               '-level', '3.1', '-threads', '3', '-preset', 'veryfast', '-crf', '18',
               '-g', str(FPS * 2), '-colorspace', 'bt709', '-color_primaries', 'bt709',
               '-color_trc', 'bt709', '-metadata', 'comment=' + signature,
               '-movflags', '+faststart', str(encoded)]
        crops = [still.crop(crop) for still in stills]
        with subprocess.Popen(cmd, stdin=subprocess.PIPE) as process:
            try:
                for n in range(count):
                    frame = crops[(n // 2) % len(crops)].copy()
                    frame.paste(meter(n, n / count), (left + 2 - crop[0], top + 2 - crop[1]), mask)
                    tip = tips[n // TIP_FRAMES]
                    frame.paste(tip, (40 - crop[0], 554 - crop[1]), tip)
                    process.stdin.write(frame.tobytes())
            finally:
                process.stdin.close()
            if process.wait() != 0:
                raise RuntimeError(f'Failed to encode {path.name}')
        encoded.replace(path)


def generate():
    sheet = ASSETS / 'loading_heroine.png'
    font_path = ASSETS / 'body.ttf'
    digest = sha256(Path(__file__).read_bytes() + sheet.read_bytes() + font_path.read_bytes())
    poster = DOCS / 'ios-loading-poster.png'
    stills = []
    for source, output in [('letters.json', 'ios-loading.mp4'), ('letters.backup.json', 'ios-loading-play.mp4')]:
        content = json.loads((ROOT / 'content' / source).read_text())
        phrases = [content['ui'][key]['text'] for key in content['loading_phrases']]
        signature = digest.copy()
        signature.update(json.dumps(phrases, ensure_ascii=False).encode())
        tag = 'garden-loading-' + signature.hexdigest()
        path = DOCS / output
        if poster.exists() and path.exists() and tag.encode() in path.read_bytes():
            continue
        if not stills:
            background = backdrop()
            with Image.open(sheet) as sprite_sheet:
                for index in range(8):
                    pose = sprite_sheet.crop((64 * index, 0, 64 * (index + 1), 64))
                    pose = pose.resize((160, 160), Image.Resampling.NEAREST)
                    image = background.copy()
                    image.paste(pose, (160, 344), pose)
                    stills.append(image)
        font = ImageFont.truetype(str(font_path), 24)
        encode(path, stills, prepare_tips(phrases, font), tag,
               poster if output == 'ios-loading.mp4' or not poster.exists() else None)


if __name__ == '__main__':
    generate()
