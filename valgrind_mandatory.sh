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
	if echo "$OUTPUT" | grep -q "ERROR SUMMARY: [^0]"; then VALGRIND_ERROR=1; fi
	if [ $EXIT_CODE -eq 42 ]; then VALGRIND_ERROR=1; fi
	HAS_ERROR_MSG=0
	if echo "$OUTPUT" | grep -q "^Error"; then HAS_ERROR_MSG=1; fi
	PROGRAM_FAILED=0
	if [ $EXIT_CODE -ne 0 ] && [ $EXIT_CODE -ne 42 ]; then PROGRAM_FAILED=1; fi
	local ok=1
	if [ $VALGRIND_ERROR -eq 1 ]; then
		echo -e "  ${RED}LEAK/MEMORY ERROR${NC}"
		echo "$OUTPUT" | grep -A5 "ERROR SUMMARY"
		ok=0
	fi
	if [ $HAS_ERROR_MSG -eq 0 ]; then
		echo -e "  ${RED}Missing 'Error' on stderr${NC}"
		ok=0
	fi
	if [ $PROGRAM_FAILED -eq 0 ]; then
		echo -e "  ${RED}Exit code 0 — should have failed${NC}"
		ok=0
	fi
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
test_args()
{
	local desc="$1"
	local cmd="$2"
	TOTAL=$((TOTAL + 1))
	echo -e "${CYAN}[TEST $TOTAL]${NC} ${BOLD}${desc}${NC}"
	echo "  CMD: $cmd"
	OUTPUT=$(timeout 3s $VOPT $cmd 2>&1)
	EXIT_CODE=$?
	VALGRIND_ERROR=0
	if echo "$OUTPUT" | grep -q "ERROR SUMMARY: [^0]"; then VALGRIND_ERROR=1; fi
	if [ $EXIT_CODE -eq 42 ]; then VALGRIND_ERROR=1; fi
	local ok=1
	if [ $VALGRIND_ERROR -eq 1 ]; then echo -e "  ${RED}LEAK/MEMORY ERROR${NC}"; ok=0; fi
	if [ $EXIT_CODE -eq 0 ]; then echo -e "  ${RED}Exit code 0 — should have failed${NC}"; ok=0; fi
	if [ $ok -eq 1 ]; then
		echo -e "  ${GREEN}PASS${NC}"
		PASS=$((PASS + 1))
	else
		FAIL=$((FAIL + 1))
	fi
	echo ""
}
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
		echo -e "  ${YELLOW}TIMEOUT — normal if display available${NC}"
		PASS=$((PASS + 1))
		echo ""
		return
	fi
	if echo "$OUTPUT" | grep -qi "segmentation\|double free\|invalid read\|invalid write"; then
		echo -e "  ${RED}CRASH detected${NC}"
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
setup_test_maps()
{
	local dir="$1"
	touch "$dir/empty.cub"
	cp "$dir/test.cub" "$dir/wrong_extension.map" 2>/dev/null || echo "" > "$dir/wrong_extension.map"
	touch "$dir/.cub"
	cat > "$dir/duplicate_texture.cub" << 'MAPEOF'
NO ./textures/north.xpm
NO ./textures/north2.xpm
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
MAPEOF
	cat > "$dir/missing_texture.cub" << 'MAPEOF'
NO ./textures/north.xpm
SO ./textures/south.xpm
WE ./textures/west.xpm
EA ./textures/NONEXISTENT_9999.xpm
F 220,100,0
C 225,30,0

111111
100001
1N0001
100001
111111
MAPEOF
	cat > "$dir/invalid_texture2.cub" << 'MAPEOF'
NO ./textures/north.xpm
SO ./textures/south.xpm
WE no_extension
EA ./textures/east.xpm
F 220,100,0
C 225,30,0

111111
100001
1N0001
100001
111111
MAPEOF
	cat > "$dir/bad_color_floor.cub" << 'MAPEOF'
NO ./textures/north.xpm
SO ./textures/south.xpm
WE ./textures/west.xpm
EA ./textures/east.xpm
F 1,16
C 225,30,0

111111
100001
1N0001
100001
111111
MAPEOF
	cat > "$dir/bad_color_range.cub" << 'MAPEOF'
NO ./textures/north.xpm
SO ./textures/south.xpm
WE ./textures/west.xpm
EA ./textures/east.xpm
F 1,16,300
C 225,30,0

111111
100001
1N0001
100001
111111
MAPEOF
	cat > "$dir/color_rgb_invalid.cub" << 'MAPEOF'
NO ./textures/north.xpm
SO ./textures/south.xpm
WE ./textures/west.xpm
EA ./textures/east.xpm
F 20,20,-20
C 225,30,0

111111
100001
1N0001
100001
111111
MAPEOF
	cat > "$dir/no_floor_color.cub" << 'MAPEOF'
NO ./textures/north.xpm
SO ./textures/south.xpm
WE ./textures/west.xpm
EA ./textures/east.xpm
F 20,20
C 225,30,0

111111
100001
1N0001
100001
111111
MAPEOF
	cat > "$dir/no_ceiling_color.cub" << 'MAPEOF'
NO ./textures/north.xpm
SO ./textures/south.xpm
WE ./textures/west.xpm
EA ./textures/east.xpm
F 220,100,0
C 200,200,

111111
100001
1N0001
100001
111111
MAPEOF
	cat > "$dir/missing_ceiling.cub" << 'MAPEOF'
NO ./textures/north.xpm
SO ./textures/south.xpm
WE ./textures/west.xpm
EA ./textures/east.xpm
F 220,100,0

111111
100001
1N0001
100001
111111
MAPEOF
	cat > "$dir/no_player.cub" << 'MAPEOF'
NO ./textures/north.xpm
SO ./textures/south.xpm
WE ./textures/west.xpm
EA ./textures/east.xpm
F 220,100,0
C 225,30,0

111111
100001
100001
100001
111111
MAPEOF
	cat > "$dir/open_map.cub" << 'MAPEOF'
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
11011
MAPEOF
	cat > "$dir/invalid_char.cub" << 'MAPEOF'
NO ./textures/north.xpm
SO ./textures/south.xpm
WE ./textures/west.xpm
EA ./textures/east.xpm
F 220,100,0
C 225,30,0

111111
1X0001
1N0001
100001
111111
MAPEOF
	cat > "$dir/multiple_player.cub" << 'MAPEOF'
NO ./textures/north.xpm
SO ./textures/south.xpm
WE ./textures/west.xpm
EA ./textures/east.xpm
F 220,100,0
C 225,30,0

111111
1S0001
1N0001
100001
111111
MAPEOF
	cat > "$dir/small_map.cub" << 'MAPEOF'
NO ./textures/north.xpm
SO ./textures/south.xpm
WE ./textures/west.xpm
EA ./textures/east.xpm
F 220,100,0
C 225,30,0

111
101
111
MAPEOF
}
echo ""
echo -e "${BOLD}============================================================${NC}"
echo -e "${BOLD}  VALGRIND SUITE — CUB3D MANDATORY — $(date)${NC}"
echo -e "${BOLD}  Binary: $CUB3D | Maps: $MAPS${NC}"
echo -e "${BOLD}============================================================${NC}"
echo ""
if [ ! -f "$CUB3D" ]; then echo -e "${RED}ERROR: binary not found.${NC}"; exit 1; fi
if [ ! -d "$MAPS" ]; then echo -e "${RED}ERROR: maps dir not found.${NC}"; exit 1; fi
echo -e "${YELLOW}Setting up test maps...${NC}"
setup_test_maps "$MAPS"
echo ""
echo -e "${BOLD}--- SECTION 1: ARGUMENTS ---${NC}"; echo ""
test_args "No arguments" "$CUB3D"
test_args "Too many arguments" "$CUB3D $MAPS/test.cub extra_arg"
test_error "Wrong extension (.map)" "$CUB3D $MAPS/wrong_extension.map" "extension"
test_error "Non-existent file" "$CUB3D $MAPS/nonexistent_9999.cub" ""
test_error "Empty file" "$CUB3D $MAPS/empty.cub" ""
test_error "Only extension as name (.cub)" "$CUB3D $MAPS/.cub" ""
echo -e "${BOLD}--- SECTION 2: TEXTURES ---${NC}"; echo ""
test_error "Duplicate texture (NO repeated)" "$CUB3D $MAPS/duplicate_texture.cub" "Duplicate"
test_error "Non-existent texture path" "$CUB3D $MAPS/missing_texture.cub" ""
test_error "Texture without .xpm" "$CUB3D $MAPS/invalid_texture2.cub" ""
echo -e "${BOLD}--- SECTION 3: COLORS ---${NC}"; echo ""
test_error "Floor 2 components (F 1,16)" "$CUB3D $MAPS/bad_color_floor.cub" "color"
test_error "Floor out of range (F 1,16,300)" "$CUB3D $MAPS/bad_color_range.cub" "color"
test_error "Floor negative (F 20,20,-20)" "$CUB3D $MAPS/color_rgb_invalid.cub" "color"
test_error "Floor 2 components v2 (F 20,20)" "$CUB3D $MAPS/no_floor_color.cub" "color"
test_error "Ceiling trailing comma (C 200,200,)" "$CUB3D $MAPS/no_ceiling_color.cub" "color"
test_error "Missing ceiling" "$CUB3D $MAPS/missing_ceiling.cub" ""
echo -e "${BOLD}--- SECTION 4: MAP VALIDATION ---${NC}"; echo ""
test_error "No player" "$CUB3D $MAPS/no_player.cub" "player"
test_error "Open map (11011)" "$CUB3D $MAPS/open_map.cub" "closed"
test_error "Invalid char (X)" "$CUB3D $MAPS/invalid_char.cub" ""
test_error "Multiple players (S and N)" "$CUB3D $MAPS/multiple_player.cub" ""
test_error "Small map no player" "$CUB3D $MAPS/small_map.cub" ""
echo -e "${BOLD}--- SECTION 5: EDGE CASES ---${NC}"; echo ""
test_args "Path to directory" "$CUB3D $MAPS/"
echo -e "${BOLD}--- SECTION 6: VALID MAPS (leak check) ---${NC}"; echo ""
for map in test valid_map valid_map2 valid_map3 valid_map4 valid_map5; do
	if [ -f "$MAPS/${map}.cub" ]; then
		test_valid_noleak "${map}.cub" "$CUB3D $MAPS/${map}.cub"
	fi
done
echo ""
echo -e "${BOLD}============================================================${NC}"
echo -e "  Total: ${TOTAL}  ${GREEN}PASS: ${PASS}${NC}  ${RED}FAIL: ${FAIL}${NC}"
echo -e "${BOLD}============================================================${NC}"
if [ $FAIL -eq 0 ]; then echo -e "${GREEN}${BOLD}  All tests passed!${NC}"; exit 0
else echo -e "${RED}${BOLD}  ${FAIL} test(s) failed.${NC}"; exit 1; fi