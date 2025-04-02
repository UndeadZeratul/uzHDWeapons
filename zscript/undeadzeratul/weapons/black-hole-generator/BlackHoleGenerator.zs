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
            let max = weaponstatus[BHGS_TIMER] * (0.0625 / max(1, hdp.strength));
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
            + (weaponstatus[BHGS_CHARGE] >= 0 ? 1 : 0)
            + (weaponstatus[BHGS_BATTERY] >= 0 ? 1 : 0)
        ;
    }

    override double weaponbulk() {
        return 240
            + (weaponstatus[BHGS_CHARGE] >= 0 ? ENC_BATTERY_LOADED : 0)
            + (weaponstatus[BHGS_BATTERY] >= 0 ? ENC_BATTERY_LOADED : 0)
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

        int bffb = hdw.weaponstatus[BHGS_BATTERY];
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

        bffb = hdw.weaponstatus[BHGS_CHARGE];
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
        weaponstatus[BHGS_CHARGE] = 20;
        weaponstatus[BHGS_BATTERY] = 20;
        weaponstatus[BHGS_TIMER] = 0;
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
                invoker.weaponstatus[BHGS_TIMER] = 0;
            }
        Hold:
            #### # 0 {
                if (
                    invoker.weaponstatus[BHGS_CHARGE] >= 20
                    && invoker.weaponstatus[BHGS_BATTERY] >= 20
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
                    || invoker.weaponstatus[BHGS_BATTERY] < 0
                    || (
                        invoker.weaponstatus[BHGS_CHARGE] >= 20
                        && invoker.weaponstatus[BHGS_BATTERY] >= 20
                    )
                ) {
                    setweaponstate('Nope');
                }
            }
            #### # 6 {
                invoker.weaponstatus[BHGS_TIMER]++;

                if (health < 40) {
                    A_SetTics(2);

                    if (health > 16) damagemobj(invoker, self, 1, "internal");
                } else if (invoker.weaponstatus[BHGS_BATTERY] == 20) {
                    A_SetTics(2);
                }

                UZBHGen.Spark(self, 1, gunheight() - 2);

                A_WeaponBusy(false);
                A_StartSound("weapons/bfgcharge", CHAN_WEAPON);
                A_WeaponReady(WRF_NOFIRE);
            }
            #### # 0 {
                if (invoker.weaponstatus[BHGS_CHARGE] == 20 && invoker.weaponstatus[BHGS_BATTERY] == 20) {
                    A_Refire("Shoot");
                } else {
                    A_Refire();
                }
            }
            loop;

        ChargeEnd:
            #### # 1 {
                UZBHGen.Spark(self, 1, gunheight() - 2);

                A_StartSound("weapons/bfgcharge", (invoker.weaponstatus[BHGS_TIMER] > 6) ? CHAN_AUTO : CHAN_WEAPON);
                A_WeaponReady(WRF_ALLOWRELOAD|WRF_NOFIRE|WRF_DISABLESWITCH);
                A_SetTics(max(1, 12 - int(invoker.weaponstatus[BHGS_TIMER] * 0.3)));

                invoker.weaponstatus[BHGS_TIMER]++;
                
                player.getpsprite(PSP_WEAPON).frame = clamp((invoker.weaponstatus[BHGS_TIMER] / 10) + 1, 1, 4);
            }
            #### # 0 {
                if (invoker.weaponstatus[BHGS_TIMER] > 40) {
                    A_Refire("Shoot");
                } else {
                    A_Refire("ChargeEnd");
                }
            }
            goto Ready;

        Shoot:
            #### F 0 {
                invoker.weaponstatus[BHGS_TIMER] = 0;

                A_StartSound("weapons/bfgf", CHAN_WEAPON);
                
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
                A_FireCustomMissile("DMBall", 0, 1, 0, 0);
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
                    invoker.weaponstatus[BHGS_BATTERY] >= 20
                    || !countinv("HDBattery")
                ) {
                    setweaponstate('Nope');
                } else {
                    invoker.weaponstatus[BHGS_LOADTYPE] = BHGC_RELOADMAX;
                }
            }
            goto Reload1;

        Unload:
            #### A 0 {
                invoker.weaponstatus[BHGS_LOADTYPE] = BHGC_UNLOADALL;
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
                if (invoker.weaponstatus[BHGS_BATTERY] >= 0) {
                    HDMagAmmo.SpawnMag(self,"HDBattery", invoker.weaponstatus[BHGS_BATTERY]);
                    invoker.weaponstatus[BHGS_BATTERY] = -1;
                    A_SetTics(3);
                }
            }
            #### A 2 offset(0, 42) {
                if (invoker.weaponstatus[BHGS_CHARGE] >= 0) {
                    HDMagAmmo.SpawnMag(self, "HDBattery", invoker.weaponstatus[BHGS_CHARGE]);
                    invoker.weaponstatus[BHGS_CHARGE] = -1;
                    A_SetTics(4);
                }

                A_MuzzleClimb(-0.05, 0.4, -0.05, 0.2, wepdot: false);
            }
            #### A 4 offset(0,42) {
                if (invoker.weaponstatus[BHGS_LOADTYPE] == BHGC_UNLOADALL) {
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
                        invoker.weaponstatus[BHGS_BATTERY] >= 0
                        && invoker.weaponstatus[BHGS_CHARGE] >= 0
                    )
                ) {
                    setweaponstate('Reload3');
                    return;
                }

                int batslot = (invoker.weaponstatus[BHGS_BATTERY] < 0 && invoker.weaponstatus[BHGS_CHARGE] < 0)
                    ? BHGS_CHARGE
                    : BHGS_BATTERY;

                if (invoker.weaponstatus[BHGS_LOADTYPE] == BHGC_ONEEMPTY) {
                    invoker.weaponstatus[BHGS_LOADTYPE] = BHGC_RELOADMAX;
                    mmm.LowestToLast();
                    invoker.weaponstatus[batslot] = mmm.TakeMag(false);
                } else {
                    invoker.weaponstatus[batslot] = mmm.TakeMag(true);
                }
            }
            #### A 0 A_JumpIf (!countinv("HDBattery") || invoker.weaponstatus[BHGS_BATTERY]>=0, 'Reload3');
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
            BHXP ABCDEFGHIJKLMNO 1 Bright Light("BHSPARK") NoDelay {
                A_FadeIn(0.1);
                A_SetRoll(roll + (getAge() * rollDir * frandom(0.1, 1.0)), SPF_INTERPOLATE);
            }
            BHXP O 1 A_FadeOut(0.3);
            wait;
    }
}

