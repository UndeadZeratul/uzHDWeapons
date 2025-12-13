class UZLandMines : HDGrenadethrower {
    default {
        weapon.selectionorder 1050;
        weapon.slotpriority 1.5;
        weapon.slotnumber 0;
        tag "$TAG_LANDMINE";
        hdgrenadethrower.ammotype "UZLandMineAmmo";
        hdgrenadethrower.throwtype "UZLandMine";
        hdgrenadethrower.spoontype "UZLandMineSpoon";
        hdgrenadethrower.wiretype "UZLandMineTripwireFrag";
        hdgrenadethrower.pinsound "misc/null";
        hdgrenadethrower.spoonsound "weapons/landmine/beep";
        // inventory.icon "LMAMA0";
    }

    override void DoEffect() {
        if(weaponstatus[0]&FRAGF_SPOONOFF) {
            weaponstatus[FRAGS_TIMER]++;

            if (owner.health < 1) TossLandMine(true);
        } else if (
            weaponstatus[0]&FRAGF_INHAND
            && weaponstatus[0]&FRAGF_PINOUT
            && owner.player.cmd.buttons&BT_ATTACK
        ) {
            return;
        }

        super.doeffect();
    }
    
    override string,double getpickupsprite() {
        return "LMAMA0", 0.6;
    }

    override string GetStatusIcon(){
        return (weaponstatus[0]&FRAGF_PINOUT) ? "LMINB0" : "LMINA0";
    }

    override void DrawHUDStuff(HDStatusBar sb,HDWeapon hdw,HDPlayerPawn hpl) {
        let statusicon = GetStatusIcon();

        if (sb.hudlevel == 1) {
            sb.drawimage(
                statusicon,
                (-52, -4),
                sb.DI_SCREEN_CENTER_BOTTOM,
                scale: (0.6, 0.6)
            );
            sb.drawnum(hpl.countinv(grenadeammotype), -45, -8, sb.DI_SCREEN_CENTER_BOTTOM);
        }

        sb.drawwepnum(
            hpl.countinv(grenadeammotype),
            (HDCONST_MAXPOCKETSPACE / ENC_LANDMINE)
        );
        
        sb.drawwepnum(hdw.weaponstatus[FRAGS_FORCE], 50, posy: -10, alwaysprecise: true);
        
        if (!(hdw.weaponstatus[0]&FRAGF_SPOONOFF)) {
            sb.drawrect(-21, -19, 5, 4);

            if (!(hdw.weaponstatus[0]&FRAGF_PINOUT)) sb.drawrect(-25, -18, 3, 2);
        } else {
            int timer = hdw.weaponstatus[FRAGS_TIMER];
            if (timer % 3) sb.drawwepnum(140 - timer, 140, posy: -15, alwaysprecise: true);
        }

        // Draw the item and guide lines
        if (
            !(hdw.weaponstatus[0]&FRAGF_SPOONOFF)
            || level.time&1
        ) {
            sb.drawimage(
                statusicon,
                (0, 30 + (hdw.weaponstatus[FRAGS_HOLDINGFIRE] << 2)) + hpl.wepbob,
                sb.DI_SCREEN_CENTER|sb.DI_ITEM_CENTER,
                alpha: (hdw.weaponstatus[0]&FRAGF_INHAND) || hpl.countinv("UZPipeBombAmmo") ? 1.0 : 0.3,
                scale: (1.2,1.2)
            );
        }

        if (hdw.weaponstatus[FRAGS_FORCE] > 0) {
            for (int i = hdw.weaponstatus[FRAGS_FORCE]; i > 0; i--) {
                if (i&(1|2|4)) continue;

                sb.drawrect(25, -30 - (i << 1), 8, 0.5);
                sb.drawrect(-25, -30 - (i << 1), -8, 0.5);
            }
        }
    }

    override string gethelptext() {
        LocalizeHelp();
        return 
            LWPHELP_FIRE.."  Activate & wind up (release to throw)\n"
            ..LWPHELP_RELOAD.."  Deactivate & cancel throw"
            ;
    }

    override void ForceBasicAmmo() {
        owner.A_SetInventory("UZLandMineAmmo", 1);
    }

    //we need to start from the inventory itself so it can go into DoEffect
    action void A_TossLandMine(bool oshit = false) {
        invoker.TossLandMine(oshit);
        A_SetHelpText();
    }

    void TossLandMine(bool oshit = false) {
        if (!owner) return;

        int garbage;
        Actor ggg;
        double cpp = cos(owner.pitch);
        double spp = sin(owner.pitch);

        //create the land mine
        [garbage, ggg] = owner.A_SpawnItemEx(
            throwtype,
            0, 0, owner.height * 0.88,
            cpp * 4, 0, -spp * 4,
            0,
            SXF_NOCHECKPOSITION|SXF_TRANSFERPITCH|SXF_SETMASTER
        );
        ggg.vel += owner.vel;

        //force calculation
        double gforce = clamp(weaponstatus[FRAGS_FORCE] * 0.5, 1, 40 + owner.health * 0.1);
        if (oshit) gforce = min(gforce, frandom(4, 20));
        if (hdplayerpawn(owner)) gforce *= hdplayerpawn(owner).strength;

        let bomb = UZLandMine(ggg);
        if (!bomb) return;
        
        if (owner.player) bomb.vel += SwingThrow() * gforce;
        bomb.a_changevelocity(
            cpp * gforce * 0.6,
            0,
            -spp * gforce * 0.6,
            CVF_RELATIVE
        );

        // Reset Weapon Status
        weaponstatus[0] &= ~FRAGF_PINOUT;
        weaponstatus[0] &= ~FRAGF_SPOONOFF;
        weaponstatus[0] &= ~FRAGF_INHAND;
        weaponstatus[0] |= FRAGF_JUSTTHREW;
        weaponstatus[FRAGS_TIMER] = 0;
        weaponstatus[FRAGS_FORCE] = 0;
        weaponstatus[FRAGS_REALLYPULL] = 0;
    }

    states {
        ready:
            TNT1 A 0 {
                invoker.weaponstatus[FRAGS_FORCE] = 0;
                invoker.weaponstatus[FRAGS_REALLYPULL] = 0;

                A_SetHelpText();
            }
            TNT1 A 1 A_WeaponReady(WRF_ALLOWRELOAD|WRF_ALLOWUSER1|WRF_ALLOWUSER2|WRF_ALLOWUSER3|WRF_ALLOWUSER4);
            goto ready3;

        deselectinstant:
            TNT1 A -1 A_TakeInventory("UZLandMines", 1);
            stop;

        zoom:
            goto ready;

        startpull:
            TNT1 A 0 A_JumpIf(invoker.weaponstatus[FRAGS_REALLYPULL] >= 26, 'endpull');
            TNT1 A 1 {
                invoker.weaponstatus[FRAGS_REALLYPULL]++;
            }
            TNT1 A 0 A_Refire();
            goto ready;

        endpull:
            TNT1 A 1 offset(0, 34);
            TNT1 A 0;
            TNT1 A 0 A_PullPin();
            TNT1 A 0 A_Refire();
            goto ready;

        fire:
            TNT1 A 0 A_JumpIf(NoFrags(), "nope");
            TNT1 A 0 A_JumpIf(invoker.weaponstatus[0]&FRAGF_JUSTTHREW, "nope");
            TNT1 A 0 A_JumpIfInventory("PowerStrength", 1, 3);
            TNT1 A 1 offset(0, 34);
            TNT1 A 1 offset(0, 36);
            TNT1 A 1 offset(0, 38);
            TNT1 A 0 A_Refire();
            goto ready;

        hold:
            TNT1 A 0 A_JumpIf(NoFrags(), "nope");
            TNT1 A 0 A_JumpIf(invoker.weaponstatus[0]&FRAGF_JUSTTHREW, "nope");
            //TNT1 A 0 A_JumpIf(invoker.weaponstatus[0]&FRAGF_PINOUT,"hold2");
            TNT1 A 0 A_JumpIf(invoker.weaponstatus[FRAGS_FORCE] >= 1, "hold2");
            TNT1 A 0 A_JumpIfInventory("PowerStrength", 1, 1);
            TNT1 A 3 A_PullPin();
        hold2:
            TNT1 A 0 A_JumpIf(NoFrags(), "nope");
            TNT1 A 0 A_JumpIf(invoker.weaponstatus[FRAGS_FORCE] >= 40, "hold3a");
            TNT1 A 0 A_JumpIf(invoker.weaponstatus[FRAGS_FORCE] >= 30, "hold3a");
            TNT1 A 0 A_JumpIf(invoker.weaponstatus[FRAGS_FORCE] >= 20, "hold3");
            TNT1 A 0 A_JumpIf(invoker.weaponstatus[FRAGS_FORCE] >= 10, "hold3");
            goto hold3;
        hold3a:
            TNT1 # 0 {
                if (invoker.weaponstatus[FRAGS_FORCE] < 50) invoker.weaponstatus[FRAGS_FORCE]++;
            }
        hold3:
            TNT1 # 1 {
                A_WeaponReady(invoker.weaponstatus[0]&FRAGF_SPOONOFF ? WRF_NOFIRE : WRF_NOFIRE|WRF_ALLOWRELOAD);

                if (invoker.weaponstatus[FRAGS_FORCE] < 50) invoker.weaponstatus[FRAGS_FORCE]++;
            }
            TNT1 A 0 A_Refire();
        throw:
            TNT1 A 0 A_JumpIf(NoFrags(), "nope");
            TNT1 A 1 offset(0, 34) A_TossLandMine();
            TNT1 A 1 offset(0, 38);
            TNT1 A 1 offset(0, 48);
            TNT1 A 1 offset(0, 52);
            TNT1 A 0 A_Refire();
            goto ready;

        reload:
            TNT1 A 0 A_JumpIf(NoFrags(), "nope");
            TNT1 A 0 A_JumpIf(invoker.weaponstatus[FRAGS_FORCE] >= 1, "pinbackin");
            TNT1 A 0 A_JumpIf(invoker.weaponstatus[0]&FRAGF_PINOUT, "altpinbackin");
            goto ready;

        pinbackin:
            TNT1 A 1 offset(0, 34) A_ReturnHandToOwner();
            TNT1 A 1 offset(0, 36);
            TNT1 A 1 offset(0, 38);
        altpinbackin:
            TNT1 A 0 A_JumpIf(invoker.weaponstatus[FRAGS_TIMER] > 0, "juststopthrowing");
            TNT1 A 1 A_ReturnHandToOwner();
            TNT1 A 0 A_Refire("nope");
            TNT1 A 1 offset(0, 38);
            TNT1 A 1 offset(0, 36);
            TNT1 A 1 offset(0, 34);
            goto ready;
    }
}

