class UZBHGen : HDWeapon {

    bool actualBlackHole;

    Default {
        //$Category "Weapons/Hideous Destructor"
        //$Title "Black Hold Generator"
        //$Sprite "BHGPA0"

        +HDWeapon.HINDERLEGS

        Weapon.SelectionOrder 99;
        Weapon.SlotNumber 7;
        Weapon.SlotPriority 2;
        Weapon.KickBack 999;
        Weapon.BobRangeX 0.5;
        Weapon.BobRangeY 1.2;
        Weapon.BobSpeed 1.5;

        scale 0.7;

        Inventory.PickupMessage "$PICKUP_BHG";
        Tag "$TAG_BHG";
        Obituary "$OB_BHG";

        HDWeapon.BarrelSize 32, 3.5, 7;
        HDWeapon.RefID UZLD_BHG;
    }

    static void Spark(Actor caller, int sparks = 1, double sparkHeight = 10.0) {
        Actor a;
        Vector3 spot;
        Vector3 origin = caller.pos + (0, 0, sparkHeight);
        double spp;
        double spa;
        for(int i = 0; i < sparks; i++) {
            spp = caller.pitch + frandom(-20, 20);
            spa = caller.angle + frandom(-20, 20);
            spot = random(24, 32) * (cos(spp) * cos(spa), cos(spp) * sin(spa), -sin(spp));
            a = caller.spawn("BHGSpark", origin + spot, ALLOW_REPLACE);
            a.vel += caller.vel * 0.9 - spot * 0.03;
        }
    }
    
    Actor ShootBall(Actor inflictor, Actor source) {
        inflictor.A_StartSound("bhg/fire", CHAN_WEAPON, CHANF_OVERLAP);

        weaponStatus[BHGS_CHARGE]  = 0;
        weaponStatus[BHGS_BATTERY] = 0;
        
		double shootAngle = inflictor.angle;
		double shootPitch = inflictor.pitch;
		vector3 shootPos  = (0, 0, 32);

		let hdp = HDPlayerPawn(inflictor);
		if (hdp) {
			shootAngle = hdp.gunAngle;
			shootPitch = hdp.gunPitch;
			shootPos   = hdp.gunPos;
		}

        FLineTraceData tlt;
        inflictor.LineTrace(
            shootAngle,
            8192,
            shootPitch,
            flags:         TRF_NOSKY|TRF_ABSOFFSET,
            offsetZ:       shootPos.z,
            offsetForward: shootPos.x,
            offsetSide:    shootPos.y,
            data:          tlt
        );

        let bbb = Spawn("BlackHole", GetBHSpawnPos(shootPos, tlt.hitLocation, shootAngle, shootPitch, tlt));
        if (bbb) {
            bbb.target = source;
            bbb.master = source;
            bbb.pitch  = shootPitch;
            bbb.angle  = shootAngle;
            bbb.vel    = (0, 0, 0);
        }

        return bbb;
    }

    private Vector3 GetBHSpawnPos(Vector3 shootPos, Vector3 targetPos, double angle, double pitch, FLineTraceData tData, int offset = 64) {
        let spawnPos = targetPos;

        switch (tData.hitType) {
            case TRACE_HitCeiling:
                spawnPos += (0, 0, -offset);
                break;
            case TRACE_HitFloor:
                spawnPos += (0, 0, offset);
                break;
            case TRACE_HitWall:
                spawnPos += ((-cos(angle) * offset, -sin(angle) * offset, 0));
                break;
            case TRACE_HitActor:
            case TRACE_HitNone:
            default:
                break;
        }

        return spawnPos;
    }

    override bool AddSpareWeapon(Actor newOwner) {
        return AddSpareWeaponRegular(newOwner);
    }

    override HDWeapon GetSpareWeapon(Actor newOwner, bool reverse, bool doSelect) {
        return GetSpareWeaponRegular(newOwner, reverse, doSelect);
    }

