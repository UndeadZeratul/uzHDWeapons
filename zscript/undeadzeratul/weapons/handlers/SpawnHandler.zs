// Struct for itemspawn information.
class UZSpawnItem play {
    // ID by string for spawner
    string spawnName;

    // ID by string for spawnees
    Array<UZSpawnItemEntry> spawnReplaces;

    // Whether or not to persistently spawn.
    bool isPersistent;

    // Whether or not to replace the original item.
    bool replaceItem;

    string toString() {

        let replacements = "[";

        foreach (spawnReplace : spawnReplaces) replacements = replacements..", "..spawnReplace.toString();

        replacements = replacements.."]";

        return String.format("{ spawnName=%s, spawnReplaces=%s, isPersistent=%b, replaceItem=%b }", spawnName, replacements, isPersistent, replaceItem);
    }
}

class UZSpawnItemEntry play {
    string name;
    int    chance;

    string toString() {
        return String.format("{ name=%s, chance=%s }", name, chance >= 0 ? "1/"..(chance + 1) : "never");
    }
}

// Struct for passing useinformation to ammunition.
class UZSpawnAmmo play {
    // ID by string for the header ammo.
    string ammoName;

    // ID by string for weapons using that ammo.
    Array<string> weaponNames;

    string toString() {

        let weapons = "[";

        foreach (weaponName : weaponNames) weapons = weapons..", "..weaponName;

        weapons = weapons.."]";

        return String.format("{ ammoName=%s, weaponNames=%s }", ammoName, weapons);
    }
}



// One handler to rule them all.
class UZWeaponsHandler : EventHandler {

    // List of persistent classes to completely ignore.
    // This -should- mean this mod has no performance impact.
    static const string blacklist[] = {
        'HDSmoke',
        'BloodTrail',
        'CheckPuff',
        'WallChunk',
        'HDBulletPuff',
        'HDFireballTail',
        'ReverseImpBallTail',
        'HDSmokeChunk',
        'ShieldSpark',
        'HDFlameRed',
        'HDMasterBlood',
        'PlantBit',
        'HDBulletActor',
        'HDLadderSection'
    };

    // List of CVARs for Backpack Spawns
    array<Class <Inventory> > backpackBlacklist;

    // Cache of Ammo Box Loot Table
    private HDAmBoxList ammoBoxList;

    // List of weapon-ammo associations.
    // Used for ammo-use association on ammo spawn (happens very often).
    array<UZSpawnAmmo> ammoSpawnList;

    // List of item-spawn associations.
    // used for item-replacement on mapload.
    array<UZSpawnItem> itemSpawnList;

    bool cvarsAvailable;

    // appends an entry to itemSpawnList;
    void addItem(string name, Array<UZSpawnItemEntry> replacees, bool persists, bool rep=true) {

        if (hd_debug) {

            let msg = "Adding "..(persists ? "Persistent" : "Non-Persistent").." Replacement Entry for "..name..": [";

            foreach (replacee : replacees) msg = msg..", "..replacee.toString();

            console.printf(msg.."]");
        }

        // Creates a new struct;
        UZSpawnItem spawnee = UZSpawnItem(new('UZSpawnItem'));

        // Populates the struct with relevant information,
        spawnee.spawnName = name;
        spawnee.isPersistent = persists;
        spawnee.replaceItem = rep;
        spawnee.spawnReplaces.copy(replacees);

        // Pushes the finished struct to the array.
        itemSpawnList.push(spawnee);
    }

    UZSpawnItemEntry addItemEntry(string name, int chance) {
        // Creates a new struct;
        UZSpawnItemEntry spawnee = UZSpawnItemEntry(new('UZSpawnItemEntry'));
        spawnee.name = name;
        spawnee.chance = chance;
        return spawnee;
    }

    // appends an entry to ammoSpawnList;
    void addAmmo(string name, Array<string> weapons) {

        if (hd_debug) {
            let msg = "Adding Ammo Association Entry for "..name..": [";

            foreach (weapon : weapons) msg = msg..", "..weapon;

            console.printf(msg.."]");
        }

        // Creates a new struct;
        UZSpawnAmmo spawnee = UZSpawnAmmo(new('UZSpawnAmmo'));
        spawnee.ammoName = name;
        spawnee.weaponNames.copy(weapons);

        // Pushes the finished struct to the array.
        ammoSpawnList.push(spawnee);
    }


    // Populates the replacement and association arrays.
    void init() {

        cvarsAvailable = true;

        //-----------------
        // Backpack Spawns
        //-----------------

        if (!bhg_allowBackpacks)      backpackBlacklist.push((Class<Inventory>)('UZBHGen'));
        if (!pipebomb_allowBackpacks) backpackBlacklist.push((Class<Inventory>)('HDPipeBombAmmo'));

        //------------
        // Ammunition
        //------------


        //------------
        // Weaponry
        //------------

        // Black Hole Generators
        Array<UZSpawnItemEntry> spawns_bhg;
        spawns_bhg.push(addItemEntry('BFG9000', bhg_spawn_bias));
        addItem('UZBHGen', spawns_bhg, bhg_persistent_spawning);

        // Pipe Bombs
        Array<UZSpawnItemEntry> spawns_pipebomb;
        spawns_pipebomb.push(addItemEntry('FragP', pipebomb_spawn_bias));
        addItem('HDPipeBombP', spawns_pipebomb, pipebomb_persistent_spawning);

        // Pipe Bomb Packs
        Array<UZSpawnItemEntry> spawns_pipebombpack;
        spawns_pipebombpack.push(addItemEntry('HDFragGrenadePickup', pipebomb_spawn_bias));
        addItem('HDPipeBombPickup', spawns_pipebombpack, pipebomb_persistent_spawning);

        //------------
        // Ammunition
        //------------
    }

