// ------------------------------------------------------------
// Remember the rule of 6...
// ------------------------------------------------------------
class UZSPAS : HDCoreShotgun {

    int frameTimer;

    default {
        //$Category "Weapons/Hideous Destructor"
        //$Title "SPAS-12 shotgun"
        //$Sprite "SPSPA0"

        tag "$TAG_SPAS12";
        obituary "$OB_SPAS12";

        scale 0.6;

        Inventory.icon "SPSPA0";
        Inventory.pickupMessage "$PICKUP_SPAS12";

        Weapon.selectionOrder 31;
        Weapon.slotNumber 3;
        Weapon.slotPriority 1;
        Weapon.bobRangeX 0.21;
        Weapon.bobRangeY 0.9;

        HDWeapon.barrelSize 30, 0.5, 2;
        HDWeapon.refID "sps";
        HDWeapon.loadoutCodes "
            \cufiremode - 0/1, whether to start in semi or not
            \curounds - 1-6, whether to load with specific Shotshells:
                - 1 -> Buckshot
                - 2 -> Slug
                - 3 -> Flechette
                - 4 -> Explosive Slug
                - 5 -> Less-Lethal
                - 6 -> Flare
            ";

        HDCoreShotgun.distantSound       "world/spasFar";
        HDCoreShotgun.openSound          "weapons/spasOpen";
        HDCoreShotgun.rackBakSound       "weapons/spasRackBak";
        HDCoreShotgun.rackFwdSound       "weapons/spasRackFwd";
        HDCoreShotgun.reloadSound        "weapons/spasReload";
        HDCoreShotgun.reloadChamberSound "weapons/spasReloadChamber";
        HDCoreShotgun.shotSound          "weapons/spas";
        HDCoreShotgun.unloadChamberSound "weapons/spasUnloadChamber";
    }

    override double gunmass() { return 8 + ((isRoundChambered() + getNumTubeRounds()) * 0.3); }

    override double weaponbulk() { return 100 + (25 * getWepStatusFlag(SPASF_STOCK)) + ((isRoundChambered() + getNumTubeRounds()) * ENC_SHELLLOADED); }

    override string,double getpickupsprite(bool usespare) { return "SPSP"..(getSpareWeaponValue(0, usespare)&SPASF_STOCK ? "B" : "A").."0", 1.0; }

    int getStrengthTics(int baseTics) { return max(1, round(baseTics * getStrengthMult())); }

    double getStrengthMult() { return HDPlayerPawn(owner) ? HDGMGlobalMaths.lerpDouble(1.5, 0.667, HDPlayerPawn(owner).strength) : 1.0; }

    override void DrawHUDStuff(HDStatusBar sb, HDWeapon hdw, HDPlayerPawn hpl) {

        HDCoreShotgun sg = HDCoreShotgun(hdw);

        if (!sg) return;

        let pos = (-16, -11);

        // TODO: Loop through all known shell types, draw them
        if (sb.hudlevel == 1) {
            let ammo = sg.getSelectedShellType();

            if (ammo) {
                sb.drawimage(sg.getShellIcon(ammo), pos + (-49, 1), sb.DI_SCREEN_CENTER_BOTTOM);
                sb.drawnum(hpl.countinv(sg.getShellAmmo(ammo)), pos.x - 48, pos.y + 3, sb.DI_SCREEN_CENTER_BOTTOM);
            }
        }

        // Draw Fire Mode
        if (getWepStatusFlag(SPASF_FIREMODE)) sb.drawimage("STSEMAUT", pos + (-12, -1), sb.DI_SCREEN_CENTER_BOTTOM);
        
        // Draw Chambered Round
        if (sg.isRoundChambered()) {
            let round = sg.getChamberedRound();
            if (sg.isChamberedRoundLive()) {
                sg.drawShell(sb, round, pos);
            } else {
                HDCore.DrawSpentShell(
                    sb,
                    getShellColor(round),
                    pos,
                    DRAWPREFAB_EW,
                    1.0,
                    sb.DI_SCREEN_CENTER_BOTTOM
                );
            }
        }

        // Draw Tube Shells
        let numTube = sg.getNumTubeRounds();
        for (int i = 0; i < numTube; i++) {
            sg.drawShell(
                sb,
                HDCore.octalArrayGet(sg.weaponStatus[HDC_SHOTS_TUBE], i),
                pos - ((i * 9), -6),
                getWepStatusFlag(SPASF_TUBELOCK) ? 0x88888888 : 0x00000000
            );
        }
    }

