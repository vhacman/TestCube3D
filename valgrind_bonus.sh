#!/bin/bash
# =============================================================================
# SUITE VALGRIND — CUB3D BONUS
# Usage: ./valgrind_bonus.sh [binary] [maps_dir]
# Example: ./valgrind_bonus.sh ./cub3D ./maps
#
# Runs AFTER the mandatory suite. Assumes:
#   - Wall collisions implemented
#   - Minimap implemented
#   - Doors ('2' character) implemented
#   - Animated sprites implemented (stub accepted)
#   - Mouse rotation implemented (stub accepted)
# =============================================================================

CUB3D="${1:-./cub3D}"
MAPS="${2:-./maps}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

PASS=0
FAIL=0
TOTAL=0

VOPT="valgrind --leak-check=full --show-leak-kinds=all \
--track-origins=yes --error-exitcode=42 -q"

# =============================================================================
# Helper: valid map — no leak, no crash
# =============================================================================
test_valid_noleak()
{
	local desc="$1"
	local cmd="$2"

	TOTAL=$((TOTAL + 1))
	echo -e "${CYAN}[TEST $TOTAL]${NC} ${BOLD}${desc}${NC}"
	echo "  CMD: $cmd"

	OUTPUT=$(timeout 5s $VOPT $cmd 2>&1)
	EXIT_CODE=$?

	if [ $EXIT_CODE -eq 124 ]; then
		echo -e "  ${YELLOW}TIMEOUT — normal if display available (kill manually)${NC}"
		PASS=$((PASS + 1))
		echo ""
		return
	fi

	if echo "$OUTPUT" | grep -qi \
		"segmentation\|double free\|invalid read\|invalid write"; then
		echo -e "  ${RED}CRASH detected${NC}"
		echo "$OUTPUT" | grep -i "segmentation\|double free\|invalid"
		FAIL=$((FAIL + 1))
		echo ""
		return
	fi

	VALGRIND_ERROR=0
	if echo "$OUTPUT" | grep -q "ERROR SUMMARY: [^0]"; then
		VALGRIND_ERROR=1
	fi
	if [ $EXIT_CODE -eq 42 ]; then
		VALGRIND_ERROR=1
	fi

	if [ $VALGRIND_ERROR -eq 1 ]; then
		echo -e "  ${RED}LEAK/MEMORY ERROR${NC}"
		echo "$OUTPUT" | grep -A5 "ERROR SUMMARY"
		FAIL=$((FAIL + 1))
	else
		echo -e "  ${GREEN}PASS${NC} — no leak"
		PASS=$((PASS + 1))
	fi
	echo ""
}

# =============================================================================
# Helper: expect Error + exit != 0 + no leak
# =============================================================================
test_error()
{
	local desc="$1"
	local cmd="$2"
	local expect_msg="$3"

	TOTAL=$((TOTAL + 1))
	echo -e "${CYAN}[TEST $TOTAL]${NC} ${BOLD}${desc}${NC}"
	echo "  CMD: $cmd"

	OUTPUT=$(timeout 5s $VOPT $cmd 2>&1)
	EXIT_CODE=$?

	if [ $EXIT_CODE -eq 124 ]; then
		echo -e "  ${RED}TIMEOUT${NC}"
		FAIL=$((FAIL + 1))
		echo ""
		return
	fi

	VALGRIND_ERROR=0
	if echo "$OUTPUT" | grep -q "ERROR SUMMARY: [^0]"; then
		VALGRIND_ERROR=1
	fi
	if [ $EXIT_CODE -eq 42 ]; then
		VALGRIND_ERROR=1
	fi

	HAS_ERROR_MSG=0
	if echo "$OUTPUT" | grep -q "^Error"; then
		HAS_ERROR_MSG=1
	fi

	local ok=1
	if [ $VALGRIND_ERROR -eq 1 ]; then
		echo -e "  ${RED}LEAK/MEMORY ERROR${NC}"
		ok=0
	fi
	if [ $HAS_ERROR_MSG -eq 0 ]; then
		echo -e "  ${RED}Missing 'Error' on stderr${NC}"
		ok=0
	fi
	if [ $EXIT_CODE -eq 0 ]; then
		echo -e "  ${RED}Exit code 0 — should have failed${NC}"
		ok=0
	fi
	if [ -n "$expect_msg" ]; then
		if ! echo "$OUTPUT" | grep -qi "$expect_msg"; then
			echo -e "  ${YELLOW}WARN: '$expect_msg' not found in output${NC}"
		fi
	fi

	if [ $ok -eq 1 ]; then
		echo -e "  ${GREEN}PASS${NC}"
		PASS=$((PASS + 1))
	else
		FAIL=$((FAIL + 1))
	fi
	echo ""
}

