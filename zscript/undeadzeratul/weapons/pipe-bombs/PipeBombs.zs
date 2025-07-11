class UZPipeBombs : HDGrenadethrower {
    default {
        weapon.selectionorder 1050;
        weapon.slotpriority 1.5;
        weapon.slotnumber 0;
        tag "$TAG_PIPEBOMB";
        hdgrenadethrower.ammotype "UZPipeBombAmmo";
        hdgrenadethrower.throwtype "UZPipeBomb";
        hdgrenadethrower.spoontype "UZPipeBombSpoon";
        hdgrenadethrower.wiretype "UZPipeBombTripwireFrag";
        hdgrenadethrower.pinsound "weapons/pipebomb/arm";
        inventory.icon "PIPPA0";
    }

    override string gethelptext() {
        LocalizeHelp();
        return 
            LWPHELP_FIRE.."  Activate & wind up (release to throw)\n"
            ..(
                owner.countinv("UZPipeBombDetonator")
                    ? LWPHELP_ALTFIRE.."  Detonate all activated pipe bombs\n"
                    : "\c[DarkGray]"..StringTable.Localize("$WPHALTFIRE")..WEPHELP_RGCOL.."  DETONATOR REQUIRED\n"
            )
            ..LWPHELP_RELOAD.."  Deactivate & cancel throw"
            ;
    }

    action bool NoPipeBombs() {
        return NoFrags() && !invoker.owner.countInv("UZPipeBombDetonator");
    }

    override void DoEffect() {
        if(weaponstatus[0]&FRAGF_SPOONOFF) {
            weaponstatus[FRAGS_TIMER]++;

            if (owner.health < 1) TossPipeBomb(true);
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
        return "PIPPA0", 0.6;
    }

    override void DrawHUDStuff(HDStatusBar sb,HDWeapon hdw,HDPlayerPawn hpl) {
        if (sb.hudlevel == 1) {
            if (hpl.countInv('UZPipeBombDetonator')) {
                sb.drawimage(
                    "PBDPA0",
                    (-72, -4),
                    sb.DI_SCREEN_CENTER_BOTTOM|sb.DI_ITEM_CENTER_BOTTOM,
                    scale: (0.6, 0.6)
                );
            }

            sb.drawimage(
                "PIPPA0",
                (-52, -4),
                sb.DI_SCREEN_CENTER_BOTTOM,
                scale: (0.6, 0.6)
            );
            sb.drawnum(hpl.countinv("UZPipeBombAmmo"), -45, -8, sb.DI_SCREEN_CENTER_BOTTOM);
        }

        sb.drawwepnum(
            hpl.countinv("UZPipeBombAmmo"),
            (HDCONST_MAXPOCKETSPACE / ENC_PIPEBOMBS)
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

    override void ForceBasicAmmo() {
        owner.A_SetInventory("UZPipeBombAmmo", 1);
    }

    //we need to start from the inventory itself so it can go into DoEffect
    action void A_TossPipeBomb(bool oshit = false) {
        invoker.TossPipeBomb(oshit);
        A_SetHelpText();
    }

    void TossPipeBomb(bool oshit = false) {
        if (!owner) return;

        int garbage;
        Actor ggg;
        double cpp = cos(owner.pitch);
        double spp = sin(owner.pitch);

        //create the pipe bomb
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

        let bomb = UZPipeBomb(ggg);
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

    action void A_DetonatePipeBombs() {
        let it = ThinkerIterator.create("UZPipeBombRoller");
        UZPipeBombRoller roller;
        while (roller = UZPipeBombRoller(it.Next())) if (roller.master == invoker.owner) roller.SetStateLabel("Destroy");
        
        it = ThinkerIterator.create("UZPipeBomb");
        UZPipeBomb bomb;
        while (bomb = UZPipeBomb(it.Next())) if (bomb.master == invoker.owner) bomb.SetStateLabel("Destroy");
    }

    states {
        ready:
            FRGG B 0 {
                invoker.weaponstatus[FRAGS_FORCE] = 0;
                invoker.weaponstatus[FRAGS_REALLYPULL] = 0;

                A_SetHelpText();
            }
            FRGG B 1 A_WeaponReady(WRF_ALLOWRELOAD|WRF_ALLOWUSER1|WRF_ALLOWUSER2|WRF_ALLOWUSER3|WRF_ALLOWUSER4);
            goto ready3;

        deselectinstant:
            TNT1 A -1 A_TakeInventory("UZPipeBombs", 1);
            stop;

        zoom:
            goto ready;

        startpull:
            FRGG B 0 A_JumpIf(invoker.weaponstatus[FRAGS_REALLYPULL] >= 26, 'endpull');
            FRGG B 1 {
                invoker.weaponstatus[FRAGS_REALLYPULL]++;
            }
            FRGG B 0 A_Refire();
            goto ready;

        endpull:
            FRGG B 1 offset(0, 34);
            TNT1 A 0;
            TNT1 A 0 A_PullPin();
            TNT1 A 0 A_Refire();
            goto ready;

        fire:
            TNT1 A 0 A_JumpIf(NoPipeBombs(), "selectinstant");
            TNT1 A 0 A_JumpIf(NoFrags(), "nope");
            TNT1 A 0 A_JumpIf(invoker.weaponstatus[0]&FRAGF_JUSTTHREW, "nope");
            TNT1 A 0 A_JumpIfInventory("PowerStrength", 1, 3);
            FRGG B 1 offset(0, 34);
            FRGG B 1 offset(0, 36);
            FRGG B 1 offset(0, 38);
            TNT1 A 0 A_Refire();
            goto ready;

        hold:
            TNT1 A 0 A_JumpIf(NoPipeBombs(), "selectinstant");
            TNT1 A 0 A_JumpIf(NoFrags(), "nope");
            TNT1 A 0 A_JumpIf(invoker.weaponstatus[0]&FRAGF_JUSTTHREW, "nope");
            //TNT1 A 0 A_JumpIf(invoker.weaponstatus[0]&FRAGF_PINOUT,"hold2");
            TNT1 A 0 A_JumpIf(invoker.weaponstatus[FRAGS_FORCE] >= 1, "hold2");
            TNT1 A 0 A_JumpIfInventory("PowerStrength", 1, 1);
            TNT1 A 3 A_PullPin();
        hold2:
            TNT1 A 0 A_JumpIf(NoPipeBombs(),"selectinstant");
            TNT1 A 0 A_JumpIf(NoFrags(), "nope");
            FRGG E 0 A_JumpIf(invoker.weaponstatus[FRAGS_FORCE] >= 40, "hold3a");
            FRGG D 0 A_JumpIf(invoker.weaponstatus[FRAGS_FORCE] >= 30, "hold3a");
            FRGG C 0 A_JumpIf(invoker.weaponstatus[FRAGS_FORCE] >= 20, "hold3");
            FRGG B 0 A_JumpIf(invoker.weaponstatus[FRAGS_FORCE] >= 10, "hold3");
            goto hold3;
        hold3a:
            FRGG # 0 {
                if (invoker.weaponstatus[FRAGS_FORCE] < 50) invoker.weaponstatus[FRAGS_FORCE]++;
            }
        hold3:
            FRGG # 1 {
                A_WeaponReady(invoker.weaponstatus[0]&FRAGF_SPOONOFF ? WRF_NOFIRE : WRF_NOFIRE|WRF_ALLOWRELOAD);

                if (invoker.weaponstatus[FRAGS_FORCE] < 50) invoker.weaponstatus[FRAGS_FORCE]++;
            }
            TNT1 A 0 A_Refire();
        throw:
            TNT1 A 0 A_JumpIf(NoPipeBombs(), "selectinstant");
            TNT1 A 0 A_JumpIf(NoFrags(), "nope");
            FRGG A 1 offset(0, 34) A_TossPipeBomb();
            FRGG A 1 offset(0, 38);
            FRGG A 1 offset(0, 48);
            FRGG A 1 offset(0, 52);
            FRGG A 0 A_Refire();
            goto ready;

        altfire:
            #### A 0 A_JumpIf(!invoker.owner.countinv("UZPipeBombDetonator"), "ready");
        begindetonate:
            PIPD A 1 offset(0, 96);
            #### A 1 offset(0, 64);
            #### A 1 offset(0, 52);
            #### A 2 offset(0, 48);
            #### A 2 offset(0, 38);
            #### A 2 offset(0, 34);
            #### B 4 offset(0, 34);
        althold:
            #### C 0 A_JumpIf(!invoker.owner.countinv("UZPipeBombDetonator"), "ready");
            #### C 0 A_JumpIf(!PressingAltfire(), "enddetonate");
            #### C 8 offset(0, 34) A_DetonatePipeBombs();
            loop;
        enddetonate:
            #### B 4 offset(0, 34);
            #### A 2 offset(0, 34);
            #### A 2 offset(0, 38);
            #### A 2 offset(0, 48);
            #### A 1 offset(0, 52);
            #### A 1 offset(0, 64);
            #### A 1 offset(0, 96);
            goto ready;


        reload:
            TNT1 A 0 A_JumpIf(NoPipeBombs(), "selectinstant");
            TNT1 A 0 A_JumpIf(NoFrags(), "nope");
            TNT1 A 0 A_JumpIf(invoker.weaponstatus[FRAGS_FORCE] >= 1, "pinbackin");
            TNT1 A 0 A_JumpIf(invoker.weaponstatus[0]&FRAGF_PINOUT, "altpinbackin");
            goto ready;

        pinbackin:
            FRGG B 1 offset(0, 34) A_ReturnHandToOwner();
            FRGG B 1 offset(0, 36);
            FRGG B 1 offset(0, 38);
        altpinbackin:
            FRGG A 0 A_JumpIf(invoker.weaponstatus[FRAGS_TIMER] > 0, "juststopthrowing");
            TNT1 A 1 A_ReturnHandToOwner();
            TNT1 A 0 A_Refire("nope");
            FRGG B 1 offset(0, 38);
            FRGG B 1 offset(0, 36);
            FRGG B 1 offset(0, 34);
            goto ready;
    }
}

// TODO: Remove?
class UZPipeBombTripwireFrag : Tripwire {
    default {
        weapon.selectionorder 1011;
        tripwire.ammotype "UZPipeBombAmmo";
        tripwire.throwtype "UZPipeBombTrippingFrag";
        tripwire.spoontype "UZPipeBombSpoon";
        tripwire.weptype "UZPipeBombs";
    }

    override void DrawHUDStuff(HDStatusBar sb, HDWeapon hdw, HDPlayerPawn hpl) {
        if (sb.hudlevel == 1) {
            sb.drawimage(
                "PIPPA0",
                (-52, -4),
                sb.DI_SCREEN_CENTER_BOTTOM,
                scale: (0.6, 0.6)
            );
            sb.drawnum(hpl.countinv("UZPipeBombAmmo"), -45, -8, sb.DI_SCREEN_CENTER_BOTTOM);
        }

        sb.drawwepnum(
            hpl.countinv("UZPipeBombAmmo"),
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
class UZPipeBombTrippingFrag : TrippingGrenade {
    default {
        //$Category "Misc/Hideous Destructor/Traps"
        //$Title "Tripwire Grenade"
        //$Sprite "FRAGA0"

        scale 0.4;
        trippinggrenade.rollertype "UZPipeBombRoller";
        trippinggrenade.spoontype "UZPipeBombSpoon";
        trippinggrenade.droptype "UZPipeBombAmmo";
        hdupk.pickuptype "UZPipeBombAmmo";
    }
    
    override void postbeginplay() {
        super.postbeginplay();

        pickupmessage = getdefaultbytype("UZPipeBombAmmo").pickupmessage();
    }

    states {
        spawn:
            PIPP A 1 nodelay A_TrackStuckHeight();
            wait;
    }
}

class UZPipeBombRoller : HDFragGrenadeRoller {
    default {
        health 20;

        height 8;
        radius 8;

        scale 0.2;
        radiusdamagefactor 0.04;
        pushfactor 1.4;
        maxstepheight 2;
        mass 500;
        
        obituary "$OB_PIPEBOMB";
    }
    
    override void tick() {
        if (isfrozen()) return;

        if (health < 1) {
            UZPipeBomb.detonate(self);
            destroy();
            return;
        }

        if (bnointeraction) {
            NextTic();
            return;
        }

        // Reset the "Fuze"
        fuze = 0;

        super.tick();
    }

    override bool used(actor user) {
        let hdp = HDPlayerPawn(user);
        if (hdp && hdp.player && hdp.player.crouchfactor < 0.6) {
            user.giveInventory('UZPipeBombAmmo', 1);
            hdp.A_Log(StringTable.localize("$PICKUP_PIPEBOMB_DEACTIVATE"), true);
            destroy();

            return true;
        }

        return super.used(user);
    }

    action void A_Detonate() {
        UZPipeBomb.detonate(invoker);
    }

    states {
        spawn:
            PIPB A 0 nodelay {
                HDMobAI.Frighten(self, 512);
            }
        spawn2:
            #### A 2 {
                if (abs(vel.z - keeprolling.z) > 10) {
                    A_StartSound("weapons/pipebomb/bounce", CHAN_BODY);
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
            ---- A 0 {
                bmissile = false;
                vel *= 0.3;
            }
            goto spawn2;

        death:
            ---- A 2 {
                if (abs(vel.z - keeprolling.z) > 3) {
                    A_StartSound("weapons/pipebomb/bounce", CHAN_BODY);
                    keeprolling = vel;
                }

                if (abs(vel.x) > 0.4 || abs(vel.y) > 0.4) {
                    setstatelabel("spawn");
                }
            }
            wait;
        destroy:
            TNT1 A 1 A_Detonate();
            stop;
    }
}

class UZPipeBomb : HDFragGrenade {
    default {
        +ROLLSPRITE;
        +ROLLCENTER;

        health 20;

        height 8;
        radius 8;

        scale 0.2;
        obituary "$OB_PIPEBOMB";
        hdfraggrenade.rollertype "UZPipeBombRoller";
        Mass 1500;
    }

    override void tick() {
        if (health < 1) {
            UZPipeBomb.detonate(self);
            destroy();
            return;
        }

        super.tick();
    }

    action void A_Detonate() {
        UZPipeBomb.detonate(invoker);
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
            PIPB A 2 {
                roll += 33;

                HDMobAI.Frighten(self, 512);
            }
            loop;
        destroy:
            TNT1 A 1 A_Detonate();
            stop;
    }
}

class UZPipeBombDetonator : HDPickup {
    default {
        inventory.icon "PBDPA0";
        inventory.amount 1;
        scale 0.25;
        inventory.maxamount 1;
        inventory.pickupmessage "$PICKUP_PIPEBOMB_DETONATOR";
        inventory.pickupsound "weapons/pocket";
        tag "$TAG_PIPEBOMB_DETONATOR";
        hdpickup.refid UZLD_PIPEBOMB_DETONATOR;
        hdpickup.bulk ENC_PIPEBOMB_DETONATOR;
    }

    states {
        spawn:
            PBDP A -1;
            stop;
    }
}

class UZPipeBombAmmo : HDAmmo {
    default {
        //+forcexybillboard
        inventory.icon "PIPPA0";
        inventory.amount 1;
        scale 0.3;
        inventory.maxamount 50;
        inventory.pickupmessage "$PICKUP_PIPEBOMB";
        inventory.pickupsound "weapons/pocket";
        tag "$TAG_PIPEBOMB";
        hdpickup.refid UZLD_PIPEBOMBS;
        hdpickup.bulk ENC_PIPEBOMBS;
        +INVENTORY.KEEPDEPLETED
    }

    override bool IsUsed() {
        return true;
    }

    override void AttachToOwner(Actor user) {
        user.GiveInventory("UZPipeBombs", 1);

        super.AttachToOwner(user);
    }

    override void DetachFromOwner() {
        if(owner && owner.player && !(owner.player.ReadyWeapon is "UZPipeBombs")) {
            owner.TakeInventory("UZPipeBombs", 1);
        }

        super.DetachFromOwner();
    }

    states {
        spawn:
            PIPP A -1;
            stop;
    }
}

// TODO: Remove?
class UZPipeBombSpoon : HDFragSpoon {
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

class UZPipeBombP : HDUPK {
    default {
        //+forcexybillboard
        scale 0.4;
        height 6;
        radius 6;

        hdupk.amount 1;
        hdupk.pickuptype "UZPipeBombAmmo";
        hdupk.pickupmessage "$PICKUP_PIPEBOMB";
        hdupk.pickupsound "weapons/rifleclick2";

        stamina 1;
    }

    states {
        spawn:
            PIPP A -1;
    }
}

class UZPipeBombPickup : UZPipeBombP {
    override void postbeginplay() {
        super.postbeginplay();

        A_SpawnItemEx("UZPipeBombP",  8, 8, flags: SXF_NOCHECKPOSITION);
        A_SpawnItemEx("UZPipeBombP",  8, 0, flags: SXF_NOCHECKPOSITION);
        A_SpawnItemEx("UZPipeBombP",  0, 8, flags: SXF_NOCHECKPOSITION);
        A_SpawnItemEx("UZPipeBombP", -8, 8, flags: SXF_NOCHECKPOSITION);
        A_SpawnItemEx("UZPipeBombP", -8, 0, flags: SXF_NOCHECKPOSITION);

        if (random[randpb]()) A_SpawnItemEx("UZPipeBombDetonator", 0, -8, flags: SXF_NOCHECKPOSITION);
    }
}