    override string gethelptext() {
        LocalizeHelp();
        return pressingFireMode() ? (
                LWPHELP_FIRE..StringTable.Localize("$SPASWH_TOGGLESEMI")
                ..LWPHELP_ALTFIRE..StringTable.Localize("$SPASWH_TOGGLESTOCK")
                ..LWPHELP_RELOAD..StringTable.Localize("$SPASWH_PREVSHELL")
                ..LWPHELP_FIREMODE..StringTable.Localize("$SPASWH_NEXTSHELL")
            ) : (
                LWPHELP_FIRESHOOT
                ..LWPHELP_ALTFIRE..StringTable.Localize("$PUMP")
                ..LWPHELP_RELOAD..StringTable.Localize("$SPASWH_RELOAD")
                ..LWPHELP_ALTRELOAD..StringTable.Localize("$SPASWH_ALTRELOADHOLD")
                ..LWPHELP_UNLOADUNLOAD
                ..LWPHELP_FIREMODE..StringTable.Localize("$SPASWH_FIREMODEHOLD")
                ..LWPHELP_MAGMANAGER
            );
    }

    override void DrawSightPicture(
        HDStatusBar sb, HDWeapon hdw, HDPlayerPawn hpl,
        bool sightbob, Vector2 bob, double fov, bool scopeview, Actor hpc
    ) {
        int cx,cy,cw,ch;
        [cx,cy,cw,ch]=screen.GetClipRect();

        sb.SetClipRect(
            -16 + bob.x, -32 + bob.y, 32, 40,
            sb.DI_SCREEN_CENTER
        );

        Vector2 bobb = bob * 1.1;
        sb.drawimage(
            "frntsite",
            (0, 0) + bobb,
            sb.DI_SCREEN_CENTER|sb.DI_ITEM_TOP
        );
        sb.SetClipRect(cx,cy,cw,ch);

        sb.drawimage(
            "sgbaksit",
            (0, 0) + bob,
            sb.DI_SCREEN_CENTER|sb.DI_ITEM_TOP,
            alpha: 0.9
        );
    }

    override void tick() {
        super.tick();

        if (owner && owner.player && owner.player.readyWeapon && owner.player.readyWeapon == self) {
            let psp = owner.player.findPSprite(PSP_WEAPON);

            if (frameTimer) {
                frameTimer--;
            } else if (psp.frame == psp.curState.frame && getWepStatusFlag(SPASF_STOCK)) {
                psp.frame++;
            }
        }
    }

    void setFireMode(bool value) {
        let val = getWepStatusFlag(SPASF_FIREMODE);
        
        if (val != value) {
            A_SetWepStatusFlags(SPASF_FIREMODE, value);
            owner.A_StartSound("weapons/spasClick", CHAN_6);
        }
    }

    void setStock(bool value) {
        let val = getWepStatusFlag(SPASF_STOCK);
        
        if (val != value) {
            A_SetWepStatusFlags(SPASF_STOCK, value);
            barrelLength = value ? default.barrelLength : 20;
            owner.A_StartSound((value ? "weapons/spasStockOut" : "weapons/spasStockIn"), CHAN_6);
        }
    }

    void setTubeLock(bool value) {
        let val = getWepStatusFlag(SPASF_TUBELOCK);
        
        if (val != value) {
            A_SetWepStatusFlags(SPASF_TUBELOCK, value);
            owner.A_StartSound("weapons/spasClick", CHAN_6);
        }
    }