    override void DoEffect() {
        super.DoEffect();

        let hdp = HDPlayerPawn(owner);

        if (
            hdp
            && !!hdp.player
            && hdp.player.readyWeapon == self
            && !hdp.gunBraced
            && hdp.strength
        ) {
            // droop downwards
            if (hdp.pitch < 10) {
                hdp.A_MuzzleClimb(
                    (frandom(-0.06, 0.06), frandom(0.1, clamp(1 - pitch, 0.08 / hdp.strength, 0.12))),
                    (0, 0),
                    (0, 0),
                    (0, 0)
                );
            }
            
            // Wobble the more charged up we are
            let max = weaponStatus[BHGS_TIMER] * (0.0625 / max(1, hdp.strength));
            if (PressingFire() && max > 0) {
                hdp.A_MuzzleClimb(
                    (frandom(-max, max), frandom(-max, max)) * 0.5,
                    (frandom(-max, max), frandom(-max, max)) * 0.1,
                    (frandom(-max, max), frandom(-max, max)) * 0.05,
                    (frandom(-max, max), frandom(-max, max)) * 0.01
                );
            }
        }
    }

    override double gunmass() {
        return 15
            + (weaponStatus[BHGS_CHARGE] >= 0 ? 1 : 0)
            + (weaponStatus[BHGS_BATTERY] >= 0 ? 1 : 0)
        ;
    }

    override double weaponbulk() {
        return 240
            + (weaponStatus[BHGS_CHARGE] >= 0 ? ENC_BATTERY_LOADED : 0)
            + (weaponStatus[BHGS_BATTERY] >= 0 ? ENC_BATTERY_LOADED : 0)
        ;
    }

    override string, double getpickupsprite() {
        return "BHGPA0", 1.0;
    }

    override void DrawSightPicture(
        HDStatusBar sb, HDWeapon hdw, HDPlayerPawn hpl,
        bool sightBob, Vector2 bob, double fov, bool scopeView, actor hpc
    ) {
        // sb.drawimage(
        // 	"brfrntsit",(0,0)+bob*1.14,sb.DI_SCREEN_CENTER|sb.DI_ITEM_TOP
        // );

        if(scopeView) {
            double degree = 6.0;
            int scaledwidth = 50;
            int scaledyoffset = (scaledwidth >> 1) + 12;

            // Define Clip Rect
            int cx, cy, cw, ch;
            [cx,cy,cw,ch]=screen.GetClipRect();
            sb.SetClipRect(
                bob.x - (scaledwidth >> 1), bob.y + scaledyoffset - (scaledwidth >> 1),
                scaledwidth, scaledwidth,
                sb.DI_SCREEN_CENTER
            );

            sb.fill(color(255, 0, 0, 0),
                bob.x - 27, scaledyoffset + bob.y - 27,
                54, 54, sb.DI_SCREEN_CENTER|sb.DI_ITEM_CENTER
            );

            TexMan.SetCameraToTexture(hpc, "HDXCAM_BRON", degree);
            let cam = TexMan.CheckForTexture("HDXCAM_BRON", TexMan.Type_Any);
            double camSize = TexMan.GetSize(cam);
            sb.DrawCircle(cam, (0, scaledyoffset) + bob * 5, 0.085, usePixelRatio: true);


            screen.SetClipRect(cx,cy,cw,ch);

            sb.drawimage(
                "brret",
                (0, scaledyoffset) + bob,
                sb.DI_SCREEN_CENTER|sb.DI_ITEM_CENTER
            );
            sb.drawimage(
                "brontoscope",
                (0, scaledyoffset) + bob,
                sb.DI_SCREEN_CENTER|sb.DI_ITEM_CENTER
            );
        }
    }

    override void DrawHUDStuff(HDStatusBar sb,HDWeapon hdw,HDPlayerPawn hpl) {

        // Only fire an actual black hole on April 1st, because, well, reasons.
        EventHandler.SendNetworkEvent("IsActualBlackHole", SystemTime.Format("%m-%d", SystemTime.Now()) == "04-01");

        if (sb.hudlevel == 1) {
            sb.drawbattery(
                -54, -4,
                sb.DI_SCREEN_CENTER_BOTTOM,
                reloadorder: true
            );
            sb.drawnum(
                hpl.countinv("HDBattery"),
                -46, -8,
                sb.DI_SCREEN_CENTER_BOTTOM
            );
        }

        int bffb = hdw.weaponStatus[BHGS_BATTERY];
        if (bffb > 0) {
            sb.drawwepnum(bffb, 20, posy: -10);
        } else if (!bffb) {
            sb.drawstring(
                sb.mamountfont,
                "000000",
                (-16, -14),
                sb.DI_TEXT_ALIGN_RIGHT|sb.DI_TRANSLATABLE|sb.DI_SCREEN_CENTER_BOTTOM,
                Font.CR_DARKGRAY
            );
        }

        bffb = hdw.weaponStatus[BHGS_CHARGE];
        if (bffb > 0) {
            sb.drawwepnum(bffb, 20);
        } else if (!bffb) {
            sb.drawstring(
                sb.mamountfont,
                "000000",
                (-16, -7),
                sb.DI_TEXT_ALIGN_RIGHT|sb.DI_TRANSLATABLE|sb.DI_SCREEN_CENTER_BOTTOM,
                Font.CR_DARKGRAY
            );
        }
    }