// TODO: Remove?
class UZLandMineTripwireFrag : Tripwire {
    default {
        weapon.selectionorder 1011;
        tripwire.ammotype "UZLandMineAmmo";
        tripwire.throwtype "UZLandMineTrippingFrag";
        tripwire.spoontype "UZLandMineSpoon";
        tripwire.weptype "UZLandMines";
    }

    override void DrawHUDStuff(HDStatusBar sb, HDWeapon hdw, HDPlayerPawn hpl) {
        if (sb.hudlevel == 1) {
            sb.drawimage(
                "LMAMA0",
                (-52, -4),
                sb.DI_SCREEN_CENTER_BOTTOM,
                scale: (0.6, 0.6)
            );
            sb.drawnum(hpl.countinv("UZLandMineAmmo"), -45, -8, sb.DI_SCREEN_CENTER_BOTTOM);
        }

        sb.drawwepnum(
            hpl.countinv("UZLandMineAmmo"),
            (ENC_FRAG / HDCONST_MAXPOCKETSPACE)
        );

        sb.drawwepnum(hdw.weaponstatus[FRAGS_FORCE], 50, posy: -10, alwaysprecise: true);

        if (!(hdw.weaponstatus[0]&FRAGF_SPOONOFF)) {
            sb.drawrect(-21, -19, 5, 4);

            if (!(hdw.weaponstatus[0]&FRAGF_PINOUT)) sb.drawrect(-25, -18, 3, 2);
        } else {
            int timer = hdw.weaponstatus[FRAGS_TIMER];
            if (timer % 3) sb.drawwepnum(140 - timer, 140, posy: -15, alwaysprecise: true);
        }
    }
}

