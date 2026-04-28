# Water Reminder

A floating macOS hydration note that stays visible like a sticky reminder. The glass slowly empties toward your next drink, and every click logs a full `300 mL` glass.

## Run it

```bash
./scripts/package_app.sh
./scripts/launch_native.sh
```

You can also double-click `Water Reminder.command` in Finder to launch it.

## How it works

- The user can set how often they want to drink water.
- Clicking the glass or button logs `300 mL`, refills the glass, and resets the timer.
- The app tracks today's intake in `mL` and compares it with a configurable daily goal.

## Notes

- The app is packaged as a native macOS `.app` bundle built with Apple command-line tools.
- The reminder window floats above other windows and stays visible across spaces.
- The app remembers the refill timer, the chosen reminder interval, and the chosen daily goal between launches.