    override string gethelptext() {
        LocalizeHelp();

        return LWPHELP_FIRE..StringTable.Localize("$BHGWH_FIRE")
            // ..LWPHELP_ALTFIRE..StringTable.Localize("$BHGWH_ALTFIRE")
            ..LWPHELP_RELOAD..StringTable.Localize("$BHGWH_RELOAD")
            // ..LWPHELP_ALTRELOAD..StringTable.Localize("$BHGWH_ALTRELOAD")
            ..LWPHELP_UNLOADUNLOAD
            // ..LWPHELP_USE.."+"..LWPHELP_UNLOAD..StringTable.Localize("$BHGWH_USEPUNL")
        ;
    }

    override void InitializeWepStats(bool idfa) {
        weaponStatus[BHGS_CHARGE] = 20;
        weaponStatus[BHGS_BATTERY] = 20;
        weaponStatus[BHGS_TIMER] = 0;
    }

    States {
        Ready:
            BHGG A 1 A_WeaponReady(WRF_ALL);
            goto ReadyEnd;

        Select0:
            BHGG A 0;
            goto Select0BFG;
        Deselect0:
            BHGG A 0;
            goto deselect0BFG;

        Spawn:
            BHGP A -1;
            Stop;

        Flash:
            BHGF A 3 Bright {
                A_Light2();
                HDFlashAlpha(0, true);
            }
            #### B 3 Bright {
                A_Light1();
                HDFlashAlpha(200);
            }
            #### C 3 Bright HDFlashAlpha(128);
            #### D 3 Bright;
            goto LightDone;

