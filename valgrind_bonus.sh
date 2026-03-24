#!/bin/bash
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
VOPT="valgrind --leak-check=full --show-leak-kinds=all --track-origins=yes --error-exitcode=42 -q"

test_valid_noleak()
{
	local desc="$1"
	local cmd="$2"
	TOTAL=$((TOTAL + 1))
	echo -e "${CYAN}[TEST $TOTAL]${NC} ${BOLD}${desc}${NC}"
	echo "  CMD: $cmd"
	OUTPUT=$(timeout 10s env -i HOME="$HOME" PATH="$PATH" $VOPT $cmd 2>&1)
	EXIT_CODE=$?
	if [ $EXIT_CODE -eq 124 ]; then
		echo -e "  ${YELLOW}TIMEOUT — try: DISPLAY= $cmd${NC}"
		FAIL=$((FAIL + 1))
		echo ""
		return
	fi
	if echo "$OUTPUT" | grep -qi "segmentation\|double free\|invalid read\|invalid write"; then
		echo -e "  ${RED}CRASH detected${NC}"
		echo "$OUTPUT" | grep -i "segmentation\|double free\|invalid"
		FAIL=$((FAIL + 1))
		echo ""
		return
	fi
	VALGRIND_ERROR=0
	if echo "$OUTPUT" | grep -q "ERROR SUMMARY: [^0]"; then VALGRIND_ERROR=1; fi
	if [ $EXIT_CODE -eq 42 ]; then VALGRIND_ERROR=1; fi
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

test_error()
{
	local desc="$1"
	local cmd="$2"
	local expect_msg="$3"
	TOTAL=$((TOTAL + 1))
	echo -e "${CYAN}[TEST $TOTAL]${NC} ${BOLD}${desc}${NC}"
	echo "  CMD: $cmd"
	OUTPUT=$(timeout 10s $VOPT $cmd 2>&1)
	EXIT_CODE=$?
	if [ $EXIT_CODE -eq 124 ]; then
		echo -e "  ${RED}TIMEOUT${NC}"
		FAIL=$((FAIL + 1))
		echo ""
		return
	fi
	VALGRIND_ERROR=0
	if echo "$OUTPUT" | grep -q "ERROR SUMMARY: [^0]"; then VALGRIND_ERROR=1; fi
	if [ $EXIT_CODE -eq 42 ]; then VALGRIND_ERROR=1; fi
	HAS_ERROR_MSG=0
	if echo "$OUTPUT" | grep -q "^Error"; then HAS_ERROR_MSG=1; fi
	local ok=1
	if [ $VALGRIND_ERROR -eq 1 ]; then echo -e "  ${RED}LEAK/MEMORY ERROR${NC}"; ok=0; fi
	if [ $HAS_ERROR_MSG -eq 0 ]; then echo -e "  ${RED}Missing 'Error' on stderr${NC}"; ok=0; fi
	if [ $EXIT_CODE -eq 0 ]; then echo -e "  ${RED}Exit code 0 — should have failed${NC}"; ok=0; fi
	if [ -n "$expect_msg" ]; then
		if ! echo "$OUTPUT" | grep -qi "$expect_msg"; then
			echo -e "  ${YELLOW}WARN: '$expect_msg' not found${NC}"
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

setup_bonus_maps()
{
	local dir="$1"
	cat > "$dir/bonus_doors.cub" << 'MAPEOF'
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
MAPEOF
	cat > "$dir/bonus_doors_multi.cub" << 'MAPEOF'
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
MAPEOF
	cat > "$dir/bonus_door_adjacent.cub" << 'MAPEOF'
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
MAPEOF
	cat > "$dir/bonus_spawn_e.cub" << 'MAPEOF'
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
MAPEOF
	cat > "$dir/bonus_spawn_s.cub" << 'MAPEOF'
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
MAPEOF
	cat > "$dir/bonus_spawn_w.cub" << 'MAPEOF'
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
MAPEOF
	cat > "$dir/bonus_door_open.cub" << 'MAPEOF'
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
MAPEOF
	cat > "$dir/bonus_large.cub" << 'MAPEOF'
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
MAPEOF
	cat > "$dir/bonus_corner_spawn.cub" << 'MAPEOF'
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
MAPEOF
	cat > "$dir/bonus_corridor.cub" << 'MAPEOF'
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
MAPEOF
}

echo ""
echo -e "${BOLD}============================================================${NC}"
echo -e "${BOLD}  VALGRIND SUITE — CUB3D BONUS — $(date)${NC}"
echo -e "${BOLD}  Binary: $CUB3D | Maps: $MAPS${NC}"
echo -e "${BOLD}============================================================${NC}"
echo ""
if [ ! -f "$CUB3D" ]; then echo -e "${RED}ERROR: binary not found. Run make bonus first.${NC}"; exit 1; fi
if [ ! -d "$MAPS" ]; then echo -e "${RED}ERROR: maps dir not found.${NC}"; exit 1; fi
echo -e "${YELLOW}Setting up bonus test maps...${NC}"
setup_bonus_maps "$MAPS"
echo ""
echo -e "${BOLD}--- SECTION 1: DOORS (parsing + no leak) ---${NC}"; echo ""
test_valid_noleak "Map with one door ('2')" "$CUB3D $MAPS/bonus_doors.cub"
test_valid_noleak "Map with multiple doors" "$CUB3D $MAPS/bonus_doors_multi.cub"
test_valid_noleak "Door adjacent to spawn" "$CUB3D $MAPS/bonus_door_adjacent.cub"
test_valid_noleak "Door with spawn E" "$CUB3D $MAPS/bonus_spawn_e.cub"
test_valid_noleak "Door with spawn S" "$CUB3D $MAPS/bonus_spawn_s.cub"
test_valid_noleak "Door with spawn W" "$CUB3D $MAPS/bonus_spawn_w.cub"
echo -e "${BOLD}--- SECTION 2: DOORS (invalid) ---${NC}"; echo ""
test_error "Door '2' on map border (open map)" "$CUB3D $MAPS/bonus_door_open.cub" ""
echo -e "${BOLD}--- SECTION 3: MINIMAP STRESS ---${NC}"; echo ""
test_valid_noleak "Large map 11x19" "$CUB3D $MAPS/bonus_large.cub"
echo -e "${BOLD}--- SECTION 4: VALID MAPS WITH BONUS BINARY ---${NC}"; echo ""
for map in test valid_map valid_map2 valid_map3 valid_map4 valid_map5; do
	if [ -f "$MAPS/${map}.cub" ]; then
		test_valid_noleak "${map}.cub with bonus binary" "$CUB3D $MAPS/${map}.cub"
	fi
done
echo -e "${BOLD}--- SECTION 5: WALL COLLISION MAPS ---${NC}"; echo ""
test_valid_noleak "Spawn near wall corner" "$CUB3D $MAPS/bonus_corner_spawn.cub"
test_valid_noleak "Long narrow corridor" "$CUB3D $MAPS/bonus_corridor.cub"
echo -e "${BOLD}--- SECTION 6: ANIMATED SPRITES (no crash) ---${NC}"; echo ""
test_valid_noleak "Animated sprites init — test.cub" "$CUB3D $MAPS/test.cub"
echo ""
echo -e "${BOLD}============================================================${NC}"
echo -e "  Total: ${TOTAL}  ${GREEN}PASS: ${PASS}${NC}  ${RED}FAIL: ${FAIL}${NC}"
echo -e "${BOLD}============================================================${NC}"
if [ $FAIL -eq 0 ]; then echo -e "${GREEN}${BOLD}  All bonus tests passed!${NC}"; exit 0
else echo -e "${RED}${BOLD}  ${FAIL} test(s) failed.${NC}"; exit 1; fi