class DMBall : HDActor {

    Default {
        +RIPPER;
        +FORCEXYBILLBOARD;
        +NODAMAGETHRUST;
        +FORCERADIUSDMG;

        Projectile;
        Radius 13;
        Height 8;
        Speed 22;
        Damage 10;
        Renderstyle "Translucent";
        Alpha 0.75;
        DeathSound "DMBall/Impact";
        // Decal BHoleDecal;
        Obituary "$OB_BHG";
    }

    States {
        Spawn:
            VOIP AA 1 Bright A_RadiusThrust(-240,200,0);
            TNT1 A 0 A_Explode(10,90,0);
            TNT1 A 0 A_SpawnItemEx("DMBTrail",0,0,0);
            VOIP BB 1 Bright A_RadiusThrust(-240,200,0);
            TNT1 A 0 A_Explode(10,90,0);
            TNT1 A 0 A_SpawnItemEx("DMBTrail",0,0,0);
            VOIP CC 1 Bright A_RadiusThrust(-240,200,0);
            TNT1 A 0 A_Explode(10,90,0);
            TNT1 A 0 A_SpawnItemEx("DMBTrail",0,0,0);
            VOIP DD 1 Bright A_RadiusThrust(-240,200,0);
            TNT1 A 0 A_Explode(10,90,0);
            TNT1 A 0 A_SpawnItemEx("DMBTrail",0,0,0);
            VOIP EE 1 Bright A_RadiusThrust(-240,200,0);
            TNT1 A 0 A_Explode(10,90,0);
            TNT1 A 0 A_SpawnItemEx("DMBTrail",0,0,0);
            VOIP FF 1 Bright A_RadiusThrust(-240,200,0);
            TNT1 A 0 A_Explode(10,90,0);
            TNT1 A 0 A_SpawnItem("DMBTrail",0,0,0);
            Loop;
        Death:
            TNT1 A 0 A_SpawnItemEx("BlackHole",0,0,0);
            TNT1 A 0 A_SetScale(1.2);
            VORX ABCDEFGH 2 Bright;
            Stop;
    }
}

class DMBTrail : HDActor {

    Default {
        +NOINTERACTION;
        +FORCEXYBILLBOARD;
        RenderStyle "Translucent";
        Alpha 0.70;
        Scale 0.7;
    }

    States {
        Spawn:
            VORX ABCDEFGH 2 Bright A_FadeOut(0.1);
            Stop;
    }
}

class BlackHole : HDActor {