        Fire:
            #### A 0 {
                invoker.weaponStatus[BHGS_TIMER] = 0;
            }
        Hold:
            #### # 0 {
                if (
                    invoker.weaponStatus[BHGS_CHARGE] >= 20
                    && invoker.weaponStatus[BHGS_BATTERY] >= 20
                ) {
                    setweaponstate('ChargeEnd');
                } else {
                    setweaponstate('Nope');
                }
            }
        Charge:
            #### # 0 {
                if (
                    PressingReload()
                    || invoker.weaponStatus[BHGS_BATTERY] < 0
                    || (
                        invoker.weaponStatus[BHGS_CHARGE] >= 20
                        && invoker.weaponStatus[BHGS_BATTERY] >= 20
                    )
                ) {
                    setweaponstate('Nope');
                }
            }
            #### # 6 {
                invoker.weaponStatus[BHGS_TIMER]++;

                if (health < 40) {
                    A_SetTics(2);

                    if (health > 16) damagemobj(invoker, self, 1, "internal");
                } else if (invoker.weaponStatus[BHGS_BATTERY] == 20) {
                    A_SetTics(2);
                }

                UZBHGen.Spark(self, 1, gunheight() - 2);

                A_WeaponBusy(false);
                A_StartSound("weapons/bfgcharge", CHAN_WEAPON);
                A_WeaponReady(WRF_NOFIRE);
            }
            #### # 0 {
                if (invoker.weaponStatus[BHGS_CHARGE] == 20 && invoker.weaponStatus[BHGS_BATTERY] == 20) {
                    A_Refire("Shoot");
                } else {
                    A_Refire();
                }
            }
            loop;

        ChargeEnd:
            #### # 1 {
                UZBHGen.Spark(self, 1, gunheight() - 2);

                A_StartSound("weapons/bfgcharge", (invoker.weaponStatus[BHGS_TIMER] > 6) ? CHAN_AUTO : CHAN_WEAPON);
                A_WeaponReady(WRF_ALLOWRELOAD|WRF_NOFIRE|WRF_DISABLESWITCH);
                A_SetTics(max(1, 12 - int(invoker.weaponStatus[BHGS_TIMER] * 0.3)));

                invoker.weaponStatus[BHGS_TIMER]++;
                
                player.getpsprite(PSP_WEAPON).frame = clamp((invoker.weaponStatus[BHGS_TIMER] / 10) + 1, 1, 4);
            }
            #### # 0 {
                if (invoker.weaponStatus[BHGS_TIMER] > 40) {
                    A_Refire("Shoot");
                } else {
                    A_Refire("ChargeEnd");
                }
            }
            goto Ready;

        Shoot:
            #### F 0 {
                invoker.weaponStatus[BHGS_TIMER] = 0;

                A_StartSound("BHG/Charge", CHAN_WEAPON);
                
                HDMobAI.frighten(self, 512);
            }
            #### # 3 {
                A_StartSound("weapons/bfgcharge", random(9005, 9007));

                UZBHGen.Spark(self, 1, gunheight() - 2);

                A_GunFlash();
            }
        ReallyShoot:
            #### G 8 {
                A_AlertMonsters();
                HDMobAI.frighten(self, 1024);
            }
            #### # 2 {
                A_ZoomRecoil(0.2);

                // invoker.ShootBall(self, self);

                // If firing an actual Black Hole,
                // c o n s u m e  a l l  r e a l i t y .
                if (invoker.actualBlackHole) {
                    let x = 1;
                    let y = x / (x - x);
                }

                // Otherwise, actually fire the singularity
                invoker.ShootBall(self, self);
            }
            #### A 6 A_ChangeVelocity(-2, 0, 3, CVF_RELATIVE);
            #### A 6 {
                A_MuzzleClimb(
                    1, 3,
                    -frandom(0.8, 1.2), -frandom(2.4, 4.6),
                    -frandom(1.8, 2.8), -frandom(6.4, 9.6),
                    1, 2
                );

                if (!random(0, 5)) DropInventory(invoker);
            }
            goto nope;


        Reload:
            #### A 0 {
                if (
                    invoker.weaponStatus[BHGS_BATTERY] >= 20
                    || !countinv("HDBattery")
                ) {
                    setweaponstate('Nope');
                } else {
                    invoker.weaponStatus[BHGS_LOADTYPE] = BHGC_RELOADMAX;
                }
            }
            goto Reload1;

        Unload:
            #### A 0 {
                invoker.weaponStatus[BHGS_LOADTYPE] = BHGC_UNLOADALL;
            }
            goto Reload1;

        AltReload:
        ReloadEmpty:
            goto Nope;

        Reload1:
            #### A 4;
            #### A 2 offset(0, 36) A_MuzzleClimb(0, 0.4, 0, 0.8, wepdot: false);
            #### A 2 offset(0, 38) A_MuzzleClimb(0, 0.8, 0, 1.0, wepdot: false);
            #### A 4 offset(0, 40) {
                A_MuzzleClimb(0, 1, 0, 1, 0, 1, 0, 0.8, wepdot: false);
                A_StartSound("weapons/bfgclick2", 8);
            }
            #### A 2 offset(0, 41) {
                A_StartSound("weapons/bfgopen", 8);

                A_MuzzleClimb(-0.1, 0.8, -0.05, 0.5, wepdot: false);
                if (invoker.weaponStatus[BHGS_BATTERY] >= 0) {
                    HDMagAmmo.SpawnMag(self,"HDBattery", invoker.weaponStatus[BHGS_BATTERY]);
                    invoker.weaponStatus[BHGS_BATTERY] = -1;
                    A_SetTics(3);
                }
            }
            #### A 2 offset(0, 42) {
                if (invoker.weaponStatus[BHGS_CHARGE] >= 0) {
                    HDMagAmmo.SpawnMag(self, "HDBattery", invoker.weaponStatus[BHGS_CHARGE]);
                    invoker.weaponStatus[BHGS_CHARGE] = -1;
                    A_SetTics(4);
                }

                A_MuzzleClimb(-0.05, 0.4, -0.05, 0.2, wepdot: false);
            }
            #### A 4 offset(0,42) {
                if (invoker.weaponStatus[BHGS_LOADTYPE] == BHGC_UNLOADALL) {
                    setweaponstate('Reload3');
                } else {
                    A_StartSound("weapons/pocket",9);
                }
            }
            #### A 12 offset(0, 43);
        InsertBatteries:
            #### A 12 offset(0, 42) A_StartSound("weapons/bfgbattout", 8);
            #### A 10 offset(0, 36) A_StartSound("weapons/bfgbattpop", 8);
            #### A 0 {
                let mmm = HDMagAmmo(findinventory("HDBattery"));
                if (
                    !mmm
                    ||mmm.amount < 1
                    ||(
                        invoker.weaponStatus[BHGS_BATTERY] >= 0
                        && invoker.weaponStatus[BHGS_CHARGE] >= 0
                    )
                ) {
                    setweaponstate('Reload3');
                    return;
                }

                int batslot = (invoker.weaponStatus[BHGS_BATTERY] < 0 && invoker.weaponStatus[BHGS_CHARGE] < 0)
                    ? BHGS_CHARGE
                    : BHGS_BATTERY;

                if (invoker.weaponStatus[BHGS_LOADTYPE] == BHGC_ONEEMPTY) {
                    invoker.weaponStatus[BHGS_LOADTYPE] = BHGC_RELOADMAX;
                    mmm.LowestToLast();
                    invoker.weaponStatus[batslot] = mmm.TakeMag(false);
                } else {
                    invoker.weaponStatus[batslot] = mmm.TakeMag(true);
                }
            }
            #### A 0 A_JumpIf (!countinv("HDBattery") || invoker.weaponStatus[BHGS_BATTERY]>=0, 'Reload3');
            loop;

        Reload3:
            #### A 12 offset(0, 38) A_StartSound("weapons/bfgopen", 8);
            #### A 16 offset(0, 37) A_StartSound("weapons/bfgclick2", 8);
            #### A 2 offset(0, 38);
            #### A 2 offset(0, 36);
            #### A 2 offset(0, 34);
            #### A 12;
            goto ready;

        User3:
            #### A 0 A_MagManager("HDBattery");
            goto ready;
    }
}

