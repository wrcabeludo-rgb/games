#!/usr/bin/env bash
# Скачивает бесплатную музыку и звуки (все — CC0, см. docs/AUDIO.md) и кладёт в game/audio/
# в формате Ogg Vorbis. Свист ударов синтезируется здесь же из шума (ffmpeg).
# Использование: tools/fetch_audio.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/game/audio"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$OUT/music" "$OUT/sfx" "$OUT/voice"

kenney() {  # kenney <ассет> — скачать и распаковать пак Kenney
	local url
	url="$(curl -sS "https://kenney.nl/assets/$1" | grep -o 'https://kenney.nl/media/pages/assets/[^"]*\.zip' | head -1)"
	mkdir -p "$TMP/$1"
	curl -sSL -o "$TMP/$1.zip" "$url"
	(cd "$TMP/$1" && unzip -q -o "../$1.zip")
}
ogg() {  # ogg <вход> <выход> [фильтр] — в Ogg Vorbis, моно для звуков
	ffmpeg -v error -y -i "$1" ${3:+-af "$3"} -ac "${CH:-1}" -ar 44100 -c:a libvorbis -q:a "${Q:-5}" "$2"
}

# --- Звуки Kenney (CC0) ---
kenney impact-sounds
kenney interface-sounds
kenney rpg-audio
kenney voiceover-pack-fighter
A="$TMP/impact-sounds/Audio"
for i in 0 1 2 3 4; do
	ogg "$A/impactPunch_medium_00$i.ogg" "$OUT/sfx/hit_light_$i.ogg"
	ogg "$A/impactPunch_heavy_00$i.ogg" "$OUT/sfx/hit_heavy_$i.ogg"
	ogg "$A/impactPlate_light_00$i.ogg" "$OUT/sfx/block_$i.ogg" "volume=0.7"
	ogg "$A/impactSoft_heavy_00$i.ogg" "$OUT/sfx/fall_$i.ogg"
	ogg "$A/footstep_grass_00$i.ogg" "$OUT/sfx/land_$i.ogg"
done
ogg "$A/impactBell_heavy_000.ogg" "$OUT/sfx/parry.ogg" "volume=0.6"
ogg "$A/impactMetal_heavy_000.ogg" "$OUT/sfx/super.ogg"
R="$TMP/rpg-audio/Audio"
ogg "$R/knifeSlice.ogg" "$OUT/sfx/slash_0.ogg"
ogg "$R/knifeSlice2.ogg" "$OUT/sfx/slash_1.ogg"
ogg "$R/cloth1.ogg" "$OUT/sfx/cape_0.ogg"
ogg "$R/cloth3.ogg" "$OUT/sfx/cape_1.ogg"
U="$TMP/interface-sounds/Audio"
ogg "$U/select_002.ogg" "$OUT/sfx/ui_move.ogg"
ogg "$U/confirmation_002.ogg" "$OUT/sfx/ui_confirm.ogg"
ogg "$U/back_002.ogg" "$OUT/sfx/ui_back.ogg"
V="$TMP/voiceover-pack-fighter/Audio"
for v in round_1 round_2 round_3 final_round fight winner you_win you_lose time tie \
		choose_your_character player_1 player_2 prepare_yourself flawless_victory; do
	ogg "$V/$v.ogg" "$OUT/voice/$v.ogg"
done

# --- Свист удара: розовый шум, полосовой фильтр, нарастание и спад ---
CH=1 ffmpeg -v error -y -f lavfi -i "anoisesrc=d=0.22:c=pink:a=0.5:r=44100" \
	-af "highpass=f=900,lowpass=f=5000,afade=t=in:d=0.06,afade=t=out:st=0.07:d=0.15,volume=0.8" \
	-c:a libvorbis -q:a 5 "$OUT/sfx/whoosh_light.ogg"
CH=1 ffmpeg -v error -y -f lavfi -i "anoisesrc=d=0.4:c=brown:a=0.7:r=44100" \
	-af "highpass=f=150,lowpass=f=1800,afade=t=in:d=0.12,afade=t=out:st=0.14:d=0.26,volume=1.6" \
	-c:a libvorbis -q:a 5 "$OUT/sfx/whoosh_heavy.ogg"

# --- Музыка с OpenGameArt (CC0), стерео ---
OGA=https://opengameart.org/sites/default/files
curl -sSL -o "$TMP/menu.wav" "$OGA/determined_pursuit_loop.wav"
curl -sSL -o "$TMP/boss2.zip" "$OGA/boss_battle_%232_metal_pack.zip"
curl -sSL -o "$TMP/battleA.mp3" "$OGA/battleThemeA.mp3"
(cd "$TMP" && unzip -q -o boss2.zip)
CH=2 Q=4 ogg "$TMP/menu.wav" "$OUT/music/menu.ogg"
# Вступление + петля одним файлом; повтор — с начала петли (loop_offset в .import).
ffmpeg -v error -y -i "$TMP/boss_battle_#2_metal_opening.wav" -i "$TMP/boss_battle_#2_metal_loop.wav" \
	-filter_complex "[0:a][1:a]concat=n=2:v=0:a=1" -ac 2 -ar 44100 -c:a libvorbis -q:a 4 "$OUT/music/fight_1.ogg"
CH=2 Q=4 ogg "$TMP/battleA.mp3" "$OUT/music/fight_2.ogg"
echo "Готово: $OUT"
