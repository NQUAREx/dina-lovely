# Восстановленный контекст — 14 ноября 2026

## Где работать

- Корень репозитория: `/root/love-in-bloom`.
- GitHub: https://github.com/NQUAREx/dina-lovely
- Публикация: https://nquarex.github.io/dina-lovely/
- `/root/Documents/Codex/2026-11-15/love-in-bloom` при проверке была пустой папкой, не репозиторием.
- В Godot открывать `project.godot`. Перед изменениями читать `AGENTS.md`.

## Что это

«Сад» / Love in Bloom / dina-lovely — мобильное пиксельное приключение с романтическими записками и финальной открыткой. Семь комнат: лабиринт, темнота с фонарём, препятствия, раскопки, бой, сад, финал. Есть загадка с камешками и подсказками, сбор ресурсов и изготовление инструментов, аксессуары, кот и сохранение прогресса. Управление сенсорное, портретный экран 540×960.

Godot 4.7.2, GDScript, Compatibility renderer. Статический Web/WASM экспорт, без игрового сервера; GitHub Pages публикует `/docs`. Сохранения — `user://garden_save_v1.json`, в браузере локальное постоянное хранилище.

## Карта кода

- `main.tscn` → `scripts/game.gd`: главный Node2D, около 4000 строк; состояние игры, комнаты, ввод, интерфейс и отрисовка. Клетка мира 48 px; комнаты кешируются.
- `scripts/hedge_field.gd`: изгородь и взаимодействие с листвой.
- `scripts/gate_junctions.gd`: стыки стен и ворот, опорные клетки и отрисовка столбов.
- `scripts/battle_director.gd`, `weapon_crates.gd`, `arena_checkpoint.gd`: бой и арена.
- `scripts/dig_quest.gd`, `world_tools.gd`, `note_flowers.gd`: ресурсы, изготовление инструментов, раскопки, цветы с записками.
- `scripts/riddle_stones.gd`, `letter_*.gd`, `cat_companion.gd`: загадка, записки, кот.
- `assets/`: пиксельные ресурсы; `tools/create_*.py`: их генераторы.
- `tools/mobile_shell.js`, `finalize_web.py`, `asset_loader.js`: браузерная оболочка и доставка сборки.
- `tests/`: Godot-регрессии, Python-проверки ресурсов/контента, браузерные проверки. `tests/RESULTS.md` содержит исторические результаты, а не подтверждение текущей версии.
- `docs/`: результат экспорта; изменения исходников автоматически туда не попадают.

## На чём остановились

При восстановлении `main` и `origin/main` совпадали, HEAD `53dc2d8` (2026-11-14): непрерывная кладка, полноразмерные столбы ворот, тень изгороди. Последние коммиты многократно меняли и откатывали варианты стен и ворот; считать финальный визуальный вариант утверждённым нельзя.

В рабочей копии сохранены незакоммиченные изменения:

- `tools/create_wall_art.py`: новая геометрия кладки и четыре варианта текстур.
- `tools/create_gate_junctions.py`: новая геометрия и декор столбов.
- `scripts/game.gd`: выбор варианта кладки по клетке, высота текстуры 128 вместо 96, контактные боковые тени.
- 18 изменённых PNG стен/стыков; 6 новых PNG вариантов стен и 6 соответствующих `.import`.

При первоначальном восстановлении эти правки не были закоммичены, а `docs/` ещё не была пересобрана. Затем пользователь явно поручил собрать и полностью опубликовать локальную версию на GitHub Pages; публикация включает эти исходники и обновлённую сборку. Следующий логичный шаг — посмотреть текущие стены/ворота в игре и уточнить желаемый вид. Точное намерение последнего запроса по одному diff восстановить нельзя.

## Правила контента

`content/letters.json` и `letters.backup.json` управляются на GitHub. Облачные значения приоритетны. Перед работой с контентом запускать `python3 tools/sync_letters.py`. Не перезаписывать личные тексты локальными версиями. Runtime UI-тексты хранятся в обеих JSON-версиях. Особый порядок изменения схемы описан в `AGENTS.md`.

При восстановлении выполнено `python3 tools/sync_letters.py --setup`: включены `.githooks` и skip-worktree для JSON. Сами тексты не менялись. Web-оболочка получает выбранную версию JSON с GitHub при запуске.

## Проверка и запуск