    Default {
        +NOCLIP;
        +NODAMAGETHRUST;
        +FORCEXYBILLBOARD;
        +FORCERADIUSDMG;
        +EXTREMEDEATH;

        Projectile;
        Radius 6;
        Height 40;
        Speed 0;
        // RenderStyle "Translucent";
        // Alpha 0.85;
        Scale 0.1;
        ReactionTime 20;
        Obituary "$OB_BHG";
    }

    States {
        Spawn:
            NMAN A 0 A_CountDown();
            #### # 0 A_PlaySoundEx("BHole/Suck", "Voice", 1);
            #### ABCDFGHIJKLMNOPQRSTUVWXYZ 2 Bright Light("BHOLE_1") {
                A_RadiusThrust(-1000, flags: RTF_AFFECTSOURCE|RTF_NOIMPACTDAMAGE|RTF_THRUSTZ);
                A_Explode(8, 180, XF_HURTSOURCE, false, 10);
            }
            NMAO ABCD 2 Bright Light("BHOLE_1") {
                A_RadiusThrust(-1000, flags: RTF_AFFECTSOURCE|RTF_NOIMPACTDAMAGE|RTF_THRUSTZ);
                A_Explode(8, 180, XF_HURTSOURCE, false, 10);
            }
            Loop;
        Death:
            #### # 0 A_StopSoundEx("Voice");
            #### # 0 A_SpawnItemEx("BHSmoke", 0, 0, 0);
            #### # 0 A_SpawnItemEx("BHExplosion", 0, 0, 0);
            #### # 0 A_PlaySound("BHole/Explosion");
            NMAN ABCD 1 Bright Light("BHOLE_2") A_FadeOut(0.03);
            NMAN EFGH 1 Bright Light("BHOLE_3") A_FadeOut(0.03);
            NMAN IJKL 1 Bright Light("BHOLE_4") A_FadeOut(0.03);
            NMAN MNOP 1 Bright Light("BHOLE_5") A_FadeOut(0.03);
            NMAN QRST 1 Bright Light("BHOLE_6") A_FadeOut(0.03);
            NMAN UVWX 1 Bright Light("BHOLE_7") A_FadeOut(0.03);
            NMAN YZ   1 Bright Light("BHOLE_8") A_FadeOut(0.03);
            NMAO AB   1 Bright Light("BHOLE_8") A_FadeOut(0.03);
            NMAO CD   1 Bright Light("BHOLE_9") A_FadeOut(0.03);
            Stop;
    }
}

class BHSmoke : HDActor {

    Default {
        +NOINTERACTION;
        +FORCEXYBILLBOARD;
        RenderStyle "Translucent";
        Alpha 0.70;
        Scale 2.2;
    }

    States {
        Spawn:
            BHXP ABCDEFGHIJKLMNO 2 A_FadeOut(0.03);
            Stop;
    }
}

class BHExplosion : HDActor {

    Default {
        +NOINTERACTION;
        +FORCEXYBILLBOARD;
    }

    States {
        Spawn:
            DBX3 A 1 Light("BHEXP_1") Bright A_SetScale(1.25);
            TNT1 A 0 A_FadeOut(0.09);
            DBX3 A 1 Light("BHEXP_2") Bright A_SetScale(1.50);
            TNT1 A 0 A_FadeOut(0.09);
            DBX3 A 1 Light("BHEXP_3") Bright A_SetScale(1.75);
            TNT1 A 0 A_FadeOut(0.09);
            DBX3 A 1 Light("BHEXP_4") Bright A_SetScale(2.0);
            TNT1 A 0 A_FadeOut(0.09);
            DBX3 A 1 Light("BHEXP_5") Bright A_SetScale(2.25);
            TNT1 A 0 A_FadeOut(0.09);
            DBX3 A 1 Light("BHEXP_6") Bright A_SetScale(2.50);
            TNT1 A 0 A_FadeOut(0.09);
            DBX3 A 1 Light("BHEXP_7") Bright A_SetScale(2.75);
            TNT1 A 0 A_FadeOut(0.09);
            DBX3 A 1 Bright A_SetScale(3.0);
            TNT1 A 0 A_FadeOut(0.09);
            DBX3 A 1 Bright A_SetScale(3.25);
            TNT1 A 0 A_FadeOut(0.09);
            DBX3 A 1 Bright A_SetScale(3.50);
            TNT1 A 0 A_FadeOut(0.09);
            DBX3 A 1 Bright A_SetScale(3.75);
            TNT1 A 0 A_FadeOut(0.09);
            DBX3 A 1 Bright A_SetScale(4.0);
            TNT1 A 0 A_FadeOut(0.09);
            DBX3 A 1 Bright A_SetScale(4.25);
            TNT1 A 0 A_FadeOut(0.09);
            Stop;
    }
}
