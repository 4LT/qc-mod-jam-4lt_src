# Leading-Shot Turrets Mod

Turrets that fire lasers ahead of enemy players. Entry for Mod Jam 2.

## Build Requirements

* fteqcc - make sure it's in your `PATH` if you want to use the Makefile!

## Building

### Linux/Cygwin/Anything with `make`

Run `make` from the root directory. If you have a Quake installation,
you can also run
```
QUAKEDIR=/path/to/quake/root make install
```
to install the mod, although you'll still be missing assets (see below).

### Anywhere

Run `fteqcc -o progs.dat` from the root directory.

## Assets

TBD Pending release of Mod Jam 2

Required files:
* `sound/4lt/beep_s.wav`
* `sound/4lt/beep_f.wav`
* `progs/4lt/barrel.mdl`
* `progs/4lt/base.mdl`

## Patching

Copy `4lt_math.qc` and `4lt_turret.qc` into your own code base and reference
them at the end of your `progs.src`, then patch your `client.qc` obituary
to include `trap_turret_point` and `trap_turret_solid`.  Please, for the sake
of your code base's readability, strip out the `FourL_`/`fourl_`/`FOURL_`
prefixes from my functions; these are only a safety mechanism to prevent
clobbering other functions when included in Mod Jam 2.

## License

`4lt_math.qc` and `4lt_turret.qc` are licensed under CC0
[linked here](https://creativecommons.org/publicdomain/zero/1.0/]).

The other qc files are... eh, who knows?  GPL presumably, but Id dropped the
ball on the 1.06 release.