```bash
cd /root/love-in-bloom
./tools/godot.sh --editor
python3 tests/content_schema.py
./tools/godot.sh --headless --script tests/gate_hand_projectiles.gd
```

При восстановлении версия Godot подтвердилась; обе указанные проверки прошли. Вторая проверяет опоры/коллизии ворот, точку выпадения предметов, снаряды у краёв арены и хваты в восьми направлениях. Это не визуальная проверка новых стен и не полное прохождение. Реальные iPhone/Android в этом сеансе не тестировались.

Экспорт после изменений кода/графики:

```bash
./tools/godot.sh --headless --editor --import
./tools/godot.sh --headless --export-release Web docs/index.html
python3 tools/finalize_web.py
python3 tools/serve.py
```

Локальная сборка: http://127.0.0.1:8766/love-in-bloom/docs/ . После экспорта обязательно выполнять finalize_web.py. Публикацию делать отдельным осознанным действием.

## Ограничения анализа

Контекст восстановлен из файлов, Git-истории и рабочего diff; предыдущая переписка недоступна. Главный технический риск сопровождения — большой `game.gd` с тесно связанными состоянием и отрисовкой. Изменения графики нужно проверять вместе с коллизиями, слоями перекрытия героини и переходами между комнатами.

## Публикация после восстановления

GitHub API подтвердил Pages: источник `main`, путь `/docs`, тип `legacy`. Экспорт игры выполняется локально; GitHub Pages собирает и размещает статический сайт. Перед экспортом обе JSON-версии синхронизированы с GitHub. В окружении отсутствовали export templates; для сборки загружены официальные шаблоны 4.7.2. Отдельная проверка `tests/forest_gate_art.py` прошла. `tests/outfit_art.py` падает на проверке отверстия в вуали (строка 37), при этом атлас совпадает с предыдущим HEAD: это существующее ограничение, не новая правка кладки.

## Рабочие скриншоты в proot

См. `tools/qa/README.md`. Нативный Godot и Firefox WebGL2 успешно снимают реальную игру с `GALLIUM_DRIVER=softpipe LIBGL_ALWAYS_SOFTWARE=1 LP_NUM_THREADS=1` под Xvfb. Нельзя делать вывод о невозможности preview по предыдущим падениям llvmpipe: они устранены этой конфигурацией. Команды: `./tools/qa/native_capture.sh`, `./tools/qa/firefox_capture.sh`. Playwright Chromium работает для стартовой оболочки, полный WebGL runtime пока проверять Firefox. Среда Selenium установлена постоянно в `/root/.local/share/love-bloom-qa/venv`, Playwright — рядом в `node_modules`.

## Публикация приостановлена пользователем

Пользователь явно запретил выкладывать новые изменения до его одобрения результата (после коммита2536e9d). Готовить локальные правки и скриншоты; не push/не публиковать, пока пользователь явно не одобрит. Текущая локальная переработка возвращает форму колонны из f878719 и использует только внутренние ряды кладки стены, без повторения кромок/цоколей блоков.

## Текущая локальная колонна: ожидает визуального одобрения

После последнего отказа переработан tools/create_gate_junctions.py: отдельная форма с верхней/нижней окантовкой и непрерывным стволом; используются пиксели внутренней кладки wall_exposed, без повторяющихся крыш и нижних кромок блоков. Важно: стены в game.gd выводят крышу 2x, боковую грань 2x по X и 1.2x по Y. Колонна теперь запекается в 96x224 (фактический экранный размер), чтобы сохранить тот же шаг кладки 8/9 экранных пикселей; прежний перенос без сжатия давал неверную перспективу. Свет обеих колонн одинаково направлен, правую не зеркалить. Реальный локальный рендер: /tmp/bloom-material-gate.png. docs не пересобирались, публикация по-прежнему запрещена до явного одобрения.

Локальные уточнения: колонны зеркальные, плющ спиралью в палитре кустов, цоколь расширен только внутрь прохода. Петли рисуются поверх створок через draw_hinges на высотах -54/-13 относительно ворот. PointLight2D использует короткую направленную вниз текстуру 96px без верхней засветки, энергия .32/.055, тёмный shader имеет такое же ограничение вниз. Публикация по-прежнему запрещена.

