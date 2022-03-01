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

[modjam 2022](http://www.khreathor.xyz/quake_maps/releases/modjam2_ai.zip)

Required files:
* `sound/4lt/beep_s.wav`
* `sound/4lt/beep_f.wav`
* `progs/4lt/barrel.mdl`
* `progs/4lt/base.mdl`

## Patching

Copy `math.qc` and `turret.qc` into your own code base and reference
them at the end of your `progs.src`, then patch your `client.qc` obituary
to include `trap_turret_point` and `trap_turret_solid`. 

## License

`math.qc` and `turret.qc` are licensed under CC0
[linked here](https://creativecommons.org/publicdomain/zero/1.0/]).

The other qc files are... eh, who knows?  GPL presumably, but Id dropped the
ball on the 1.06 release.