    states {
        spawn:
            SPSP A -1 nodelay {
                frame = invoker.getWepStatusFlag(SPASF_STOCK);
            }
            stop;

        select0:
            SPSG A 0;
            goto select0big;
        deselect0:
            SPSG A 0 {
                if (
                    invoker.getWepStatusFlag(SPASF_STOCK)
                    && !(
                        player.pendingWeapon is 'NullWeapon'
                        || countinv('NulledWeapon')
                    )
                ) invoker.setStock(false);
            }
            goto deselect0big;
        ready:
            SPSG A 0 {
                if (!pressingAltFire()) {
                    if (!pressingFire()) A_ClearRefire();

                    A_SetWepStatusFlags(HDC_SHOTF_ALTHOLDING, false);
                }

                invoker.setTubeLock(pressingAltReload());
            }
            #### A 0 A_SetHelpText();
            #### A 1 A_WeaponReady(WRF_ALL);
            goto readyend;

        fire:
            #### A 0 A_JumpIf(invoker.isChamberedRoundLive(), "shoot");
            #### A 1 A_WeaponReady(WRF_NONE);
            #### A 0 A_Refire();
            goto ready;

        hold:
            #### A 0 {
                if (!pressingAltFire()) {
                    A_SetWepStatusFlags(HDC_SHOTF_ALTHOLDING, false);
                } else if (!invoker.getWepStatusFlag(HDC_SHOTF_ALTHOLDING)) {
                    setWeaponState("chamber");
                }
            }
            #### A 1 A_WeaponReady(WRF_NOFIRE);
            #### A 0 A_Refire();
            goto ready;