// TODO: Remove?
class UZLandMineTrippingFrag : TrippingGrenade {
    default {
        //$Category "Misc/Hideous Destructor/Traps"
        //$Title "Tripwire Grenade"
        //$Sprite "FRAGA0"

        scale 0.4;
        trippinggrenade.rollertype "UZLandMineRoller";
        trippinggrenade.spoontype "UZLandMineSpoon";
        trippinggrenade.droptype "UZLandMineAmmo";
        hdupk.pickuptype "UZLandMineAmmo";
    }
    
    override void postbeginplay() {
        super.postbeginplay();

        pickupmessage = getdefaultbytype("UZLandMineAmmo").pickupmessage();
    }

    states {
        spawn:
            LMAM A 1 nodelay A_TrackStuckHeight();
            wait;
    }
}

class UZLandMineRoller : HDFragGrenadeRoller {

    bool steppedOn;
    bool primed;

    default {
        health 20;

        height 8;
        radius 8;

        scale 0.5;
        radiusdamagefactor 0.04;
        pushfactor 1.4;
        maxstepheight 2;
        mass 500;
        
        obituary "$OB_LANDMINE";
    }
    
    override void tick() {
        if (isfrozen()) return;

        if (health < 1) {
            A_Detonate();
            destroy();
            return;
        }

        if (bnointeraction) {
            NextTic();
            return;
        }

        // Update the frame to "animate" it beeping
        if (primed) frame = (Level.time % 12) < 6;

        // Reset the "Fuze"
        fuze = 0;

        let currentlySteppedOn = false;

        foreach (mo : BlockThingsIterator.Create(self, 128)) {

            // If the thing doesn't exist,
            // or is the mine itself,
            // or is another mine,
            // or isn't a player or another mob,
            // skip.
            if (!mo
                || mo == self
                || mo.GetClassName() == GetClassName()
                || !(mo is 'HDPlayerPawn' || mo is 'HDMobBase')
            ) continue;

            
            // If that thing is standing on top of the mine, prime for detonation.
            if (
                mo.pos.z >= pos.z
                && mo.pos.z <= pos.z + height
                && Distance2D(mo) < radius + mo.radius
            ) {
                if (!steppedOn) A_StartSound("weapons/LandMine/Arm");

                currentlySteppedOn = true;
                primed = true;

                break;
            }
        }

        // store whether currently being stepped on
        steppedOn = currentlySteppedOn;

        // If we're not detonating, but we are primed and no longer being stepped on, detonate.
        if (!steppedOn && primed && !instatesequence(curstate, resolvestate("detonate"))) {
            SetStateLabel("detonate");
        }

        super.tick();
    }