Последнее локальное уточнение: крепёж на створках укорочен до9px (4px у открытой); плющ возвращён к прежней узкой внешней форме, цвета из травы (56,83,73)/(76,104,89)/(102,127,105), цветочки напрямую из grass_clumps. Внутренний цоколь теперь явно продолжается от x70 до84 и имеет верхнюю, переднюю и боковую грани; наружную сторону не расширять.

Исправление геометрии цоколя после повторного замечания: убрать вылет x84; внутренняя полоса теперь идёт вдоль глубины колонны x70..76,y138..188, с верхним уступом и боковой гранью. Фонарь перерисован на16x18 и увеличен nearest2x; широкая верхняя крышка, укороченная передняя грань, только крупная пиксельная сетка.

Плющ снова переработан по замечанию о наложенной ленте: стебли изогнуты и ветвятся на передней грани, короткие корешки привязаны к швам, на фаске листья сжаты и темнее. Контактная тень полупрозрачно затемняет исходный камень, слой обрезан силуэтом колонны, фонарь отрисован перед растением. Листья на общей сетке2px, сохранены трава-палитра и цветочки газона. Только локально; публикации нет.

## Новое правило публикации и текущие исправления
Пользователь отменил запрет: отныне после завершения задачи автоматически собирать и публиковать на Pages. Эксперимент теней74d3eda отменён git revert c6c4d2e. Исправлен grip face5 (NE) на ближнюю правую перчатку и слой руки; общая точка используется всеми10 инструментами и оружием. Отдельный генератор create_open_gate.py сохраняет перспективную открытую створку при регенерации атласа. Culling doorway использует полный Rect2(-144,-160,288,224). create_room_walls.py генерирует7 семейств wall_roomN, каждый с4 вариантами и exposed/stacked; верхние5 рядов коридора используют предыдущее семейство, остальной уровень и нижний коридор — текущее.

## Материалы ограждений, звуки и непрерывность коридоров (2026-11-16)
Пользователь уточнил: ограждения различаются принципом, не цветом. wall_room0 кусты,1 густые деревья,3 земляные насыпи,5 кубический садовый забор;2/4/6 исходная кладка. HedgeField оставлен только в0; остальные # теперь рисуют тематическую границу. Corridor owner исправлен по реальной ориентации уровней: северный коридор level+1, южный level, т.е. всегда физически верхняя комната. В коридорах вариант зависит только от x (исключает смену узора от разных локальных y), краевая тень рисуется на полу как внутри grid, так и в extensions; прежняя дублирующая контактная тень стен пропущена в corridor rows. tests/material_boundaries.gd проверяет обе стороны всех6 переходов и7 trunk-масок.
Большое quest_tree использует отдельные *_trunk.png маски древесины; крона и ground shadow исключены, все стадии повреждений сохранены. Генератор tools/create_quest_trunk_mask.py. Звуки кирки/топора/крафта собраны из существующих CC0 foley, лицензия и оригиналы сохранены; громкость chop/axe -10dB, pick/craft -12dB. Визуально проверены /tmp/material-room-{1,3,5}.png. Правило автоматической публикации остаётся в силе.

## Исправления границ и боевого ИИ (2026-11-16)
AI замерзал на полосах у северной/южной стены из-за inside_main_room() в _process. Теперь gating использует battle.player_in_arena(), учитывающий весь доступный пол арены. tests/combat_wall_pursuit.gd проверяет настоящий _process у обеих стен/4углов, движение преследования и сохранение LOS за реальными препятствиями. Старый combat_balance.gd по-прежнему несовместим с pending_spawns (строка9), это отдельное старое ограничение.
wall_room1 и3 теперь имеют16 разных силуэтов; seed+x/y выбирают вариант и малое смещение±3x±2y, в коридорах только x для непрерывности между комнатами. Темнее evergreen1, насыпи3 в палитре выкопанной почвы, сад5 деревянный кубический забор. Геометрия коллизий неизменна. Открытая створка сильнее повёрнута, свободный край дальше в глубине. В iron_weapon_crates все8 поз крышек удерживают внутренние края на петлях, убраны щели. Проверены нативные кадры /tmp/revised-room-{1,3,4,5}.png.