        firemode:
            #### A 0 A_JumpIf(!pressingFireMode(), "nope");
            #### A 0 A_WeaponBusy(true);
            #### A 1 {
                if (justPressed(BT_ATTACK)) {
                    invoker.setFireMode(!invoker.getWepStatusFlag(SPASF_FIREMODE));
                } else if (justPressed(BT_ALTATTACK)) {
                    invoker.setStock(!invoker.getWepStatusFlag(SPASF_STOCK));
                } else if (justPressed(BT_RELOAD)) {
                    invoker.selectNextShellType();
                } else if (justPressed(BT_ALTRELOAD)) {
                    invoker.selectPrevShellType();
                }
            }
            loop;

        shoot:
            #### A 2;
            #### A 1 offset(0, 36) A_FireShotgun(recoilMult: invoker.getStrengthMult() * (invoker.getWepStatusFlag(SPASF_STOCK) ? 1.0 : 1.5));
            #### C 1 A_WeaponReady(WRF_NOFIRE);
            #### C 0 A_JumpIf(invoker.getWepStatusFlag(SPASF_FIREMODE), "chambersemi");
            goto ready;

        pumplocked:
            #### A 0 A_JumpIf(invoker.getWepStatusFlag(HDC_SHOTF_ALTHOLDING), "nope");
            #### A 0 A_SetWepStatusFlags(HDC_SHOTF_ALTHOLDING, true);
            #### A 0 A_StartSound("weapons/spasClick", CHAN_6);
            #### AAAA 1 A_MuzzleClimb(frandom[uzwepsrand](-0.5, 0.5), wepdot: false);
            #### A 0 A_JumpIf(!pressingAltFire(), "nope");
            loop;

        chambersemi:
            #### A 1 A_Chamber();
            #### A 0 A_Refire();
            goto ready;

        altfire:
        chamber:
            #### A 0 A_JumpIf(invoker.getWepStatusFlag(SPASF_FIREMODE), "pumplocked");
            #### A 0 A_JumpIf(invoker.getWepStatusFlag(HDC_SHOTF_ALTHOLDING), "nope");
            #### A 0 A_SetWepStatusFlags(HDC_SHOTF_ALTHOLDING, true);
            #### A 0 A_StartSound(invoker.rackBakSound,8);
            #### Q 2 A_SetTics(invoker.getStrengthTics(2));
            #### Q 0 A_MuzzleClimb(0, frandom[uzwepsrand](0.6, 1.0), wepdot: false);
            #### Q 3 A_SetTics(invoker.getStrengthTics(3));
            #### Q 0 A_MuzzleClimb(0, frandom[uzwepsrand](0.6, 1.0), wepdot: false);
            #### Q 3 A_SetTics(invoker.getStrengthTics(3));
            #### Q 0 A_JumpIf(pressingAltFire(), "longstroke");
            #### Q 2 A_SetTics(invoker.getStrengthTics(2));
            goto unrack;

        longstroke:
            #### S 2 A_MuzzleClimb(frandom[uzwepsrand](1.0, 2.0), wepdot: false);
            #### S 0 A_Chamber(tubeSlot: invoker.getWepStatusFlag(SPASF_TUBELOCK) ? 31 : HDC_SHOTS_TUBE);
            #### S 0 A_MuzzleClimb(-frandom[uzwepsrand](1.0, 2.0), wepdot: false);
        racked:
            #### S 1 A_WeaponReady(WRF_NOFIRE);
            #### S 0 A_JumpIf(!pressingAltFire(), "unrack");
            #### S 0 A_JumpIf(pressingUnload(), "rackunload");
            #### S 0 A_JumpIf(!invoker.isRoundChambered() && pressingReload() && countinv(invoker.getShellAmmo(invoker.getSelectedShellType())), "rackreload");
            loop;

        rackreload:
            #### S 1 offset(-1, 35) A_WeaponBusy(true);
            #### S 2 offset(-2, 37);
            #### S 4 offset(-3, 40);
            #### S 1 offset(-4, 42);
            #### S 6 offset(-5, 43) A_GrabShells(1, true, true);
            #### S 6 offset(-4, 41) A_StartSound("weapons/pocket",9);
        rackloadone:
            #### S 1 offset(-4, 42);
            #### S 2 offset(-4, 41);
            #### S 3 offset(-4, 40) A_LoadChamberFromHand();
            #### S 5 offset(-4, 41);
            #### S 4 offset(-4, 40) A_JumpIf(invoker.getNumHandShells(), "rackloadone");
        rackreloadend:
            #### S 1 offset(-3, 39);
            #### S 1 offset(-2, 37);
            #### S 1 offset(-1, 34);
            #### S 0 A_WeaponBusy(false);
            goto racked;

        rackunload:
            #### S 1 offset(-1, 35) A_WeaponBusy(true);
            #### S 2 offset(-2, 37);
            #### S 4 offset(-3, 40);
            #### S 1 offset(-4, 42);
            #### S 2 offset(-4, 41);
            #### S 3 offset(-4, 40) {
                let chm = invoker.isRoundChambered();

                if (invoker.isChamberedRoundLive()) {
                    A_AddToHand(invoker.removeChamberedRound());
                    A_EmptyHand(careful: true);
                } else if (chm) {
                    A_SpawnItemEx(
                        invoker.getSpentShell(invoker.removeChamberedRound()),
                        cos(pitch) * 8, 0, height - 7 - sin(pitch) * 8,
                        vel.x + cos(pitch) * cos(angle - random[uzwepsrand](86, 90)) * 5,
                        vel.y + cos(pitch) * sin(angle - random[uzwepsrand](86, 90)) * 5,
                        vel.z + sin(pitch) * random[uzwepsrand](4,6),
                        0,
                        SXF_ABSOLUTEMOMENTUM|SXF_NOCHECKPOSITION|SXF_TRANSFERPITCH
                    );
                }

                if (chm) A_StartSound(invoker.unloadChamberSound, 8, CHANF_OVERLAP);
            }
            #### S 5 offset(-4, 41);
            #### S 4 offset(-4, 40) A_JumpIf(invoker.getNumHandShells(), "rackloadone");
            goto rackreloadend;

        unrack:
            #### S 0 A_StartSound(invoker.rackFwdSound, 8);
            #### Q 2 A_JumpIf(!pressingFire(), 1);
            #### QA 2 {
                if (pressingFire()) A_SetTics(1);

                A_MuzzleClimb(0, -frandom[uzwepsrand](0.6, 1.0), wepdot: false);
            }
            #### A 0 A_ClearRefire();
            goto ready;

        flash:
            SPSF A 1 bright {
                A_Light2();
                HDFlashAlpha(-32);
                frame = invoker.getWepStatusFlag(SPASF_STOCK);
            }
            TNT1 A 1 A_ZoomRecoil(0.9);
            TNT1 A 0 A_Light0();
            TNT1 A 0 A_AlertMonsters();
            // TNT1 A 0 A_SPASRecoil();
            goto lightdone;
        
        semireload:
            #### A 1 offset(-1, 35) A_WeaponBusy(true);
            #### A 2 offset(-2, 37);
            #### A 4 offset(-3, 40);
            #### A 1 offset(-4, 42);
            #### A 6 offset(-5, 43) A_GrabShells(1, true, true);
            #### A 6 offset(-4, 41);
        semiloadone:
            #### A 1 offset(-4, 42);
            #### A 2 offset(-4, 41);
            #### A 3 offset(-4, 40) A_LoadChamberFromHand();
            #### A 5 offset(-4, 41);
            #### A 4 offset(-4, 40) A_WeaponBusy(false);
            goto ready;

        reload:
        startreload:
            #### A 0 A_JumpIf(!invoker.isRoundChambered() && invoker.getWepStatusFlag(SPASF_TUBELOCK), "semireload");
            #### A 1 A_JumpIf(invoker.isTubeFull() || !countinv(invoker.getShellAmmo(invoker.getSelectedShellType())), "nope");
            #### EGIK 2 A_MuzzleClimb(frandom[uzwepsrand](0.6, 0.7), -frandom[uzwepsrand](0.6, 0.7), wepdot: false);
        reloadstarthand:
            #### M 1 offset(0, 36);
            #### M 1 offset(0, 38);
            #### M 2 offset(0, 36);
            #### M 2 offset(0, 34);
            #### M 3 offset(0, 36);
            #### M 3 offset(0, 40);
        reloadpocket:
            #### M 3 offset(0, 39) A_GrabShells();
            #### M 5 offset(0, 42) A_StartSound("weapons/pocket", 9);
            #### M 6 offset(0, 41) A_StartSound("weapons/pocket", 9);
            #### M 4 offset(0, 40);
        reloadashell:
            #### M 2 offset(0, 36);
            #### M 4 offset(0, 34) A_LoadTubeFromHand();
            #### MMMMMM 1 offset(0, 33) {
                if (
                    !pressingReload()
                    || invoker.isTubeFull()
                    || (
                        !invoker.getNumHandShells()
                        && !countinv(getShellAmmo(invoker.getSelectedShellType()))
                    )
                ) {
                    setWeaponState("reloadend");
                } else if (!invoker.getNumHandShells()) {
                    setWeaponState("reloadstarthand");
                }
            }
            loop;

        reloadend:
            #### M 4 offset(0, 34) A_StartSound(invoker.openSound, 8, CHANF_OVERLAP);
            #### M 1 offset(0, 36) A_EmptyHand(careful: true);
            #### M 1 offset(0, 34);
            #### KIGEA 2;
            goto ready;

        altreload:
            // Simply return to ready,
            // the flag will be set there,
            // as well as allow pumping
            goto ready;

        unload:
            #### A 0 A_JumpIf(!((invoker.isRoundChambered() && !invoker.getWepStatusFlag(SPASF_FIREMODE)) || invoker.getNumTubeRounds()), "nope");
            #### EGIK 2 A_MuzzleClimb(frandom[uzwepsrand](1.2, 2.4), -frandom[uzwepsrand](1.2, 2.4), wepdot: false);
            #### M 1 offset(0, 34);
            #### M 1 offset(0, 36) A_StartSound(invoker.openSound, 8);
            #### M 1 offset(0, 38);
            #### O 8 offset(0, 36) {
                let mult = invoker.getStrengthMult();
                A_MuzzleClimb(-frandom[uzwepsrand](1.2, 2.4) * mult, frandom[uzwepsrand](1.2, 2.4) * mult, wepdot: false);

                if (!invoker.isRoundChambered() || invoker.getWepStatusFlag(SPASF_FIREMODE)) {
                    setWeaponState("unloadtube");
                } else {
                    A_StartSound(invoker.rackBakSound, 8, CHANF_OVERLAP);
                    A_SetTics(invoker.getStrengthTics(8));
                }
            }
            #### O 8 offset(0, 34) {
                let mult = invoker.getStrengthMult();
                A_MuzzleClimb(-frandom[uzwepsrand](1.2, 2.4) * mult, frandom[uzwepsrand](1.2, 2.4) * mult, wepdot: false);

                let live  = invoker.isChamberedRoundLive();
                let round = invoker.removeChamberedRound();

                if (live) {
                    A_StartSound(invoker.unloadChamberSound, 8, CHANF_OVERLAP);

                    if (A_JumpIfInventory(invoker.getShellAmmo(round), 0, "null")) {

                        A_EjectCasing(
                            invoker.getFumblingShell(round),
                            frandom(-1, 2),
                            live ? (frandom(0.2, 0.25), -frandom(5, 5.2), frandom(0, 0.15)) : (frandom(0.25, 0.3), -frandom(6, 6.5), frandom(0, 0.2)),
                            (0, 0, -2)
                        );
                    } else {
                        HDF.Give(self, invoker.getShellAmmo(round), 1);
                        A_StartSound("weapons/pocket", 9);
                        A_SetTics(5);
                    }
                } else if (round) {

                    A_EjectCasing(
                        invoker.getSpentShell(round),
                        frandom(-1, 2),
                        live ? (frandom(0.2, 0.25), -frandom(5, 5.2), frandom(0, 0.15)) : (frandom(0.25, 0.3), -frandom(6, 6.5), frandom(0, 0.2)),
                        (0, 0, -2)
                    );
                }
            }
            #### M 0 A_StartSound(invoker.rackFwdSound, 8);
            #### M 0 A_JumpIf(!pressingUnload(), "reloadend");
            #### M 4 offset(0, 40);
        unloadtube:
            #### M 6 offset(0, 40) A_EmptyHand(careful: true);
        unloadloop:
            #### M 8 offset(1, 41) {
                if (invoker.getNumTubeRounds() < 1) {
                    setWeaponState("reloadend");
                } else if (invoker.getNumHandShells() >= 3) {
                    setWeaponState("unloadloopend");
                } else {
                    A_AddToHand(invoker.popTubeRound());
                }
            }
            #### M 4 offset(0, 40) A_StartSound(invoker.reloadSound, 8);
            loop;
        unloadloopend:
            #### M 6 offset(1, 41);
            #### M 3 offset(1, 42) A_StartSound("weapons/pocket", 9);
            #### M 0 A_EmptyHand(careful: true);
            #### M 6 A_Jumpif(!pressingUnload(),"reloadend");
            goto unloadloop;
    }

    override void InitializeWepStats(bool idfa) {

        // Set tube size
        weaponStatus[HDC_SHOTS_TUBESIZE] = 5;
        
        // Pick a random starting Shell Type
        if (!weaponStatus[HDC_SHOTS_SHELLTYPE]) weaponStatus[HDC_SHOTS_SHELLTYPE] = random[uzwepsrand](1, HDC_SHELLTYPE_TOTAL);

        super.initializeWepStats(idfa);
    }

    override void loadoutConfigure(string input) {
        super.loadoutConfigure(input);

        // Start with specific Shell Type
        int shellType = getloadoutvar(input, "rounds", 1);
        if (shellType >= 0) {

            // Clear the current Chamber/Tube
            clearChamberedRound();
            weaponStatus[HDC_SHOTS_TUBE] = 0;
            
            // If set to a non-zero value,
            // clamp, set the selected round,
            // and fill the chamber/rube
            if (shellType) {
                shellType = clamp(shellType, 1, HDC_SHELLTYPE_TOTAL);
                
                weaponStatus[HDC_SHOTS_SHELLTYPE] = shellType;
                setChamberedRound(shellType);
                while (!isTubeFull()) pushTubeRound(shellType);
            }
        }

        // Select the starting firemode
        bool firemode = getloadoutvar(input, "firemode", 1);
        if (firemode >= 0) A_SetWepStatusFlags(SPASF_FIREMODE, firemode);
    }
}