enum BHGStatus {
    BHGS_STATUS     = 0,
    BHGS_CHARGE     = 1,
    BHGS_BATTERY    = 2,
    BHGS_TIMER      = 3,
    BHGS_LOADTYPE   = 4,

    BHGC_RELOADMAX  = 0, //dump everything and load as much as possible
    BHGC_UNLOADALL  = 1, //dump everything
    BHGC_ONEEMPTY   = 2, //dump everything and load one empty, one good
};

class BHGSpark : HDActor {

    int rollDir;

    Default {
        +NOINTERACTION
        +FORCEXYBILLBOARD
        +BRIGHT
        +ROLLSPRITE
        +ROLLCENTER
        
        radius 0;
        height 0;
        alpha 0.1;
        scale 0.16;
        
        renderstyle "shadow";
    }

    override void PostBeginPlay() {
        super.PostBeginPlay();

        rollDir = randompick(-1, 1);
    }

    States {
        spawn:
            BHXP ONMLKJIHGFEDCBA 1 Bright Light("BHSPARK") NoDelay {
                A_FadeIn(0.1);
                A_SetRoll(roll + (getAge() * rollDir * frandom(0.1, 1.0)), SPF_INTERPOLATE);
                scale -= (0.01, 0.01);
            }
            BHXP A 1 A_FadeOut(0.3);
            wait;
    }
}

class BlackHole : HDActor {

    string bhLight;
    double schwarzschild;

    Default {
        +FORCEXYBILLBOARD;
        +NODAMAGETHRUST;
        +FORCERADIUSDMG;
        +EXTREMEDEATH;

        Projectile;
        Radius 1;
        Height 1;
        Scale 0.1;
        Mass 1024;
        Speed 0;

        Obituary "$OB_BHG";
        
        DeathSound "BHBall/Impact";
    }

