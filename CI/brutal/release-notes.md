Morrowind with the melee combat of Dark Messiah of Might and Magic, built on OpenMW 0.51.0.
You need your own copies of Morrowind and Dark Messiah of Might and Magic.

This is an alpha release: the combat works, the game balance is not tuned yet.

## Fixed in 0.1.1

* Windows: the Dark Messiah import from the launcher stopped by itself a second after it started,
  with "dm-import: cancelled". The import now runs to the end.
* Windows: the import could fail with "PermissionError: [Errno 13] Permission denied" on a file in
  `.dm-import-work\source-cache`, when two steps extracted the same file at the same time.
* A cancelled import now says why it stopped, and keeps the step logs in the `import-logs` folder
  beside the imported data. The launcher log notes when you pressed Cancel.

Players who already finished the import with 0.1.0 do not need to import again.

## Downloads

* **Linux** (Debian 13, Ubuntu 24.04 or newer, x86-64): `BrutalMorrowind-0.1.1-Linux-64Bit.tar.gz`.
  Unpack it anywhere and run `brutalmorrowind-launcher`.
* **Windows** (Windows 10 or newer, 64-bit): `BrutalMorrowind-0.1.1-Windows-x64.exe`. Run the installer.

On the first run the launcher imports Dark Messiah's animations, sounds and textures from your copy
of the game; this takes about half a minute.

See the README in the repository for requirements, the first run and the FAQ.
