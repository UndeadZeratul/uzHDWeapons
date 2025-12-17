class UZWeaponsSpawnHandler : EventHandler {

    override void worldLoaded(WorldEvent e) {

        forEach (s : Level.sectors) {

            // Prefer larger sectors
            if (HDCore.getRandomInt(0, 1024, hdc_random_mode) < HDCore.getSectorArea(s)) continue;

            // Prefer darker sectors
            if (HDCore.getRandomInt(0, 256, hdc_random_mode) < s.lightLevel) continue;

            // If sector contains a PlayerPawn, skip.
            for (let i = 0; i < MAXPLAYERS; i++) if (playerInGame[i] && players[i].mo && players[i].mo.curSector == s) continue;

            spawnFloorTraps(s);

            spawnWallTraps(s);
        }
    }

    private void spawnFloorTraps(Sector s) {

        // If Claymore Spawners are disabled, quit.
        if (!uz_floortrap_spawners) return;

        let area   = HDCore.getSectorArea(s);
        let radius = HDCore.getSectorRadius(s);

        name trapClasses[] = { 'UZPlacedClaymore', 'UZLandMine' };
        let trapClass      = trapClasses[HDCore.getRandomInt(0, trapClasses.size() - 1)];

        // Somewhere between 0 and 1/1024th the sector size in square meters should be good for a sector
        // TODO: Allow reduction rate to be configurable
        int max = int(HDCore.getRandomInt(0, area, hdc_random_mode) / HDCONST_ONEMETRE) >> 10;
        for (let i = 0; i < max; i++) {
            let angle = HDCore.getRandomInt(1, 360, hdc_random_mode);
            let dist  = HDCore.getRandomDouble(0, radius, hdc_random_mode);
            let xy    = s.centerspot + (dist * cos(angle), dist * sin(angle));
            let pos   = (xy.x, xy.y, s.centerFloor());

            // Don't spawn traps too close to players
            for (let i = 0; i < MAXPLAYERS; i++) if (players[i].mo && (players[i].mo.pos - pos).length() < (10 * HDCONST_ONEMETRE)) continue;

            if (Level.PointInSector(xy) == s) {
                let a = HDCore.SpawnStuff(trapClass, pos, randomVel: false, allowInvalidPos: true);

                if (a) {
                    a.angle = angle;
                }
            }
        }
    }

    private void spawnWallTraps(Sector s) {

        // If Laser TripBomb Spawners are disabled, quit.
        if (!uz_walltrap_spawners) return;

        name trapClasses[]  = { 'UZLaserTripBombPlanted' };
        let trapClass       = trapClasses[HDCore.getRandomInt(0, trapClasses.size() - 1)];

        forEach(l : s.lines) {

            // If line is too short, skip.
            if (l.delta.length() < 256) continue;
            
            // Spawn more in darker
            if (HDCore.getRandomInt(0, 256, hdc_random_mode) < s.lightLevel) continue;

            let twoSided = l.flags&Line.ML_TWOSIDED;
            let facingBack = twoSided && l.sideDef[Line.BACK] && l.sideDef[Line.BACK].sector == s;

            let inSide = l.sideDef[facingBack ? Line.BACK : Line.FRONT];
            let outSide = l.sideDef[facingBack ? Line.FRONT : Line.BACK];
            let floorDelta = twoSided ? inSide.sector.centerFloor() - outSide.sector.centerFloor() : -HDCore.getSectorHeight(s);

            // If line is two-sided & outside floor is under a meter above the inside floor, skip.
            if (floorDelta > -HDCONST_ONEMETRE) continue;

            // if (l.flags&~Line.ML_BLOCKING) continue;

            let step = 1.0 / (l.delta.length() / HDCore.getRandomDouble(128, 256, hdc_random_mode));
            let ratio = step;
            let delta = facingBack ? l.delta : -l.delta;

            while (ratio < 1.0) {
                let angle = VectorAngle(-delta.y, delta.x);
                let xy    = HDGMVectorUtil.lerpVec2(l.v1.p, l.v2.p, ratio);
                let pos   = (xy.x + cos(angle), xy.y + sin(angle), s.centerFloor() + min(0.5 * abs(floorDelta), (HDCore.getRandomDouble(0.5, 1.0, hdc_random_mode) * HDCONST_ONEMETRE)));

                // Spawn a Laser Tripbomb along the wall, roughly a metre above the floor
                let a = HDCore.spawnStuff(trapClass, pos, randomVel: false, allowInvalidPos: true);

                if (a) {
                    
                    a.angle = angle;

                    FLineTraceData ltd;
                    a.lineTrace(
                        angle,
                        10 * HDCONST_ONEMETRE,
                        a.pitch,
                        data: ltd
                    );

                    if (!ltd.hitline || HDF.lineTraceHitSky(ltd)) {
                        HDCore.log('UZWeps.SpawnHandler', LOGGING_DEBUG, "Opposite wall too far to be effective trap, destroying Laser TripBomb.");

                        a.destroy();
                    }
                }

                ratio += step;
            }
        }
    }
}
