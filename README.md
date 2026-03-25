*This project has been created as part of the 42 curriculum by \<login1\>[, \<login2\>].*

---

# cub3D

## Description

cub3D is a 3D maze explorer built with the **DDA (Digital Differential Analysis)** raycasting algorithm, inspired by the original Wolfenstein 3D engine. The program reads a `.cub` configuration file that defines wall textures, floor/ceiling colors, and a 2D map, then renders a first-person 3D view in real time using the MiniLibX graphics library.

Key features:
- Raycasting engine with per-side wall textures (N/S/E/W)
- Configurable floor and ceiling colors via RGB
- Player movement and rotation (WASD + arrow keys)
- Strict map and config file validation with meaningful error messages
- Clean memory management (no leaks on exit)

Bonus features:
- Wall collisions
- Minimap system
- Openable/closable doors (`2` in map)
- Animated sprites
- Mouse rotation

---

## Instructions

### Requirements

- Linux or macOS
- `gcc`, `make`
- MiniLibX (included or system-provided)

### Compilation

```bash
# Mandatory
make

# Bonus
make bonus

# Clean
make clean
make fclean
make re
```

The executable produced is `cub3D` (or `cub3D_bonus` for the bonus version).

### Running

```bash
./cub3D path/to/map.cub
```

The map file must have the `.cub` extension and follow this format:

```
NO ./textures/north.xpm
SO ./textures/south.xpm
WE ./textures/west.xpm
EA ./textures/east.xpm
F 220,100,0
C 225,30,0

111111
100001
1N0001
100001
111111
```

Valid map characters: `0` (empty), `1` (wall), `N`/`S`/`E`/`W` (player spawn), `2` (door, bonus only).

### Controls

| Key | Action |
|-----|--------|
| `W` / `Z` | Move forward |
| `S` | Move backward |
| `A` / `Q` | Strafe left |
| `D` | Strafe right |
| `←` | Rotate left |
| `→` | Rotate right |
| Mouse | Rotate (bonus) |
| `ESC` / `Q` | Quit |
| `E` | Open/close door (bonus) |

### Valgrind Test Suites

Two test scripts are included to verify memory safety:

```bash
# Mandatory tests
./valgrind_mandatory.sh ./cub3D ./maps

# Bonus tests
./valgrind_bonus.sh ./cub3D_bonus ./maps
```

Both scripts accept two optional arguments:
- `$1` — path to the binary (default: `./cub3D`)
- `$2` — path to the maps directory (default: `./maps`)

The scripts auto-generate all required test maps inside the maps directory, then run valgrind with:
```
--leak-check=full --show-leak-kinds=all --track-origins=yes --error-exitcode=42
```

Test sections covered by `valgrind_mandatory.sh`:
1. Argument validation (no args, too many, wrong extension, missing file)
2. Texture errors (duplicate, non-existent path, missing `.xpm`)
3. Color errors (wrong component count, out-of-range, negative values)
4. Map validation (no player, open map, invalid char, multiple players)
5. Edge cases (path to directory)
6. Valid maps — headless leak check (DISPLAY unset to force fast mlx exit)

Test sections covered by `valgrind_bonus.sh`:
1. Door parsing + no leak (single, multiple, adjacent to spawn, all spawn directions)
2. Invalid door placement (door on border)
3. Minimap stress (large 11×19 map)
4. Valid maps with bonus binary
5. Wall collision maps (corner spawn, narrow corridor)
6. Animated sprites init (no crash)

To check for leaks on macOS during live execution:
```bash
while true; do leaks cub3D; sleep 1; done
```

---

## Resources

### Documentation & References

- [MiniLibX Linux documentation](https://harm-smits.github.io/42docs/libs/minilibx)
- [Lode's Raycasting Tutorial](https://lodev.org/cgtutor/raycasting.html) — primary reference for DDA algorithm and texture mapping
- [Ray-Casting Tutorial by F. Permadi](https://permadi.com/1996/05/ray-casting-tutorial-table-of-contents/)
- [Wolfenstein 3D source code](https://github.com/id-Software/wolf3d) — original engine inspiration

### AI Usage

AI assistance (Claude) was used for the following tasks:
- **Valgrind test scripts** (`valgrind_mandatory.sh`, `valgrind_bonus.sh`): generating comprehensive edge-case maps and structuring the test suite logic
- **Debugging memory leaks**: identifying patterns in valgrind output and suggesting free/cleanup sequences
- **README**: drafting and structuring this document

All core logic — raycasting engine, DDA implementation, texture mapping, map parsing, and MiniLibX rendering — was written and understood by the team members.