enum spasstatus {

    // FROM HDCoreShotgun
    // ------------------
    // HDC_SHOTS_CHAMBER    = 1,    // Octal value of round in chamber, lowest two (right-most) bits reserved for loaded/live flags
    // HDC_SHOTS_TUBE       = 2,    // Octal Array of rounds in tube magazine
    // // SHOTS_SIDESADDLE  = 3,    // From HDShotgun
    // HDC_SHOTS_TUBESIZE   = 4,    // Number of rounds the tube magazine can hold
    // HDC_SHOTS_SHELLTYPE  = 5,    // The Octal value of the currently selected round to load from inventory

    // HDC_SHOTF_ALTHOLDING = 1,

    // HDC_SHOTCHAMBF_LIVE  = 1 << 31,
    
    SPASF_STOCK             = 2,    // Flag for whether the stock is extended
    SPASF_TUBELOCK          = 4,    // Flag for whether the tube chambers a round when pumped
    SPASF_FIREMODE          = 8     // Flag for whether the gun is in semi-auto mode
};

class UZSPASRandom : IdleDummy {
    states {
        spawn:
            TNT1 A 0 nodelay {
                let g = UZSPAS(spawn("UZSPAS", pos, ALLOW_REPLACE));

                if (!g) return;

                HDF.TransferSpecials(self, g, HDF.TS_ALL);

                g.A_SetWepStatusFlags(SPASF_FIREMODE, !!random[uzwepsrand](0, 2));

                let box = g.getShellBox(g.weaponStatus[HDC_SHOTS_SHELLTYPE]);

                if (!box) return;

                spawn(box, pos + (3, 0, 0), ALLOW_REPLACE);
            }
            stop;
    }
}
