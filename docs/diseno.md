# Documento de diseño (borrador v0.1)

Juego de Roblox ambientado en Jujutsu Kaizen con mecánicas al estilo Type Soul y Heian. Es un RPG de acción multijugador: eliges un camino, peleas, subes de nivel y desbloqueas técnicas cada vez más fuertes hasta llegar a la Expansión de Dominio.

> Nota: los nombres de personajes y técnicas de JJK son propiedad de su autor. Para publicar en Roblox conviene usar nombres propios o "inspirados" (por ejemplo, "Infinito" pasa a ser "Vacío Absoluto"). En este borrador uso los nombres originales para que se entienda la idea.

## 1. Bucle principal

1. Entras al mundo y eliges un **camino** (equivalente a las razas de Type Soul).
2. Haces misiones, exorcizas maldiciones y peleas contra jugadores para ganar **XP** y **energía maldita máxima**.
3. Al subir de nivel desbloqueas pasos de progresión: técnica innata, Black Flash, Reversa, Dominio.
4. El final de cada camino es dominar tu técnica y ganar rango (Grado 4 → Grado Especial).

## 2. Caminos (razas)

| Camino | Equivalente en Type Soul | Estilo | Progresión clave |
|---|---|---|---|
| **Hechicero** | Shinigami | Equilibrado, técnica innata aleatoria | Técnica → Black Flash → Reversa → Dominio |
| **Maldición** | Hollow | Agresivo, se cura comiendo almas/maldiciones | Forma básica → Evolución → Maldición de Grado Especial → Dominio |
| **Restricción Celestial** | Quincy (estilo diferente) | Sin energía maldita, cuerpo físico extremo y armas malditas | Armas → Sentidos → Cuerpo perfecto (sin dominio, pero inmune a dominios simples) |

Opcional más adelante: **Usuario de Maldiciones (Geto)**, que captura maldiciones y las invoca.

## 3. Técnicas innatas (el "zanpakuto")

Al crear personaje se tira una técnica con rareza (como el spin de Heian). Cada técnica tiene 4 movimientos en teclas Z, X, C, V más una versión despertada.

| Rareza | Ejemplos (inspirados) |
|---|---|
| Común | Manipulación de sangre, Muñecos de paja, Construcción |
| Rara | Diez Sombras, Habla Maldita, Proporción (7:3) |
| Épica | Llama del desastre, Transfiguración inactiva |
| Legendaria | Infinito, Santuario |

Se pueden conseguir rerolls jugando (no solo pagando) para que no sea pay-to-win.

## 4. Combate

- **M1** (clics) en combo de 4 golpes, con bloqueo (F), esquiva (Q) y rotura de guardia.
- **Energía maldita**: barra que se gasta con técnicas y se recarga peleando o meditando.
- **Black Flash**: si golpeas justo en una ventana de tiempo pequeña, el daño se multiplica (x2.5) y te da un aumento temporal. Es la mecánica de habilidad del juego.
- **Técnica Maldita Reversa**: curación que gasta mucha energía; se desbloquea a nivel alto.
- **Dominio Simple / Hollow Wicker Basket**: defensa contra dominios para quien no tiene uno.

## 5. Expansión de Dominio (el "bankai")

- Se desbloquea con una misión difícil al llegar a cierto nivel.
- Crea una esfera alrededor del jugador: dentro, sus técnicas **aciertan siempre** durante unos segundos.
- **Choque de dominios**: si dos jugadores lo abren a la vez, gana quien tenga más maestría (minijuego de pulsar teclas).
- Después del dominio, la técnica queda "quemada" unos segundos (como en el anime), lo que equilibra su poder.

## 6. Progresión

- **Nivel** (1 a 100) sube con XP.
- **Grado** (4, 3, 2, 1, Especial) se gana con misiones de ascenso y es lo que ven los demás.
- **Maestría de técnica**: sube usando la técnica y desbloquea los movimientos V, la versión despertada y el dominio.
- Lo que pierdes al morir: nada importante al principio; quizá en zonas PvP se pierden objetos.

## 7. Mundo

- **Escuela Jujutsu de Tokio**: zona segura, tutorial, tienda, misiones.
- **Shibuya**: zona abierta con PvP activado y maldiciones de alto grado.
- **Ciudad / bosque**: misiones de exorcismo de bajo nivel.
- Más adelante: **Era Heian**, una zona de alto nivel inspirada en el juego del mismo nombre.

## 8. Primer prototipo (alcance mínimo)

Para no perderse, la primera versión jugable tendría solo:

1. Un mapa pequeño (la escuela y una zona de combate).
2. El camino **Hechicero** con 2 técnicas (una común y una legendaria).
3. Combate M1, bloqueo, esquiva y Black Flash.
4. Energía maldita y una barra de vida.
5. Enemigos maldición básicos con IA simple.
6. Guardado del progreso (nivel y técnica) en DataStore.

## 9. Base técnica propuesta (Luau)

- **Rojo + Git** para trabajar el código fuera de Roblox Studio y tenerlo en un repositorio.
- El servidor manda en todo (daño, cooldowns, energía) para evitar exploits; el cliente solo envía "quiero usar la técnica X" y reproduce animaciones y efectos.
- Estructura de carpetas:
  - `ServerScriptService/Combat` (daño, hitboxes, Black Flash)
  - `ServerScriptService/Data` (guardado con DataStore)
  - `ReplicatedStorage/Techniques` (un módulo por técnica con sus movimientos)
  - `StarterPlayerScripts/Input` (teclas Z, X, C, V, M1)
  - `StarterGui` (vida, energía, cooldowns)
