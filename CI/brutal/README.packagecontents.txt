=== Package contents ===

This package contains Linux binaries of Brutal Morrowind. It runs on Debian 13
(Trixie), Ubuntu 24.04 and newer distributions.

=== Running ===

Unpack the archive anywhere and run "brutalmorrowind-launcher".

Run the shell scripts (the files without a suffix), not the *.x86_64 files: the
scripts point the programs at the libraries in "lib" and the Qt plugins in
"plugins". Set DEBUG=1 to run a program under gdb.

The package folder is never written to. Settings, saves and the imported Dark
Messiah data go to ~/.config/brutalmorrowind and ~/.local/share/brutalmorrowind.

=== Contents ===

brutalmorrowind            the game
brutalmorrowind-launcher   the launcher
brutalmorrowind-wizard     the Morrowind installation wizard
brutalmorrowind-import     the Dark Messiah importer, with its own Python in dm-import/
lib/                       bundled libraries and OpenSceneGraph plugins
plugins/                   Qt plugins
resources/                 engine resources and the built-in Brutal Morrowind scripts