    override bool used(actor user) {
        let hdp = HDPlayerPawn(user);
        if (hdp && hdp.player && hdp.player.crouchfactor < 0.6) {
            user.giveInventory('UZLandMineAmmo', 1);
            hdp.A_Log(StringTable.localize("$PICKUP_LANDMINE_DEACTIVATE"), true);
            destroy();
        } else {
            primed = true;
        }

        return true;
    }

    action void A_Detonate() {
        UZLandMine.detonate(invoker);
    }

    states {
        spawn:
            LMIN A 1;
        spawn2:
            #### # 2 {
                if (abs(vel.z - keeprolling.z) > 10) {
                    A_StartSound("weapons/landmine/bounce", CHAN_BODY);
                } else if (floorz >= pos.z) {
                    A_StartSound("misc/fragroll");
                }

                keeprolling = vel;

                if (abs(vel.x) < 0.4 && abs(vel.y) < 0.4) {
                    setstatelabel("death");
                }
            }
            loop;

        bounce:
            #### # 0 {
                bmissile = false;
                vel *= 0.2;
            }
            goto spawn2;

        death:
            #### # 2 {
                if (abs(vel.z - keeprolling.z) > 3) {
                    A_StartSound("weapons/landmine/bounce", CHAN_BODY);
                    keeprolling = vel;
                }

                if (abs(vel.x) > 0.4 || abs(vel.y) > 0.4) {
                    setstatelabel("spawn");
                }
            }
            wait;
        detonate:
            #### B 8 A_StartSound("weapons/landmine/beep");
            TNT1 A 0 A_Detonate();
            stop;
    }
}

