# Звук и музыка

Всё бесплатное, лицензия **CC0** (общественное достояние: можно в коммерческой игре, указывать автора
не обязательно, но мы указываем). Скачивает и конвертирует `tools/fetch_audio.sh` → `game/audio/`.
Играет `SoundDirector` (game/scripts/ui/sound_director.gd): он только читает состояние боя.

## Музыка (OpenGameArt)
| Файл | Где | Трек | Автор |
|---|---|---|---|
| music/menu.ogg | заставка, выбор бойца | [Determined Pursuit (epic orchestra loop)](https://opengameart.org/content/determined-pursuit-epic-orchestra-loop) | Emma_MA |
| music/fight_1.ogg | бой (нечётные матчи) | [Boss Battle #2 (Symphonic Metal)](https://opengameart.org/content/boss-battle-2-symphonic-metal) — вступление + петля | nene |
| music/fight_2.ogg | бой (чётные матчи) | [Battle Theme A](https://opengameart.org/content/battle-theme-a) | cynicmusic |

## Звуки (Kenney, kenney.nl)
| Файлы | Событие | Пак |
|---|---|---|
| sfx/hit_light_*, hit_heavy_* | попадание лёгким / сильным | [Impact Sounds](https://kenney.nl/assets/impact-sounds) (impactPunch) |
| sfx/block_* | удар в блок | Impact Sounds (impactPlate) |
| sfx/parry | парирование, контратака | Impact Sounds (impactBell) |
| sfx/super | суперприём | Impact Sounds (impactMetal) |
| sfx/fall_*, land_* | падение, приземление | Impact Sounds (impactSoft, footstep_grass) |
| sfx/slash_*, cape_* | когти Дракулы, взмах плаща | [RPG Audio](https://kenney.nl/assets/rpg-audio) |
| sfx/ui_* | меню | [Interface Sounds](https://kenney.nl/assets/interface-sounds) |
| voice/* | диктор: «Round 1», «Fight!», «Time», «Winner», «Choose your character» | [Voiceover Pack: Fighter](https://kenney.nl/assets/voiceover-pack-fighter) |
| sfx/whoosh_light, whoosh_heavy | свист удара | синтезирован из шума (tools/fetch_audio.sh) |
| sfx/<боец>_<удар> (ilya_st_lp) | свой звук удара бойца вместо свиста | вырезан из видео Veo (ffmpeg, см. CLAUDE.md) |

Громкость — константы в начале `sound_director.gd` (MUSIC_DB, SFX_DB, VOICE_DB).
Позже: свои фразы героев (Илья, Дракула) — можно записать голосом или подобрать.

## Шрифты (game/fonts/, лицензия SIL Open Font License — бесплатно, в том числе в коммерческой игре)
| Файл | Где | Авторы |
|---|---|---|
| RuslanDisplay-Regular.ttf | заголовки: «БИТВА ЛЕГЕНД», «РАУНД», «НОКАУТ», имена бойцов, «ПАУЗА» | Oleg Snarsky, Denis Masharov, Vladimir Rabdu |
| RussoOne-Regular.ttf | цифры и надписи интерфейса | Jovanny Lemonad |

Тексты лицензий — рядом со шрифтами (OFL-*.txt).