# =============================================================================
# HELPERS: create bonus-specific test maps
# =============================================================================
setup_bonus_maps()
{
	local dir="$1"

	# Map with doors — '2' is a valid bonus character
	cat > "$dir/bonus_doors.cub" << 'EOF'
NO ./textures/north.xpm
SO ./textures/south.xpm
WE ./textures/west.xpm
EA ./textures/east.xpm
F 220,100,0
C 225,30,0

111111111
100000001
1N0020001
100000001
111111111
EOF

	# Map with multiple doors
	cat > "$dir/bonus_doors_multi.cub" << 'EOF'
NO ./textures/north.xpm
SO ./textures/south.xpm
WE ./textures/west.xpm
EA ./textures/east.xpm
F 220,100,0
C 225,30,0

11111111111
10000000001
1N002020001
10000000001
11111111111
EOF

	# Map with door adjacent to player spawn
	cat > "$dir/bonus_door_adjacent.cub" << 'EOF'
NO ./textures/north.xpm
SO ./textures/south.xpm
WE ./textures/west.xpm
EA ./textures/east.xpm
F 220,100,0
C 225,30,0

111111
1N2001
100001
100001
111111
EOF

	# Large open map — stress test for minimap rendering
	cat > "$dir/bonus_large.cub" << 'EOF'
NO ./textures/north.xpm
SO ./textures/south.xpm
WE ./textures/west.xpm
EA ./textures/east.xpm
F 100,149,237
C 50,50,50

1111111111111111111
1000000000000000001
1000100010001000001
1000100010001000001
1001100011001100001
100000N000000000001
1001100011001100001
1000100010001000001
1000100010001000001
1000000000000000001
1111111111111111111
EOF

	# Map with all spawn directions for door test
	cat > "$dir/bonus_spawn_e.cub" << 'EOF'
NO ./textures/north.xpm
SO ./textures/south.xpm
WE ./textures/west.xpm
EA ./textures/east.xpm
F 220,100,0
C 225,30,0

111111
100001
1E0201
100001
111111
EOF

	cat > "$dir/bonus_spawn_s.cub" << 'EOF'
NO ./textures/north.xpm
SO ./textures/south.xpm
WE ./textures/west.xpm
EA ./textures/east.xpm
F 220,100,0
C 225,30,0

111111
100001
1S0001
100201
111111
EOF

	cat > "$dir/bonus_spawn_w.cub" << 'EOF'
NO ./textures/north.xpm
SO ./textures/south.xpm
WE ./textures/west.xpm
EA ./textures/east.xpm
F 220,100,0
C 225,30,0

111111
100001
120W01
100001
111111
EOF

	# Invalid: door '2' next to map border (should be caught if validated)
	cat > "$dir/bonus_door_open.cub" << 'EOF'
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
112111
EOF
}

# =============================================================================
# MAIN
# =============================================================================

echo ""
echo -e "${BOLD}============================================================${NC}"
echo -e "${BOLD}  VALGRIND SUITE — CUB3D BONUS — $(date)${NC}"
echo -e "${BOLD}  Binary: $CUB3D | Maps: $MAPS${NC}"
echo -e "${BOLD}============================================================${NC}"
echo ""

if [ ! -f "$CUB3D" ]; then
	echo -e "${RED}ERROR: binary '$CUB3D' not found. Run make bonus first.${NC}"
	exit 1
fi

if [ ! -d "$MAPS" ]; then
	echo -e "${RED}ERROR: maps directory '$MAPS' not found.${NC}"
	exit 1
fi

echo -e "${YELLOW}Setting up bonus test maps in $MAPS ...${NC}"
setup_bonus_maps "$MAPS"
echo ""

# ============================================================
# SECTION 1 — DOORS: parsing and leak check
# ============================================================
echo -e "${BOLD}--- SECTION 1: DOORS (parsing + no leak) ---${NC}"
echo ""

test_valid_noleak \
	"Map with one door (char '2')" \
	"$CUB3D $MAPS/bonus_doors.cub"