class UZLandMine : HDFragGrenade {
    default {
        +ROLLSPRITE;
        +ROLLCENTER;
        +SHOOTABLE;
        +NOBLOOD;
        +NOTARGET;
        +NOTAUTOAIMED;
        +DONTTHRUST;

        health 20;

        height 8;
        radius 8;

        scale 0.5;
        obituary "$OB_LANDMINE";
        hdfraggrenade.rollertype "UZLandMineRoller";
        Mass 1500;
    }

    override void tick() {
        if (health < 1) {
            UZLandMine.detonate(self);
            destroy();
            return;
        }

        frame = (Level.time % 12) < 6;

        super.tick();
    }

    action void A_Detonate() {
        UZLandMine.detonate(invoker);
    }

    static void detonate(HDActor caller) {
        caller.bSOLID         = false;
        caller.bPUSHABLE      = false;
        caller.bMISSILE       = false;
        caller.bNOINTERACTION = true;
        caller.bSHOOTABLE     = false;

        caller.A_HDBlast(
            pushradius: 256,
            pushamount: 118,
            fullpushradius: 96,
            fragradius: 300
        );

        DistantQuaker.Quake(caller, 4, 35, 512, 10);

        caller.A_StartSound("world/explode", CHAN_AUTO);
        caller.A_AlertMonsters();

        actor xpl = spawn("WallChunker", caller.pos - (0, 0, 1), ALLOW_REPLACE);
        xpl.target = caller.target;
        xpl.master = caller.master;
        xpl.stamina = caller.stamina;

        xpl = spawn("HDExplosion", caller.pos - (0, 0, 1), ALLOW_REPLACE);
        xpl.target = caller.target;
        xpl.master = caller.master;
        xpl.stamina = caller.stamina;

        caller.A_SpawnChunks("BigWallChunk", 14, 4, 12);
        caller.A_SpawnChunks("HDB_frag", 42, 300, 700);

        DistantNoise.make(caller, "world/rocketfar");
    }

    states {
        spawn:
            LMIN A 1;
            loop;
        detonate:
            #### B 12 A_StartSound("weapons/LandMine/beep");
            TNT1 A 1 A_Detonate();
            stop;
    }
}

class UZLandMineAmmo : HDAmmo {
    default {
        //+forcexybillboard
        inventory.icon "LMAMA0";
        inventory.amount 1;
        scale 0.3;
        inventory.maxamount 50;
        inventory.pickupmessage "$PICKUP_LANDMINE";
        inventory.pickupsound "weapons/pocket";
        tag "$TAG_LANDMINE";
        hdpickup.refid UZLD_LANDMINE;
        hdpickup.bulk ENC_LANDMINE;
        +INVENTORY.KEEPDEPLETED
    }

    override bool IsUsed() {
        return true;
    }

    override void AttachToOwner(Actor user) {
        user.GiveInventory("UZLandMines", 1);

        super.AttachToOwner(user);
    }

    override void DetachFromOwner() {
        if(owner && owner.player && !(owner.player.ReadyWeapon is "UZLandMines")) {
            owner.TakeInventory("UZLandMines", 1);
        }

        super.DetachFromOwner();
    }

    states {
        spawn:
            LMAM A -1;
            stop;
    }
}

// TODO: Remove?
class UZLandMineSpoon : HDFragSpoon {
    default {
        Scale 0.45;
    }

    override void PostBeginPlay() {
        HDDebris.PostBeginPlay();
    }

    states {
        spawn:
            TNT1 A 0;
            stop;
    }
}

class UZLandMinePickup : HDUPK {
    default {
        //+forcexybillboard
        scale 0.4;
        height 6;
        radius 6;

        hdupk.amount 1;
        hdupk.pickuptype "UZLandMineAmmo";
        hdupk.pickupmessage "$PICKUP_LANDMINE";
        hdupk.pickupsound "weapons/rifleclick2";

        stamina 1;
    }

    states {
        spawn:
            LMAM A -1;
    }
}

class UZLandMineBoxPickup : HDUPK {
    default {
        //+forcexybillboard
        scale 0.4;
        height 6;
        radius 6;

        hdupk.amount 6;
        hdupk.pickuptype "UZLandMineAmmo";
        hdupk.pickupmessage "$PICKUP_LANDMINE_BOX";
        hdupk.pickupsound "weapons/rifleclick2";

        stamina 1;
    }

    states {
        spawn:
            LMAM B -1;
    }
}