    // Random stuff, stores it and forces negative values just to be 0.
    bool giveRandom(int chance) {
        if (chance > -1) {
            let result = random(0, chance);

            if (hd_debug) console.printf("Rolled a "..(result + 1).." out of "..(chance + 1));

            return result == 0;
        }

        return false;
    }

    // Tries to replace the item during spawning.
    bool tryReplaceItem(ReplaceEvent e, string spawnName, int chance) {
        if (giveRandom(chance)) {
            if (hd_debug) console.printf(e.replacee.getClassName().." -> "..spawnName);

            e.replacement = spawnName;

            return true;
        }

        return false;
    }

    // Tries to create the item via random spawning.
    bool tryCreateItem(Actor thing, string spawnName, int chance) {
        if (giveRandom(chance)) {
            if (hd_debug) console.printf(thing.getClassName().." + "..spawnName);

            Actor.Spawn(spawnName, thing.pos);

            return true;
        }

        return false;
    }

    override void worldLoaded(WorldEvent e) {

        // Populates the main arrays if they haven't been already.
        if (!cvarsAvailable) init();

        foreach (bl : backpackBlacklist) {
            if (hd_debug) console.printf("Removing "..bl.getClassName().." from Backpack Spawn Pool");

            BPSpawnPool.removeItem(bl);
        }
    }

    override void checkReplacement(ReplaceEvent e) {

        // Populates the main arrays if they haven't been already.
        if (!cvarsAvailable) init();

        // If there's nothing to replace or if the replacement is final, quit.
        if (!e.replacee || e.isFinal) return;

        // If thing being replaced is blacklisted, quit.
        foreach (bl : blacklist) if (e.replacee is bl) return;

        string candidateName = e.replacee.getClassName();

        // If current map is Range, quit.
        if (level.MapName == 'RANGE') return;

        handleWeaponReplacements(e, candidateName);
    }

    override void worldThingSpawned(WorldEvent e) {

        // Populates the main arrays if they haven't been already.
        if (!cvarsAvailable) init();

        // If thing spawned doesn't exist, quit.
        if (!e.thing) return;

        // If thing spawned is blacklisted, quit.
        foreach (bl : blacklist) if (e.thing is bl) return;

        // Handle Ammo Box Loot Table Filtering
        if (e.thing is 'HDAmBox' && !ammoBoxList) handleAmmoBoxLootTable();

        string candidateName = e.thing.getClassName();

        // Pointers for specific classes.
        let ammo = HDAmmo(e.thing);

        // If the thing spawned is an ammunition, add any and all items that can use this.
        if (ammo) handleAmmoUses(ammo, candidateName);

        // If current map is Range, quit.
        if (level.MapName == 'RANGE') return;

        handleWeaponSpawns(e.thing, ammo, candidateName);
    }

    private void handleAmmoBoxLootTable() {
        ammoBoxList = HDAmBoxList.Get();

        foreach (bl : backpackBlacklist) {
            let index = ammoBoxList.invClasses.find(bl.getClassName());

            if (index != ammoBoxList.invClasses.Size()) {
                if (hd_debug) console.printf("Removing "..bl.getClassName().." from Ammo Box Loot Table");

                ammoBoxList.invClasses.Delete(index);
            }
        }
    }

    private void handleAmmoUses(HDAmmo ammo, string candidateName) {
        foreach (ammoSpawn : ammoSpawnList) if (candidateName ~== ammoSpawn.ammoName) {
            if (hd_debug) {
                console.printf("Adding the following to the list of items that use "..ammo.getClassName().."");
                foreach (weapon : ammoSpawn.weaponNames) console.printf("* "..weapon);
            }

            ammo.itemsThatUseThis.append(ammoSpawn.weaponNames);
        }
    }

    private void handleWeaponReplacements(ReplaceEvent e, string candidateName) {

        // Checks if the level has been loaded more than 1 tic.
        bool prespawn = !(level.maptime > 1);

        // Iterates through the list of item candidates for e.thing.
        foreach (itemSpawn : itemSpawnList) {

            if ((prespawn || itemSpawn.isPersistent) && itemSpawn.replaceItem) {
                foreach (spawnReplace : itemSpawn.spawnReplaces) {
                    if (spawnReplace.name ~== candidateName) {
                        if (hd_debug) console.printf("Attempting to replace "..candidateName.." with "..itemSpawn.spawnName.."...");

                        if (tryReplaceItem(e, itemSpawn.spawnName, spawnReplace.chance)) return;
                    }
                }
            }
        }
    }

    private void handleWeaponSpawns(Actor thing, HDAmmo ammo, string candidateName) {

        // Checks if the level has been loaded more than 1 tic.
        bool prespawn = !(level.maptime > 1);

        // Iterates through the list of item candidates for e.thing.
        foreach (itemSpawn : itemSpawnList) {

            // if an item is owned or is an ammo (doesn't retain owner ptr),
            // do not replace it.
            let item = Inventory(thing);
            if (
                (prespawn || itemSpawn.isPersistent)
             && (!(item && item.owner) && (!ammo || prespawn))
             && !itemSpawn.replaceItem
            ) {
                foreach (spawnReplace : itemSpawn.spawnReplaces) {
                    if (spawnReplace.name ~== candidateName) {
                        if (hd_debug) console.printf("Attempting to spawn "..itemSpawn.spawnName.." with "..candidateName.."...");

                        if (tryCreateItem(thing, itemSpawn.spawnName, spawnReplace.chance)) return;
                    }
                }
            }
        }
    }
}