## Загрузчик iOS, слитная насыпь и реальная проверка коридора
CSS transform загрузчика зависел от WebKit при синхронном старте WASM. Теперь muted playsinline baseline H264 loop стартует до engine; ожидается воспроизведение/первый кадр, CSS запасной вариант. tools/qa/loading_video.cjs проверил смену7 кадров при блокировке JS. Реального iOS-теста нет, не утверждать обратное.
Насыпь3 теперь scripts/earth_boundary.gd: объединённое поле высот, непрерывный фундамент всех wall cells, протяжённые полки/пики, склоны/страты/камни, baked once cache. Вызывается после ground перед объектами; старые wall3main stamps пропущены. Коллизии сохранены.
Две старые линии открытой створки имели координаты10,17 и10,37, исправлены16,12/16,32.
Коридорный layout теперь canonical row (юг upper minus height ==север lower), x относительно центра15лабиринт/13остальные, одинаковые варианты зеркально справа. Также Vector2i(world/TILE) округлял отрицательный y к нулю: исправлено на floori обеих координат. Это и было оставшейся сменой рядов. Скрины /tmp/corridor-before-midpoint.png и /tmp/corridor-after-midpoint.png сравнены:0 несовпадений силуэтов зелени в обоих боковых сегментах y260..640. /tmp/gate-no-old-rails.png и /tmp/revised-room-3.png проверены визуально.

## Уточнения загрузчика, створки, насыпи и кнопки сброса
Видео загрузчика на iOS тормозило/пропадало и имело непрозрачную подложку. Заменено на прозрачный native GIF8кадров с общей палитрой/disposal2, без video/CSS strip/круглого фона. QA loading_animation.cjs:38 compositor frames,8distinct при3s заблокированногоJS. Реального iPhone не было — не заявлять проверку на устройстве.
Открытая створка теперь отдельный40x56 open_gate_leaf.png с прозрачным запасом; full-image render сохраняет y12угол, который срезался старым atlas region y16..48.
Насыпь3 переделана из smooth height relief в маленькие пиксельные горки: ограниченная тёмная soil palette, редкие светлые, грубые плоскости/галька. По новому уточнению пользователя12горок на wall cell в3перекрывающихся рядах, плотное заполнение с неровным краем, максимум22sourcepx шириной на горку. Основание сплошное; коллизии не менялись. Кнопка сброса получила отдельные рамки normal/hover/pressed/disabled поверх icon-only override.

Дополнительное уточнение насыпи: после уплотнения пользователь попросил вернуть видимые крупные горки. Теперь12мелких clods(w6..9,h5..9)на cell +редкие высокие(w11..12,h17..22) и средние(w8..10,h11..15). Большие рисуются в переднем ряду, не скрываются мелкими. Ширина каждой<=1блок. Проверен обновлённый /tmp/revised-room-3.png, плотность сохранена.

Последнее уточнение: пользователь всё ещё видел избыток мелких горок. Их количество снижено12→3на cell, теперь2средние и~1крупная, плотность обеспечена их перекрытием. Проверен игровой кадр /tmp/revised-room-3.png, без ошибок импорта/рендера.

## Правый хват SE, референсный сундук/пень и уходящие в туман границы
Хват face7(SE) выбирает настоящую дальнюю правую кисть x8, а не ближнюю левую x24.5. face7 добавлен hand_is_behind; тест right_hand_diagonals проверяет10инструментов наNE/SE.
Оружейный сундук заново нарисован по первому референсу: высокие светлые боковые крышки, широкая тёмная полость и серая передняя панель с тёмной вставкой,8кадров/петли непрерывны.
create_reference_stump.py рисует широкую золотистую овальную спиленную поверхность/кольца/тёмную кору/корни. База quest_tree и6стадий повреждения согласованы с пнём, крону не менять; trunk masks обновлены. Генератор добавлен в create_assets.py.
Границы: shaders/boundary_depth.gdshader + scripts/boundary_depth.gd (unshaded ColorRect z100 подHUD CanvasLayer2). Union текущей и соседних комнат +общих коридоров, снаружи чёрный, внутрь мягкий fade120px с мелкой неоднородностью. boundary_backdrop.gd рисует2дальних затемнённых ряда тематических ограждений за периметром, чтобы не читать одиночную стену с прямоугольным концом. Все только визуально, коллизии прежние. Важное: fog currentdarkroom остаётся отдельным CanvasLayer1.

Уточнение пользователя по туману: переход был резким/слишком чёрным. Fade расширен120→200px, область растянута ещё на48px наружу, reveal^.78 ослабляет затемнение у края; цвет теперь(.008,.012,.020), почти чёрный холодный. Коридорная область расширена240→336 чтобы пол не тонул в тумане. Проверен /tmp/revised-room-3.png с мягким переходом.

