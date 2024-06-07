Documentation?

# Setup
Installing:
1. Download [Git](https://git-scm.com/download/win)
2. Run the [installation bat file](https://raw.githack.com/hamurlik/AutoAccent/master/Scripts/Install%20AutoAccent.bat) (or just `git clone https://github.com/hamurlik/AutoAccent.git`)
3. Start the Launch.bat file to open the program

Updating:
1. Start the Update.bat file (or just `git pull`)

# Usage
To use, select a text field, type your message, and press the right shift key. You should hear a short robotic beep if it worked.
The key can be changed in the settings.

You can open the settings by right clicking the tray icon (Green letter 'H')

# Presets
### Asciizonian, Bogzonian, and Truezonian
Russian sounding presets. They don't include a word filter, they only change letters.

- Asciizonian is the default, only uses ASCII characters.
- Bogzonian is a version of Asciizonian, has funnier looking v and w.
- Truezonian uses unicode characters.

To use Asciizonian and Bogzonian properly, you need to write your initial message using Cyrillic letters, transliterating into English.

So for example "Hello, how are you" would be written as "Хйелло, хов ар ю?" which the app then turns into "Khiyello, khow ar yu?".

These presets have filters for Latin letters too, but it just won't look as funny.

### Tiefling
Spanish sounding preset. Has a rather big word filter, also has elongated "r" and "s".

With this preset, putting a backtick after a vowel will put an accent mark on it. So "a`" becomes "á".

Additionally, "u~" becomes "ü", "n`" or "n~" becomes "ñ".

This preset also puts upside down exclamation points and question marks. So "Hola!" becomes "¡Hola!".

# Screenshots

![image](https://github.com/hamurlik/AutoAccent/assets/75280571/4559b5d9-a6b2-4031-b5a3-3a27de978a4c)
![image](https://github.com/hamurlik/AutoAccent/assets/75280571/8a5e5246-6d95-403c-9245-633c5c86696a)


# Contact

If you have any issues or requests, you can contact me on discord. Username is `hamurlik`

I can make you a custom preset too.

Keep in mind that presets need to have detectable patterns, like "th" becoming "z". Organic things can be hard to pick up in code as it can only read letters, not sounds. Not until I figure out how to
 hook up a phonetic dictionary to it, anyway.
