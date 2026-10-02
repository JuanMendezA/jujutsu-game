# jujutsu-game

Prototipo de un juego de Roblox estilo Jujutsu Kaizen con mecánicas tipo Type Soul / Heian. El diseño está en [docs/diseno.md](docs/diseno.md).

## Qué incluye

- Combate M1 (combo de 4), bloqueo (F), esquiva con invulnerabilidad (Q).
- **Black Flash**: haz clic justo cuando termina el cooldown del golpe anterior y el daño se multiplica x2.5.
- Energía maldita que se regenera y se gasta en técnicas.
- Dos técnicas innatas que se sortean al entrar: Manipulación de Sangre (80%) e Infinito (20%), cada una con Z y X.
- Maldiciones enemigas que persiguen, atacan, dan XP y reaparecen.
- Nivel y XP guardados con DataStore.

## Estructura (Rojo)

| Carpeta | En Roblox |
|---|---|
| `src/shared` | `ReplicatedStorage.Shared` (configuración y remotes) |
| `src/server` | `ServerScriptService.Server` |
| `src/client` | `StarterPlayer.StarterPlayerScripts.Client` |

Todo el balance (daño, cooldowns, técnicas) está en `src/shared/Config.luau`.

## Cómo probar

1. Instala [Rojo](https://rojo.space) y su plugin de Studio.
2. En esta carpeta: `rojo serve`, y en Studio pulsa **Connect** en el plugin.
3. Para que se guarde el progreso en Studio: *Game Settings → Security → Enable Studio Access to API Services*.
4. Opcional: crea en `Workspace` una carpeta `CurseSpawns` con partes donde quieras que aparezcan las maldiciones.

## Limitaciones conocidas

- Los empujones de técnicas mueven bien a las maldiciones, pero a otros jugadores puede que no (su física la controla su cliente).
- El Black Flash depende de la latencia del jugador; la ventana se puede ajustar en `Config.BlackFlash.Window`.