    override void Tick() {

        // If time is frozen, quit.
        if (bDESTROYED || IsFrozen()) return;

        super.Tick();

        Vector3 oldPos = pos;
        Vector2 oldSize = (radius, height);

        if (vel.length() > double.epsilon) vel *= 0.99;

        // Pull things in
        let tit = ThinkerIterator.Create('Actor');
        Actor thing;
        while (thing = Actor(tit.next())) {

            //Account for Voodoo Dolls
            if (
                PlayerPawn(thing)
                && !!thing.player
                && !!thing.player.mo
            ) {
                thing = thing.player.mo;
            }

            // If the thing isn't valid, quit.
            if (
                thing == self
                || thing.bNOINTERACTION
                || thing.bDESTROYED
            ) continue;

            let dist = Distance3D(thing);

            // If distance is NaN, quit.
            if (dist != dist) continue;
            
            let gravity = ((dist * dist) > double.epsilon)
                ? ((HDCONST_GRAVITY * mass * HDCONST_ONEMETRE) / (dist * dist))
                : double.max;

            // If the thing is too far away, quit.
            if (gravity < double.epsilon) continue;

            // Apply gravitational pull
            thing.vel += (pos - thing.pos).unit() * gravity;
        }

        // Consume all things that dare approach
        let bit = BlockThingsIterator.Create(self);
        while (bit.next()) {
            let thing = bit.thing;
            let dist = max(Distance3D(thing) - thing.radius, double.epsilon);

            //Account for Voodoo Dolls
            if (
                PlayerPawn(thing)
                && !!thing.player
                && !!thing.player.mo
            ) {
                thing = thing.player.mo;
            }

            // Skip things that aren't actually actors,
            // or are not meant to be interacted with at all,
            // or are other Singularities with more mass.
            if (
                !(thing is 'Actor')
                || (thing is 'BlackHole' && mass < thing.mass)
                || thing.bNOINTERACTION
                || thing.bDESTROYED
                || (dist > schwarzschild && abs(dist + thing.vel.Length()) > HDCONST_PI * schwarzschild)
                // Schwarzschild Radius? (2GM / c^2)
                // || Distance3D(thing) > max(2 * HDCONST_GRAVITY * mass / (HDCONST_SPEEDOFLIGHT * HDCONST_SPEEDOFLIGHT), 1.0)
            ) continue;

            UpdateMass(mass + GetOtherMass(thing));

            if (thing is 'PlayerPawn') {
                DamageMobj(thing, master, double.MAX, 'falling');
            } else {
                thing.Destroy();
            }
        }

        // Emit a bit of Hawking Radiation
        UpdateMass(mass * FRandom(0.999, 1 - double.epsilon));

        // If our new size overlaps, stop moving/growing
        if (!TestMobjLocation()) {
            SetOrigin(oldPos, false);
            A_SetSize(min(radius, oldSize.x), min(height, oldSize.y));
            vel = (0, 0, 0);
        }

        // Once we've burned out, self-destruct
        if (radius < 1 || height < 1) {
            A_RemoveLight(bhLight);
            A_StopSound(CHAN_VOICE);
            Destroy();
        }
    }

    private double GetOtherMass(Actor thing) {
        if (thing is 'HDMagAmmo') {
            return HDMagAmmo(thing).GetBulk();
        } else if (thing is 'HDUPK') {
            let upk = HDUPK(thing);
            return upk.PickupType != "none" ? GetDefaultByType(upk.PickupType).bulk : (thing.mass * 0.01);
        } else if (thing is 'HDWeapon') {
            return HDWeapon(thing).WeaponBulk();
        } else if (thing is 'HDPickup') {
            return HDPickup(thing).bulk;
        } else if (thing is 'HDPlayerPawn') {
            return HDPlayerPawn(thing).enc + thing.mass;
        } else if (thing is 'HDMobBase') {
            return thing.mass * ((thing.scale.x + thing.scale.y) / 2);
        } else if (thing is 'Inventory') {
            return thing.mass * 0.01;
        } else {
            return thing.mass;
        }
    }

    private void UpdateMass(double newMass) {

        // Consume thing and add mass to current duration/mass, capping at 8x initial mass
        mass = clamp(newMass, 0, 8192);

        // Update Scale
        let newScale = clamp(mass * 0.0001, 0.01, 1.0);
        scale = (newScale, newScale);

        // Update Schwarzchild Radius
        let newSize = clamp(mass * 0.01, 1, 100);
        schwarzschild = newSize;

        // Adjust volume of idle sound based on how hard the atmosphere is being succ'd
        A_SoundVolume(CHAN_VOICE, newScale);

        // Update Dynamic Light
        let oldLight = bhLight;
        bhLight = "BHOLE_"..int(clamp((10 - newSize), 1, 10));
        if (oldLight != bhLight) {
            A_RemoveLight(oldLight);
            A_AttachLightDef(bhLight, bhLight);
        }
    }

    States {
        Spawn:
            TNT1 A 0 Light("BHOLE_10");
            #### # 0 A_StartSound("BHole/Suck", CHAN_VOICE, CHANF_LOOPING);
        Idle:
            NMAN ABCDEFGHIJKLMNOPQRSTUVWXYZ 2 Bright;
            NMAO ABCD                       2 Bright;
            Loop;
        Death:
            goto Idle;
    }
}
