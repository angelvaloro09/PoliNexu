"""Rutas relativas de páginas del SAES ya autenticado.

A diferencia de `base_url` (que sí varía por escuela, ver `schools.py`), estas
rutas son compartidas por todos los planteles — el SAES es el mismo producto
del DAE-IPN desplegado por campus. Verificadas navegando el menú "Alumnos"
en UPIICSA; si algún plantel resulta tener una ruta distinta, hay que
resolverlo por escuela en vez de asumir que esto es 100% universal.
"""

SCHEDULE_PATH = "/Alumnos/Informacion_semestral/Horario_Alumno.aspx"
GRADES_PATH = "/Alumnos/Informacion_semestral/calificaciones_sem.aspx"
KARDEX_PATH = "/Alumnos/boleta/kardex.aspx"

# Página que el worker de keep-alive golpea cada pocos minutos para resetear el
# sliding timeout de la Session de ASP.NET. Debe ser lo más barata posible: no
# se parsea, sólo importa el status. Sin autenticar, *cualquier* ruta bajo
# /Alumnos/ (exista o no) devuelve 302 a Default.aspx?ReturnUrl=..., así que la
# existencia real de esta página sólo se confirma con una sesión viva
# (`scripts/probe_session.py`).
KEEPALIVE_PATH = "/Alumnos/default.aspx"
