# SafeTweak

Small, honest, reversible tweaks for Windows 10/11 with a Material 3 style window.
No "10x faster PC" promises: these are a few sensible settings, each backed up and undoable.

[English](#english) · [Русский](#русский)

---

## English

### What it does

| Tweak | What changes | Undo |
|---|---|---|
| Clean temporary files | Deletes files older than 24 h from `%TEMP%` and `C:\Windows\Temp`. Files in use and links are skipped. | **Not undoable** (they are temp files) |
| Reduce telemetry | `AllowTelemetry=0` policy (on Home/Pro this means the minimum "Required" level), advertising ID off, tailored experiences off, app-launch tracking off, `DiagTrack` service disabled | Yes |
| High performance power plan | Activates the built-in High performance plan. Skipped if your PC does not have it (many Modern Standby laptops) | Yes, previous plan is restored |
| Turn off visual effects | Animations, shadows, Aero Peek, fades off. Font smoothing stays on. Sign out to apply fully | Yes |
| Startup apps | Lists apps from the `Run` registry keys; you switch off the ones you do not need. Uses the same flag as Task Manager | Yes (or re-enable in Task Manager) |

SafeTweak **never touches** Windows Defender, UAC, Windows Update / security updates, the page file, or your personal files.

### How it keeps you safe

- Needs administrator rights (it relaunches itself elevated). Without them only dry run is available.
- Creates a System Restore point before the first change (asks you if that fails, e.g. System Protection is off).
- Saves the original value of every registry value, service start type and power plan to `C:\ProgramData\SafeTweak\backup.json` before changing it. Repeated runs keep the very first original.
- **Dry run** shows exactly what would change and writes nothing.
- **Undo everything** restores all backed-up values in reverse order.

### Run it

1. Download the repository (Code → Download ZIP) and unzip it.
2. Open PowerShell in that folder and run:

```powershell
powershell -ExecutionPolicy Bypass -File .\SafeTweak.ps1
```

3. Turn on the tweaks you want, try **Dry run** first, then **Apply selected**. Reboot afterwards.

Command line (no window):

```powershell
.\SafeTweak.ps1 -DryRun -Apply Temp,Telemetry,Power,Visual   # preview
.\SafeTweak.ps1 -Apply Telemetry,Visual                       # apply
.\SafeTweak.ps1 -Apply Startup                                # pick startup apps in the console
.\SafeTweak.ps1 -Undo                                         # roll everything back
```

Options: `-NoRestorePoint` skips the restore point, `-BackupFile <path>` uses another backup file.

### Undo

Click **Undo everything** (or run `-Undo`), then reboot. The used backup is kept as `backup.json.restored-<date>`.
If something goes really wrong, use the restore point: Start → "Create a restore point" → System Restore.

### Notes

- Per-user settings (visual effects, ad ID) apply to the account that runs SafeTweak. If you elevate with a different admin account, they apply to that account.
- Some telemetry may still be sent at the "Required" level; that is a Windows limit on Home/Pro.

### Tests

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\SafeTweak.Tests.ps1
```

Checks backup and undo on a throwaway key `HKCU:\Software\SafeTweakTest` and dry-runs every tweak. No admin needed.

### Disclaimer

Provided "as is", without warranty of any kind (see [LICENSE](LICENSE)). You use it at your own risk. Read what each tweak does, try dry run first, and keep your own backups.

---

## Русский

### Что делает

| Твик | Что меняется | Откат |
|---|---|---|
| Очистка временных файлов | Удаляет файлы старше 24 часов из `%TEMP%` и `C:\Windows\Temp`. Занятые файлы и ссылки пропускаются | **Нельзя откатить** (это временные файлы) |
| Меньше телеметрии | Политика `AllowTelemetry=0` (на Home/Pro это минимальный уровень «Обязательные данные»), выключены рекламный ID, персональные рекомендации, отслеживание запуска приложений, служба `DiagTrack` отключена | Да |
| План «Высокая производительность» | Включает встроенный план. Если его нет (многие ноутбуки с Modern Standby), пропускается | Да, вернётся прежний план |
| Отключить визуальные эффекты | Анимации, тени, Aero Peek, затухания выключены. Сглаживание шрифтов остаётся. Полностью применится после выхода из системы | Да |
| Автозагрузка | Показывает приложения из ключей реестра `Run`, вы выключаете ненужные. Тот же флаг, что в Диспетчере задач | Да (или включить в Диспетчере задач) |

SafeTweak **не трогает** Защитник Windows, UAC, Центр обновления и обновления безопасности, файл подкачки и ваши личные файлы.

### Как он вас бережёт

- Нужны права администратора (перезапускается сам с повышением). Без них доступен только пробный прогон.
- Перед первым изменением создаёт точку восстановления (если не вышло, например выключена защита системы, спрашивает).
- Перед изменением сохраняет исходные значения реестра, тип запуска служб и план питания в `C:\ProgramData\SafeTweak\backup.json`. При повторных запусках хранится самое первое значение.
- **Dry run (пробный прогон)** показывает, что именно изменится, и ничего не пишет.
- **Undo everything (откатить всё)** возвращает все сохранённые значения в обратном порядке.

### Запуск

1. Скачайте репозиторий (Code → Download ZIP) и распакуйте.
2. Откройте PowerShell в этой папке и выполните:

```powershell
powershell -ExecutionPolicy Bypass -File .\SafeTweak.ps1
```

3. Включите нужные твики, сначала попробуйте **Dry run**, затем **Apply selected**. После — перезагрузка.

Командная строка (без окна):

```powershell
.\SafeTweak.ps1 -DryRun -Apply Temp,Telemetry,Power,Visual   # посмотреть
.\SafeTweak.ps1 -Apply Telemetry,Visual                       # применить
.\SafeTweak.ps1 -Apply Startup                                # выбрать автозагрузку в консоли
.\SafeTweak.ps1 -Undo                                         # откатить всё
```

Параметры: `-NoRestorePoint` — без точки восстановления, `-BackupFile <путь>` — другой файл бэкапа.

### Откат

Нажмите **Undo everything** (или `-Undo`) и перезагрузитесь. Использованный бэкап остаётся как `backup.json.restored-<дата>`.
Если всё совсем плохо — точка восстановления: Пуск → «Создание точки восстановления» → «Восстановить».

### Важно

- Настройки пользователя (эффекты, рекламный ID) применяются к учётной записи, от которой запущен SafeTweak. Если повышаете права другим админом — применятся к нему.
- На уровне «Обязательные данные» часть телеметрии всё равно уходит; это ограничение Windows Home/Pro.

### Тесты

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\SafeTweak.Tests.ps1
```

Проверяют бэкап и откат на временном ключе `HKCU:\Software\SafeTweakTest` и прогоняют все твики в режиме dry run. Админ не нужен.

### Отказ от ответственности

Программа предоставляется «как есть», без каких-либо гарантий (см. [LICENSE](LICENSE)). Вы используете её на свой риск. Прочитайте, что делает каждый твик, сначала запустите dry run и держите свои резервные копии.