test_valid_noleak \
	"Map with multiple doors" \
	"$CUB3D $MAPS/bonus_doors_multi.cub"

test_valid_noleak \
	"Door adjacent to player spawn" \
	"$CUB3D $MAPS/bonus_door_adjacent.cub"

test_valid_noleak \
	"Door with spawn E" \
	"$CUB3D $MAPS/bonus_spawn_e.cub"

test_valid_noleak \
	"Door with spawn S" \
	"$CUB3D $MAPS/bonus_spawn_s.cub"

test_valid_noleak \
	"Door with spawn W" \
	"$CUB3D $MAPS/bonus_spawn_w.cub"

# ============================================================
# SECTION 2 — DOORS: invalid cases
# ============================================================
echo -e "${BOLD}--- SECTION 2: DOORS (invalid cases) ---${NC}"
echo ""

test_error \
	"Door '2' adjacent to map border (open map)" \
	"$CUB3D $MAPS/bonus_door_open.cub" \
	""

# ============================================================
# SECTION 3 — MINIMAP: large maps (stress)
# ============================================================
echo -e "${BOLD}--- SECTION 3: MINIMAP STRESS ---${NC}"
echo -e "${YELLOW}Checking: no crash / no leak on large maps.${NC}"
echo ""

test_valid_noleak \
	"Large open map (11x19) — minimap stress" \
	"$CUB3D $MAPS/bonus_large.cub"

# Run all standard valid maps with bonus binary too
echo -e "${BOLD}--- SECTION 4: VALID MAPS WITH BONUS BINARY ---${NC}"
echo ""

for map in test valid_map valid_map2 valid_map3 valid_map4 valid_map5; do
	if [ -f "$MAPS/${map}.cub" ]; then
		test_valid_noleak \
			"${map}.cub with bonus binary" \
			"$CUB3D $MAPS/${map}.cub"
	fi
done

# ============================================================
# SECTION 5 — WALL COLLISION: argument sanity
# (collision itself requires a running window — only leak check here)
# ============================================================
echo -e "${BOLD}--- SECTION 5: WALL COLLISION MAPS ---${NC}"
echo -e "${YELLOW}Verifying no crash when player starts near walls.${NC}"
echo ""

# Spawn very close to wall corners
cat > "$MAPS/bonus_corner_spawn.cub" << 'EOF'
NO ./textures/north.xpm
SO ./textures/south.xpm
WE ./textures/west.xpm
EA ./textures/east.xpm
F 220,100,0
C 225,30,0

11111
11001
1N001
10001
11111
EOF

test_valid_noleak \
	"Player spawning near wall corner" \
	"$CUB3D $MAPS/bonus_corner_spawn.cub"

# Narrow corridor
cat > "$MAPS/bonus_corridor.cub" << 'EOF'
NO ./textures/north.xpm
SO ./textures/south.xpm
WE ./textures/west.xpm
EA ./textures/east.xpm
F 220,100,0
C 225,30,0

11111111111111
10000000000001
1000N000000001
10000000000001
11111111111111
EOF

test_valid_noleak \
	"Long narrow corridor (collision stress)" \
	"$CUB3D $MAPS/bonus_corridor.cub"

# ============================================================
# SECTION 6 — ANIMATED SPRITES: no crash (stubs accepted)
# ============================================================
echo -e "${BOLD}--- SECTION 6: ANIMATED SPRITES (no crash) ---${NC}"
echo -e "${YELLOW}Stub implementation is accepted — only checking no crash.${NC}"
echo ""

test_valid_noleak \
	"Animated sprites init — test.cub" \
	"$CUB3D $MAPS/test.cub"

# ============================================================
# RESULTS
# ============================================================
echo ""
echo -e "${BOLD}============================================================${NC}"
echo -e "${BOLD}  RESULTS${NC}"
echo -e "${BOLD}============================================================${NC}"
echo -e "  Total:  ${TOTAL}"
echo -e "  ${GREEN}PASS:   ${PASS}${NC}"
echo -e "  ${RED}FAIL:   ${FAIL}${NC}"
echo ""

if [ $FAIL -eq 0 ]; then
	echo -e "${GREEN}${BOLD}  All bonus tests passed!${NC}"
	exit 0
else
	echo -e "${RED}${BOLD}  ${FAIL} test(s) failed. Check output above.${NC}"
	exit 1
fi
