class UZWeaponsSpawnHandler : EventHandler {

    Array<Sector> trappedSectors;

    override void worldLoaded(WorldEvent e) {

        // If neither floor/wall traps are enabled, quit.
        if (!uz_floortrap_spawners) return;

        let hdcSpawnHandler = HDCoreSpawnHandler(StaticEventHandler.find('HDCoreSpawnHandler'));

        // If current map is blacklisted, quit.
        forEach (bl : hdcSpawnHandler.mapBlacklist) if (Level.MapName == bl) return;

        BuildSectors();
    }

    override void worldTick() {

        if (HDCore.isPreSpawn() && uz_floortrap_spawners) {

            HDCore.log('UZWeps.SpawnHandler', LOGGING_DEBUG, "Sector is large, dark, and empty enough, placing traps.");

            let max = trappedSectors.size();
            let incr = max(hdc_prespawn_threshold, 1);
            for (let i = Level.mapTime; i < max; i += incr) {

                let s = trappedSectors[i];

                if (uz_floortrap_spawners) spawnFloorTraps(s, HDCore.getSectorArea(s) / HDCONST_ONEMETRE);
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

            HDCore.log('UZWeps.SpawnHandler', LOGGING_DEBUG, "Attempting to spawn '"..trapClass.."' floor trap in s="..s.." @ "..pos..", angle="..angle..", dist="..dist);

            // Don't spawn traps too close to players
            let tooClose = false;
            for (let i = 0; i < MAXPLAYERS; i++) {
                if (players[i].mo && (players[i].mo.pos - pos).length() < (10 * HDCONST_ONEMETRE)) {
                    tooClose = true;
                    break;
                }
            }

            if (tooClose) continue;

            if (Level.PointInSector(xy) == s) {
                let a = HDCore.SpawnStuff(trapClass, pos, randomVel: false, allowInvalidPos: true);

                if (a) {
                    a.angle = angle;
                }
            }
        }
    }
}