Последнее требование: краевой туман никогда не затемняет проходимый пол/коридоры/стыки. boundary_depth теперь использует3кэшированных маски floor cells текущей/соседних комнат и2прямоугольника коридорного пола, обнуляет alpha на них. Fade только ограждения/внешнее пространство. Отдельная тьма комнаты1 тоже заходила в проход: draw_night_mask fade перенесён внутрь band, flashlightshader in_room ограничен внутренними границами, без max(room_opacity,in_room) на весь viewport. Сохраняет основную тёмную комнату и луч фонаря, убирает затемнение проходов.

Финальное уточнение видимой толщины: пользователь хочет1–1.5клетки ограждения. Room fog domain теперь только24px снаружи исходного room bounds (проходимый пол начинается на48pxвнутри, итого72px видимой полосы); коридор floor width144, fog domain288 =>72pxсбоку. Fade100px с тем же светлым reveal^.78, floor masks неизменны. Это заменяет прежнее расширение96px и fade200px. Маски пола и ограничение darkroom применены в той же сборке.

Финальная переработка по замечанию о резких масках/колоннах: boundary_depth заменён единым расстоянием до объединения видимых зон. Зоны — внутренний прямоугольник каждой комнаты, общий полкоридора и полные видимые boundingboxes колонн. Alpha smoothstep(0,72,distance)*.98 для всех, нет бинарной floor-mask/разного перехода в стыках. Пол и колонны distance0 =>alpha0, производная на границе0; дальше72px плавный fade. Цвет остаётся(.008,.012,.020). Старые маски удалены как источник резкого края. Проверены /tmp/corridor-before-midpoint.png /after и отсутствие shader errors.

Колонны поверх тумана: пользователь заметил угловые вырезы от их protected rectangles. Удалены pillar-зоны из boundary_depth, непрерывный fade только от комнат/проходов. Новый pillar_overlay.gd z101 рисует те же колонны текущей и соседних комнат поверх boundaryfog(z100), не изменяя его форму. Shader остаётся единым расстоянием до room/corridor floor. Проверен нативный коридор.

## Аудит внешних обрывов всех уровней
boundary_backdrop теперь подкладывает непрерывную тёмную основу материала под дальние ряды и продолжает наружные бока ВСЕХ коридоров rings3/4 за реальными wallcells, включая extensions. Ранее полупрозрачные края коридорных деревьев могли закончиться раньше fade72. В дальней зоне alpha тумана теперь1 (вместо.98), чтобы исходный фон не просвечивал; цвет остаётсяRGB(2,3,5).
Проверены28 нативных кадров всех4углов7уровней; контактные листы /tmp/edge-audit-nw-se.png /tmp/edge-audit-ne-sw.png. Внешние полосы во всех28кадрах строгоRGB(2,3,5); открытых обрывов на листах не найдено. Коридор0↔1 также переснят, tests/material_boundaries.gd проверяет6переходов; gate/projectile testPASS. Это аудитуглов и указанного коридора, не заявлениео проверке каждого возможного положения камеры.

## Шесть исправлений после скриншотов (следующий проход)
1) pillar_overlay теперь спрайты с shader alpha-occlusion по точному силуэту текущего героя/одежды, инструментов/оружия и передних врагов. Порядок сравнивается по исходному y-sort: спереди персонаж виден, сзади колонна его закрывает. Туман по-прежнему под колонной, никаких отверстий в форме fog.
2) Записки: letter_view применяет стартовую позу в_ready до первого draw и переводит viewport start в local coordinates; game.show_letter берёт item_display_position конверта, archive card по стабильному id, не по полному равенству dictionary. tests/letter_origin.gd PASS.
3) Casio: create_watch_wrist.py рисует40frames на анатомической левой кисти, учитывает occlusion телом на правом профиле; generator включён вcreate_assets. assets/atlas обновлён, просмотрен /tmp/watch-left-wrist.png.
4) Темнота комнаты1 теперь единые координаты origin дляlevel0/1/2: room_band/opacity/light sources вычисляются из darkroom даже когда активен сосед. Нет старой отдельной draw_night_mask соседней комнаты. Снова max(room_opacity,in_room): весь viewport плавно темнеет по мере входа, не только полоса внутри комнаты. Цвет темноты совпадает с boundaryfog RGB2/3/5. tests/dark_corridor_continuity.gd PASS opacity/band across same physical seam and deeper entrance.
5) release_at_gate(previous_foot) вphysics требует фактического пересечения наружу, а не стояния надпьедесталом с walk_facing down. tests/pickup_all_directions.gd PASS flashlight+9tools8sides and idle frames, outward crossingstilldrops.
6) Неколлизионные полосы были corridor extensions до24клеток, проходившие внутрь соседней комнаты. Ограничено5клетками (реальная половина общего коридора), backdrop extensions также[-5,height+5). Настоящие стеныroom4 затемнены*.65 по образцу этих полос, остальные комнатные стены прежние. Скрины /tmp/six-room-2.png /tmp/six-room-4.png проверены чистыми. /tmp/six-dark-before.png /after /enter проверены: нет скачка, весь экран темнеет при входе.

