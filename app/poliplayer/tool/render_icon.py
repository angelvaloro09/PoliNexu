"""Genera los PNG de la marca de PoliNexu para el ícono de launcher y el splash.

Reproduce la MISMA geometría que `lib/presentation/widgets/nexus_mark.dart`
(`NexusGeometry`): tres nodos en triángulo con el vértice arriba, unidos por un
trazo cerrado. Si cambias la marca en Dart, cambia aquí también — no hay forma
de compartir el código entre un CustomPainter y un script de build.

Uso (desde `app/poliplayer/`, con Pillow instalado):

    python tool/render_icon.py

Salida en `assets/branding/`, que es lo que consumen `flutter_launcher_icons` y
`flutter_native_splash` (ver `pubspec.yaml`).
"""

import math
from pathlib import Path

from PIL import Image, ImageDraw

OUT_DIR = Path(__file__).resolve().parent.parent / "assets" / "branding"

# Mismos tokens que `AppTheme`.
BRAND_BLUE = (30, 99, 209, 255)      # geminiSeedLight  #1E63D1
BRAND_BLUE_LIGHT = (91, 147, 245, 255)  # segundo tono del degradado de marca
BRAND_BLUE_DARK = (168, 199, 250, 255)  # geminiSeedDark   #A8C7FA
SURFACE_LIGHT = (248, 249, 250, 255)  # #F8F9FA
SURFACE_DARK = (19, 19, 20, 255)      # #131314
TRANSPARENT = (0, 0, 0, 0)

# Supermuestreo: Pillow no antialiasa `line`/`ellipse`, así que se dibuja en
# grande y se reduce con LANCZOS.
SCALE = 4

RADIUS_FACTOR = 0.72
EDGE_ALPHA = 0.45


def _nodes(size: float, inset: float) -> list[tuple[float, float]]:
    """Centros de los tres nodos. `inset` encoge la marca dentro del lienzo.

    Igual que en Dart: el triángulo con vértice arriba ocupa de -r a +r/2, así
    que se baja un cuarto de radio para centrar la caja que realmente ocupa.
    """
    center = size / 2
    radius = center * RADIUS_FACTOR * inset
    cy = center + radius * 0.25
    return [
        (
            center + math.cos(-math.pi / 2 + i * (2 * math.pi / 3)) * radius,
            cy + math.sin(-math.pi / 2 + i * (2 * math.pi / 3)) * radius,
        )
        for i in range(3)
    ]


def _lerp(
    a: tuple[int, int, int, int], b: tuple[int, int, int, int], t: float
) -> tuple[int, int, int, int]:
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(4))  # type: ignore[return-value]


def _with_alpha(color: tuple[int, int, int, int], alpha: float) -> tuple[int, int, int, int]:
    return (color[0], color[1], color[2], int(color[3] * alpha))


def render(
    size: int,
    *,
    fg: tuple[int, int, int, int],
    bg: tuple[int, int, int, int],
    accent: tuple[int, int, int, int] | None = None,
    inset: float = 1.0,
    solid: bool = True,
) -> Image.Image:
    canvas = size * SCALE
    image = Image.new("RGBA", (canvas, canvas), bg)
    draw = ImageDraw.Draw(image)

    nodes = _nodes(canvas, inset)
    edge_width = max(1.5, canvas * 0.028 * inset)
    node_radius = max(2.5, canvas * 0.075 * inset)

    # Trazo cerrado. `joint="curve"` redondea las uniones, como el
    # StrokeJoin.round del pintor de Dart.
    draw.line(
        [*nodes, nodes[0]],
        fill=_with_alpha(fg, EDGE_ALPHA),
        width=int(edge_width),
        joint="curve",
    )

    # Degradado diagonal como en Dart: se aproxima coloreando cada nodo según
    # su posición sobre la diagonal del lienzo.
    for x, y in nodes:
        t = 0.0 if accent is None else ((x + y) / (2 * canvas))
        node_fill = fg if accent is None else _lerp(fg, accent, min(1.0, max(0.0, t * 1.6)))
        draw.ellipse(
            [x - node_radius, y - node_radius, x + node_radius, y + node_radius],
            fill=node_fill,
        )
        if not solid:
            core = node_radius * 0.38
            draw.ellipse([x - core, y - core, x + core, y + core], fill=bg)

    return image.resize((size, size), Image.LANCZOS)


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)

    outputs = {
        # Ícono legacy: marca sobre el fondo claro de la app.
        "icon.png": dict(
            size=1024, fg=BRAND_BLUE, accent=BRAND_BLUE_LIGHT, bg=SURFACE_LIGHT, inset=0.86
        ),
        # Adaptativo: la capa de primer plano debe dejar margen porque el
        # launcher recorta hasta un 33% del borde según la forma del sistema.
        "icon_foreground.png": dict(
            size=1024, fg=BRAND_BLUE, accent=BRAND_BLUE_LIGHT, bg=TRANSPARENT, inset=0.52
        ),
        # Monocromo (íconos temáticos de Android 13+): silueta plana.
        "icon_monochrome.png": dict(
            size=1024, fg=(0, 0, 0, 255), bg=TRANSPARENT, inset=0.52
        ),
        # Splash nativo, una versión por tema. Android 12+ dibuja este ícono
        # dentro de una ventana circular que recorta como el ícono adaptativo
        # (hasta 33% del borde) — mismo inset que `icon_foreground.png`, si no
        # el trazo queda cortado por el círculo.
        "splash_light.png": dict(size=512, fg=BRAND_BLUE, bg=TRANSPARENT, inset=0.52),
        "splash_dark.png": dict(size=512, fg=BRAND_BLUE_DARK, bg=TRANSPARENT, inset=0.52),
    }

    for name, kwargs in outputs.items():
        # El monocromo y el adaptativo van macizos: el núcleo hueco desaparece
        # a tamaños pequeños y sólo ensucia la silueta.
        image = render(**kwargs, solid=True)
        image.save(OUT_DIR / name)
        print(f"  {name:24} {image.size[0]}x{image.size[1]}")

    print(f"\nEscrito en {OUT_DIR}")


if __name__ == "__main__":
    main()
