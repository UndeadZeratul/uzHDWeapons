class UZWeaponsSpawnHandler : EventHandler {

    Array<Sector> trappedSectors;

    override void worldLoaded(WorldEvent e) {

        // If neither floor/wall traps are enabled, quit.
        if (!(uz_floortrap_spawners || uz_walltrap_spawners)) return;

        BuildSectors();
    }

    override void worldTick() {

        if (HDCore.isPreSpawn() && (uz_floortrap_spawners || uz_walltrap_spawners)) {

            let max = trappedSectors.size();
            let incr = max(hdc_prespawn_threshold, 1);
            for (let i = Level.mapTime; i < max; i += incr) {

                let s = trappedSectors[i];

                if (uz_floortrap_spawners) spawnFloorTraps(s, HDCore.getSectorArea(s) / HDCONST_ONEMETRE);

                if (uz_walltrap_spawners) spawnWallTraps(s, HDCore.getSectorHeight(s));
            }
        } else if (!bDESTROYED) {
            destroy();
        }

    }

    private void BuildSectors() {
        trappedSectors.clear();

        forEach (s : Level.sectors) {

            // If sector is null, skip.
            if (!s) continue;

            let height = HDCore.getSectorHeight(s);

            // If sector is not tall enough, skip.
            if (height < (2 * HDCONST_ONEMETRE)) continue;

            let area = HDCore.getSectorArea(s) / HDCONST_ONEMETRE;

            // Prefer larger sectors
            if (area < 1024 && HDCore.getRandomInt(0, 1024, hdc_random_mode) < area) continue;

            // Prefer darker sectors
            if (s.lightLevel < 256 && HDCore.getRandomInt(0, 256, hdc_random_mode) < s.lightLevel) continue;

            // If sector contains a PlayerPawn, skip.
            if (HDCore.anyPlayersInSector(s)) continue;

            trappedSectors.push(s);
        }
    }

    private void spawnFloorTraps(Sector s, double area) {

        let radius = HDCore.getSectorRadius(s);

        name trapClasses[] = { 'UZPlacedClaymore', 'UZLandMine' };
        let trapClass      = trapClasses[HDCore.getRandomInt(0, trapClasses.size() - 1)];

        // Somewhere between 0 and 1/1024th the sector size in square meters should be good for a sector
        // TODO: Allow reduction rate to be configurable
        int max = HDCore.getRandomInt(0, area, hdc_random_mode) >> 10;
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

    private void spawnWallTraps(Sector s, double height) {

        name trapClasses[] = { 'UZLaserTripBombPlanted' };
        let trapClass      = trapClasses[HDCore.getRandomInt(0, trapClasses.size() - 1)];

        forEach(l : s.lines) {

            // If line is too short, skip.
            if (l.delta.length() < 256) continue;
            
            let twoSided = l.flags&Line.ML_TWOSIDED;
            let facingBack = twoSided && l.sideDef[Line.BACK] && l.sideDef[Line.BACK].sector == s;

            let inSide = l.sideDef[facingBack ? Line.BACK : Line.FRONT];
            let outSide = l.sideDef[facingBack ? Line.FRONT : Line.BACK];
            let floorDelta = twoSided ? inSide.sector.centerFloor() - outSide.sector.centerFloor() : -height;

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