## 2026-11-16: larger controls and restored darkness feather
Action control248x88 with readable wrapped labels; drop/cycle80x80 and explicit framed states. Boundary fog opaque muted slate(.105,.112,.145), preserving72px fade. Restored exact pre-boundary6ad3171 symmetric ±64px night feather and black night base; retained shared world coordinates for midpoint continuity. Inspected14 native entrance/exit captures and large-button screenshot. Dark corridor continuity regression passed. This was a visual sample audit, not an exhaustive guarantee.

## Corridor backdrop ownership follow-up
Removed room backdrop stamps in corridor rows and prevented cached neighbours from drawing corridor backdrop rings. Active-room canonical corridor pass owns both halves. Corrected boundary fog floor rectangle for narrow room2 (columns9..17), excluding empty grid padding. Permanent corridor comparison rule added to AGENTS.md.

## Restore junction depth, distant black and dark-room perimeter
Restored the additional junction apron rows removed in2d6055d. Their material now uses boundary_room(y), including cached neighbours, so both halves use the upper room's material. Longitudinal rings remain single-owner. External fog keeps a slate near edge, fades RGB to black over48..180 world pixels (alpha still0..72). Night mask band extends two tiles over the room boundary (3TILE..H-3TILE), so trees/apron fade into dark room from corridor instead of a visible light stripe. Shared world coordinates and full-screen entry opacity retained.

## Smoother distant fog and clean backdrop masonry
Fog RGB now transitions slate→black over120..480px instead48..180px. Backdrop nested rings replaced with one outer band to eliminate duplicate cells. Junction apron excludes columns already covered by canonical longitudinal rings3/4. Masonry backdrop uses stacked texture rather than repeated exposed cap per row; organic textures retain exposed silhouette.

## Single-line actions, centred drop icon and aligned organic depth
Action248x88 uses no wrapping and existing single-line font fitting. Drop icon AtlasTexture crops transparent asymmetric padding and centres both axes. Fog colour fade72..280px; masonry alpha reaches full opacity32px (organic72px), stored per room/corridor area so midpoint does not switch fade. No extra backdrop for masonry/wood owner2/4/5/6. Maze extension copies actual crown atlas/radius/height outside boundary; earth expands same procedural bake two cells; trees use original variants/jitter/mirroring and full palette. Reviewed native no-fog and fog shots of all three organic materials plus masonry before release. Material ownership and dark continuity tests passed.

## Two-block masonry and soft darker fog
Restored72px fade for all materials, darkened near slate to(.070,.076,.095). Added one outward masonry/wood perimeter cell on horizontal and vertical room edges (narrow room2 uses actual columns8..18). Canonical corridor backdrop restored for masonry too. Lower entrance overlay disabled: original world-sorted lower posts remain, avoiding repaint over foreground lower walls. Upper post silhouette overlay retained.

## Wall row sorting and tool pickup icons
Extra masonry perimeter is now in the same depth-sorted renderable list as ordinary walls, not an early backdrop pass; lower roofs correctly cover upper faces. Tool actions use cropped actual atlas sprites for all10 tools regardless shared pickup label (regression tests/tool_action_icons.gd). Removed rectangular backdrop foundations. Thicket base silhouette now scalloped/rooted with foliage lobes; earth foundation narrowed beneath overlap, broad low irregular crests/shoulders replace tall pointed heaps. Inspected no-fog forest/earth/masonry images before fog shots. Material ownership/dark continuity regressions passed.

