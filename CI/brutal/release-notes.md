Morrowind with the melee combat of Dark Messiah of Might and Magic, built on OpenMW 0.51.0.
You need your own copies of Morrowind and Dark Messiah of Might and Magic.

This is an alpha release: the combat works, the game balance is not tuned yet.

## Added in 0.2.0

* The Dark Messiah importer supports GCF installations and already extracted `mm/` folders.
  All import steps accept VPK archives with any name ending in `_dir.vpk`; Steam depot names are
  no longer required. You can select the installation folder directly in the launcher.
* Dark Messiah footsteps, jump and landing sounds for the player and NPCs. Footsteps follow the
  animation and use the surface underfoot; NPC footsteps also take their footwear into account.
* **Kick always triggers ragdoll** in **Scripts → Brutal Morrowind**. Ordinary kicks knock NPCs
  and supported creatures into ragdoll without spending adrenaline. Normal kick damage, stamina
  cost and pushback are kept. This option is off by default and requires Kick and Ragdoll.

## Fixed in 0.2.0

* Shield blocking: smoother raising and lowering, corrected hit-reaction timing and return to
  guard, and the same weapon-contact sounds heard when blocking in Dark Messiah. Rapid repeated
  hits no longer leave competing reactions playing at once.
* Blocked unarmed creature attacks produce shield sparks when the shield material and effects
  settings allow them.
* NPC shields stay upright. NPCs interrupted while drawing a weapon keep it visible in hand.
* First-person legs play their full movement cycle at the right speed when no weapon is drawn.
* The launcher detects an outdated Dark Messiah import and offers to rebuild it. A successful
  update removes the old import while keeping folders from newer versions.
* Restarting an import immediately after cancelling it works without the cancelled run's
  delayed stop timer interrupting the new import.

After updating from 0.1.1, the launcher will ask you to import Dark Messiah again for the new
sounds and corrected animations. Choose **Import and play** when prompted.

## Downloads

* **Linux** (Debian 13, Ubuntu 24.04 or newer, x86-64): `BrutalMorrowind-0.2.0-Linux-64Bit.tar.gz`.
  Unpack it anywhere and run `brutalmorrowind-launcher`.
* **Windows** (Windows 10 or newer, 64-bit): `BrutalMorrowind-0.2.0-Windows-x64.exe`. Run the installer.

On the first run the launcher imports Dark Messiah's animations, sounds and textures from your copy
of the game; this takes about half a minute.

See the README in the repository for requirements, the first run and the FAQ.