## Roof-plane fog and graded excavation apron
Masonry fog rectangles follow actual roof plane: horizontal source roof edge is26px above foot tile edge; side opaque roof ends2px inside tile edge. Offset(-2,-26), width+4 is shared by current/neighbor rooms and corridor areas, preserving midpoint coordinates. Earth bank core now fully opaque on wall cells to seal grass texture ends; sparse soil grains/small heaps extend40 source pixels onto grass, density/size rise outward, shoulder mounds close gaps at the core. Organic heaps become taller deeper in boundary. Inspected no-fog/fog excavation edge and arena north/south corners. Dark corridor continuity test passed.

## Stone icons, stable axe notches and grass under banks
Pickup atlas icons now include quest_pebble variants, rock fragments and branches; shared material labels cannot select branch icon for stones. Tree generator derives every damage stage from the canonical tree and draws an expanding axe wedge rather than cracks; verified exact RGBA equality outside notch for all6 stages, masks regenerated. Removed all brown earth foundations, extended cached grass image72 source pixels around excavation so every bank gap shows grass rather than the bitmap edge. Reviewed axe sheet and native no-fog excavation edge. Tool/resource icon and trunk mask tests passed.

## Narrow loose earth fringe and shared procedural corridor
Removed regular8px shoulder lattice; fringe shrunk40→16source pixels, grain density.72→.35 and heap chance.12→.035 with radius2..4. Room3 procedural earth bake extends through entire south shared corridor (H-5..H+5), PAD160. Static wall_room3 rendering disabled in stone/backdrop paths. One final corridor draw uses room3's same cached bake and world origin from either active room. Main earth bitmap excludes corridor to avoid double painting; final strips include12px inward protrusions, preventing lower-room floor pass clipping them at midpoint. Preserve this single pass for future corridor changes.
Native midpoint parity: left crop(140,260..215,610) and right(325,260..400,610) before/after both have exactly0 differing RGB pixels after final shared-pass fix.

## Corridor bank termination and southeast foreground hands
Earth shared corridor ends24px before lower room wall footprint boundary, at that wall's roof edge, preventing soil over masonry. Near fog slate restored(.105,.100,.135) with very soft96..360px darkening. Southeast facing7 removed from hand_is_behind; anatomical right grip remains unchanged and common tool/weapon renderer draws above body. Updated diagonal regression expectation.

## Seven-part visual/loading/gameplay follow-up
Maze outer crowns render north/sides before canopy and south after front canopy; extended grass also covers maze under two-row boundary. Removed green ground paint from all quest tree states and moved projected shadow into floor pass. Loader uses decoded static PNG strip with linear transform hold keyframes; blocked-JS browser probe3004ms captured40 frames/8 poses, real iOS hardware unavailable. Dedicated original shovel_break.wav snap/rattle triggered on durability exhaustion. Arena reward clearance checked after all props/crates installation and cached-room activation; regression50 shuffled layouts plus forced crate overlap passes. Shared upper-room final wall pass for all corridors avoids active-room dependent floor/wall sorting; includes canonical floor underneath chamfers and lower junction front row coverage. All six corridor pairs captured for pixel audit.
Final six-corridor native audit: all12 terrain crops x110..215/x325..430,y290..600 have0 differing pixels before/after active-room seam. Wider crops show tiny differences around lamps/door edges y240..245; do not claim entire frames identical (UI, gates, animation differ). Corrected extended maze grass to skip actual corridor floor tiles; floor under chamfers canonicalized. Lower-room front row repainted after corridor walls (except maze) covers corner faces. Final screenshot garden checked.

## Cloud fog and loader strip constraints
Boundary near fog RGB(.88,.89,.91), existing96..360px fade to black retained. Loader strip dimensions hardened with!important min/max widths/heights1024x128, object-fit fill and no flex shrink; clipping parent has own translateZ compositor layer/paint containment to avoid WebKit culling/resizing of translated image. Requires actual iOS followup; cannot claim hardware verified.

## Textured external cloud boundary
External boundary shader now renders dense procedural cloud texture with3 scales132/64/29px, randomized elliptical lobes/offsets and pixel-grid2px sampling. Continuous opaque cloud coverage, existing room/corridor alpha edge retained. Stable world_origin accumulates room heights and maze96px offset to avoid cloud reseed at corridor midpoint. Internal dark-room flashlight shader unchanged.
