// ------------------------------------------------------------
// "Ripper" Chaingun Cannon
// ------------------------------------------------------------
enum ripperstatus {
    RIPRF_JUSTUNLOAD     = 1,
    RIPRF_LOADCELL       = 2,
    RIPRF_DIRTYMAG       = 4,

    RIPRS_MAG1           = 1,
    RIPRS_MAG2           = 2,
    RIPRS_MAG3           = 3,

    RIPRS_CHAMBER1       = 4,
    RIPRS_CHAMBER2       = 5,
    RIPRS_CHAMBER3       = 6,

    RIPRS_CURRENTCHAMBER = 7,

    RIPRS_BATTERY        = 8,
    // RIPRS_ZOOM           = 9,
    RIPRS_HEAT           = 10,

    RIPRS_DOT            = 11,

    RIPR_BARREL_OVERLAY  = -3,
    RIPR_HEAT_OVERLAY    = -2,
};

class UZRipper : HDWeapon {

    bool isOpen;

    default {
        //$Category "Weapons/Hideous Destructor"
        //$Title "Ripper Chaingun"
        //$Sprite "RIPPA0"

        +HDWeapon.HINDERLEGS
        -HDWeapon.FITSINBACKPACK

        scale 0.8;
        inventory.pickupmessage "$PICKUP_RIPPER";
        weapon.selectionorder 40;
        weapon.slotnumber 4;
        weapon.slotpriority 1;
        weapon.kickback 24;
        weapon.bobrangex 0.67;
        weapon.bobrangey 1.0;
        weapon.bobspeed 2.1;
        weapon.bobstyle "normal";
        obituary "$OB_RIPPER";
        hdweapon.barrelsize 31, 3, 3;
        hdweapon.refid UZLD_RIPPER;
        tag "$TAG_RIPPER";

        hdweapon.ammo1 "HD4mMag",1;
        hdweapon.ammo2 "HDBattery",1;

        // hdweapon.loadoutcodes"
        //     \cufast - 0/1, whether to start in \"fuller auto\" mode
        //     \cuzoom - 16-70, 10x the resulting FOV in degrees
        //     \cudot - 0-5";
    }

    override bool AddSpareWeapon(actor newowner) {
        return AddSpareWeaponRegular(newowner);
    }

    override HDWeapon GetSpareWeapon(actor newowner, bool reverse, bool doselect) {
        return GetSpareWeaponRegular(newowner, reverse, doselect);
    }

    override void tick() {
        super.tick();

        if (weaponStatus[RIPRS_HEAT] > 256 || random[uzwepsrand]() < weaponStatus[RIPRS_HEAT]) drainheat(RIPRS_HEAT, 1);
    }

    override void DoEffect() {
        let hdp = HDPlayerPawn(owner);

        //droop downwards
        if (
            hdp
            && !hdp.gunbraced
            && !!hdp.player
            && hdp.player.readyweapon == self
            && hdp.strength
            && hdp.pitch < frandom[uzwepsrand](5, 8)
        ) {
            hdp.A_MuzzleClimb(
                (frandom[uzwepsrand](-0.05, 0.05), frandom[uzwepsrand](0.1, clamp(1 - pitch, 0.06 / hdp.strength, 0.12))),
                (0, 0),
                (0, 0),
                (0, 0)
            );
        }

        super.DoEffect();
    }

    // override void OnSelect(bool fromPowerup) {
    //     super.OnSelect(fromPowerup);
    // }

    // override void OnDeselect(bool fromPowerup, bool onToss) {
    //     super.OnDeselect(fromPowerup, onToss);

    //     A_ClearOverlays();
    // }

    override double gunmass() {
        double mass = 9 + (weaponStatus[RIPRS_BATTERY] >= 0);

        for (int i = RIPRS_MAG1; i <= RIPRS_MAG3; i++) {
            if (weaponStatus[i] >= 0) {
                mass += weaponStatus[i] * 0.04;
            }
        }

        return mass;
    }

    override double weaponbulk() {
        double blx = 185 + (weaponStatus[RIPRS_BATTERY] >= 0 ? ENC_BATTERY_LOADED : 0);

        for (int i = RIPRS_MAG1; i <= RIPRS_MAG3; i++) {
            int wsi = weaponStatus[i];
            if (wsi >= 0) blx += ENC_426_LOADED * wsi + ENC_426MAG_LOADED;
        }

        return blx;
    }

    override string,double getpickupsprite() {
        return "RIPPA0",1.0;
    }

    override void DrawHUDStuff(HDStatusBar sb, HDWeapon hdw, HDPlayerPawn hpl) {
        if (sb.hudlevel == 1) {
            int nextmagloaded = sb.GetNextLoadMag(hdmagammo(hpl.findinventory("HD4mMag")));
            if (nextmagloaded > 50) {
                sb.drawimage(
                    "ZMAGA0",
                    (-46, -3),
                    sb.DI_SCREEN_CENTER_BOTTOM,
                    scale: (2, 2)
                );
            } else if (nextmagloaded < 1) {
                sb.drawimage(
                    "ZMAGC0",
                    (-46, -3),
                    sb.DI_SCREEN_CENTER_BOTTOM,
                    alpha: nextmagloaded ? 0.6 : 1.0,
                    scale: (2, 2)
                );
            } else {
                sb.drawbar(
                    "ZMAGNORM", "ZMAGGREY",
                    nextmagloaded, 50,
                    (-46, -3), -1,
                    sb.SHADER_VERT,
                    sb.DI_SCREEN_CENTER_BOTTOM
                );
            }

            sb.drawbattery(-64, -4, sb.DI_SCREEN_CENTER_BOTTOM, reloadorder: true);

            sb.drawnum(hpl.countinv("HD4mMag"), -43, -8, sb.DI_SCREEN_CENTER_BOTTOM);
            sb.drawnum(hpl.countinv("HDBattery"), -56, -8, sb.DI_SCREEN_CENTER_BOTTOM);
        }

        for (int i = 0; i < 3; i++) {
            if ( i > 0 && hdw.weaponStatus[RIPRS_MAG1 + i] >= 0) sb.drawrect(-15 - i * 4, -14, 3, 2);

            if (hdw.weaponStatus[RIPRS_CHAMBER1 + i] > 0) sb.drawrect(-15, -19 + i * 2, 1, 1);
        }

        sb.drawwepnum(hdw.weaponStatus[RIPRS_MAG1], 50, posy: -9);

        // sb.drawwepcounter(hdw.weaponStatus[0]&RIPRF_FAST,
        //     -28,-16,"blank","STFULAUT"
        // );

        if (hdw.weaponStatus[RIPRS_BATTERY] > 0) {
            int lod = min(50, hdw.weaponStatus[RIPRS_MAG1]);
            
            if (lod >= 0) {
                if (hdw.weaponStatus[0]&RIPRF_DIRTYMAG) lod = random[shitgun](10, 99);
                
                sb.drawnum(
                    lod,
                    -20, -22,
                    sb.DI_SCREEN_CENTER_BOTTOM|sb.DI_TEXT_ALIGN_RIGHT,
                    Font.CR_RED
                );
            }
            
            sb.drawwepnum(hdw.weaponStatus[RIPRS_BATTERY], 20);
        } else if (!hdw.weaponStatus[RIPRS_BATTERY]) {
            sb.drawstring(
                sb.mamountfont,
                "00000",
                (-16, -8),
                sb.DI_TEXT_ALIGN_RIGHT|sb.DI_TRANSLATABLE|sb.DI_SCREEN_CENTER_BOTTOM,
                Font.CR_DARKGRAY
            );
        }
        // sb.drawnum(
        //     hdw.weaponStatus[RIPRS_ZOOM],
        //     -30, -22,
        //     sb.DI_SCREEN_CENTER_BOTTOM|sb.DI_TEXT_ALIGN_RIGHT,
        //     Font.CR_DARKGRAY
        // );
    }

    override string gethelptext() {
        LocalizeHelp();
        return
        LWPHELP_FIRESHOOT
        ..LWPHELP_RELOAD..StringTable.Localize("$VULWH_RELOAD")
        ..LWPHELP_ALTRELOAD..StringTable.Localize("$VULWH_ALTRELOAD")
        // ..LWPHELP_FIREMODE..StringTable.Localize("$VULWH_SWITCH")..(weaponStatus[0]&RIPRF_FAST?"700":"2100")..StringTable.Localize("$VULWH_RPM")
        ..LWPHELP_MAGMANAGER
        ..LWPHELP_UNLOADUNLOAD
        ..LWPHELP_USE.."+"..LWPHELP_UNLOAD..StringTable.Localize("$VULWH_OR")..LWPHELP_USE.."+"..LWPHELP_ALTRELOAD..StringTable.Localize("$VULWH_UNLBAT")
        ;
    }

    override void DrawSightPicture(
        HDStatusBar sb, HDWeapon hdw, HDPlayerPawn hpl,
        bool sightbob, Vector2 bob, double fov, bool scopeview, Actor hpc
    ) {

        for (let i = -1; i < 2; i++) {
            let dotoff = max(abs(bob.x + (i * 2.5)), abs(bob.y));
            if (dotoff < 40) {
                sb.drawimage(
                    sb.ChooseReflexReticle(hdw.weaponStatus[RIPRS_DOT]),
                    (i * 2.5, 0) + bob * 1.1,
                    sb.DI_SCREEN_CENTER|sb.DI_ITEM_CENTER,
                    alpha: 0.8 - dotoff * 0.01,
                    col: 0xFF000000|sb.crosshaircolor.GetInt()
                );
            }
        }
        
        sb.drawimage(
            "riprsite",
            (0, 0) + bob,
            sb.DI_SCREEN_CENTER|sb.DI_ITEM_CENTER
        );
    }

    override void SetReflexReticle(int which) {
        weaponStatus[RIPRS_DOT] = which;
    }

    override void consolidate() {
        CheckBFGCharge(RIPRS_BATTERY);
    }

    override void DropOneAmmo(int amt) {
        if (owner) {
            amt = clamp(amt, 1, 10);

            if (owner.countinv("FourMilAmmo")) {
                owner.A_DropInventory("FourMilAmmo", 50);
            } else {
                owner.angle -= 10;
                owner.A_DropInventory("HD4mMag",1);
                owner.angle += 20;
                owner.A_DropInventory("HDBattery",1);
                owner.angle -= 10;
            }
        }
    }

    override void InitializeWepStats(bool idfa) {
        weaponStatus[RIPRS_BATTERY] = 20;

        weaponStatus[RIPRS_MAG1] = 51;
        weaponStatus[RIPRS_MAG2] = 51;
        weaponStatus[RIPRS_MAG3] = 51;

        weaponStatus[RIPRS_CHAMBER1] = idfa;
        weaponStatus[RIPRS_CHAMBER2] = idfa;
        weaponStatus[RIPRS_CHAMBER3] = idfa;

        weaponStatus[0] &= ~RIPRF_DIRTYMAG;
    }

    override void loadoutconfigure(string input) {
        int xhdot = getloadoutvar(input, "dot", 3);
        if (xhdot >= 0) weaponStatus[RIPRS_DOT] = xhdot;

        if (getage() < 1) {
            weaponStatus[RIPRS_MAG1] = 47;
            weaponStatus[RIPRS_CHAMBER1] = 1;
            weaponStatus[RIPRS_CHAMBER2] = 1;
            weaponStatus[RIPRS_CHAMBER3] = 1;
        }
    }

    action void RIPRShoot() {

        if (invoker.weaponStatus[RIPRS_CHAMBER1] != 1)return;

        switch(invoker.weaponStatus[RIPRS_CURRENTCHAMBER]) {
            case 0:
                A_Overlay(-6, "flash1", true);
                break;
            case 1:
                A_Overlay(-5, "flash2", true);
                break;
            case 2:
                A_Overlay(-4, "flash3", true);
                break;
            default:
                HDCore.log('UZWeps.Ripper', LOGGING_WARN, "Firing from unknown barrel: "..invoker.weaponStatus[RIPRS_CURRENTCHAMBER]);
                break;
        }

        A_StartSound("weapons/ripper/fire", CHAN_WEAPON, CHANF_OVERLAP);
        A_AlertMonsters();

        double cm = IsMoving.Count(self);
        double offx = frandom[uzwepsrand](-0.1, 0.1) * cm;
        double offy = frandom[uzwepsrand](-0.1, 0.1) * cm;

        int heat = min(50, invoker.weaponStatus[RIPRS_HEAT]);

        HDBulletActor.FireBullet(
            self,
            "HDB_426",
            zofs: height - 8,
            xyofs: (invoker.weaponStatus[RIPRS_CURRENTCHAMBER] - 1) * 2.25,
            spread: heat > 20 ? heat * 0.2 : 4,
            distantsound: "world/vulcfar"
        );

        invoker.weaponStatus[RIPRS_CURRENTCHAMBER] = (invoker.weaponStatus[RIPRS_CURRENTCHAMBER] + 1) % 3;

        invoker.weaponStatus[RIPRS_HEAT] += random[uzwepsrand](2, 4);

        if (random[uzwepsrand](0, 8192) < min(10, heat)) invoker.weaponStatus[RIPRS_BATTERY]++;

        invoker.weaponStatus[RIPRS_CHAMBER1] = 0;
    }

    action void RIPRNextRound() {
        int thisch = invoker.weaponStatus[RIPRS_CHAMBER1];
        if (thisch > 0) {

            //spit out a misfired, wasted or broken round
            if (thisch > 1) {
                for (int i = 0; i < 5; i++) {
                    A_SpawnItemEx(
                        "TinyWallChunk",
                        3, 0, height - 18,
                        random[uzwepsrand](4, 7), random[uzwepsrand](-2, 2), random[uzwepsrand](-2, 1),
                        -30,
                        SXF_NOCHECKPOSITION
                    );
                }
            } else {
                A_SpawnItemEx(
                    "ZM66DroppedRound",
                    3, 0, height - 18,
                    random[uzwepsrand](4, 7), random[uzwepsrand](-2, 2), random[uzwepsrand](-2, 1),
                    -30,
                    SXF_NOCHECKPOSITION
                );
            }

            A_MuzzleClimb(frandom[uzwepsrand](0.6, 2.4), frandom[uzwepsrand](1.2, 2.4));
        }

        // cycle all chambers
        for (int i = RIPRS_CHAMBER1; i < RIPRS_CHAMBER3; i++) {
            invoker.weaponStatus[i] = invoker.weaponStatus[i + 1];
        }

        // check if mag is clean
        int inmag = invoker.weaponStatus[RIPRS_MAG1];
        if (inmag >= 51) {
            // open the seal
            invoker.weaponStatus[RIPRS_MAG1] = 50;
            invoker.weaponStatus[0]&=~RIPRF_DIRTYMAG;
            inmag = 50;
        }

        // extract a round from the mag
        if (inmag > 0) {
            invoker.weaponStatus[RIPRS_MAG1]--;
            A_StartSound("weapons/vulcchamber", CHAN_WEAPON,CHANF_OVERLAP);

            invoker.weaponStatus[RIPRS_CHAMBER3] = (random[uzwepsrand](0, 2000) <= 1 + (invoker.weaponStatus[0]&RIPRF_DIRTYMAG ? 9 : 0)) ? 2 : 1;
        } else {
            invoker.weaponStatus[RIPRS_CHAMBER3] = 0;
        }
    }

    action void RIPRNextMag() {
        int thismag = invoker.weaponStatus[RIPRS_MAG1];

        if (thismag >= 0) {
            double cp = cos(pitch);
            double ca = cos(angle + 60);
            double sp = sin(pitch);
            double sa = sin(angle + 60);
            actor mmm = HDMagAmmo.SpawnMag(self, "HD4mMag", thismag);

            mmm.setOrigin(
                pos + (
                    cp * ca * 16,
                    cp * sa * 16,
                    height - 12 - 12 * sp
                ),
                false
            );

            mmm.vel += (
                cp * cos(angle + random[uzwepsrand](55, 65)),
                cp * sin(angle + random[uzwepsrand](55, 65)),
                sp
            );
        }

        for (int i = RIPRS_MAG1; i < RIPRS_MAG3; i++) invoker.weaponStatus[i] = invoker.weaponStatus[i + 1];

        invoker.weaponStatus[RIPRS_MAG3] = -1;

        if (invoker.weaponStatus[RIPRS_MAG1] < 51) invoker.weaponStatus[0] |= RIPRF_DIRTYMAG;
    }

    states {
        select0:
            RIPG A 0 A_Overlay(RIPR_BARREL_OVERLAY, "barrelOverlay", true);
            #### # 0 A_OverlayFlags(RIPR_BARREL_OVERLAY, PSPF_ADDBOB|PSPF_FORCEALPHA, true);
            #### # 0 A_Overlay(RIPR_HEAT_OVERLAY, "heatOverlay", true);
            #### # 0 A_OverlayFlags(RIPR_HEAT_OVERLAY, PSPF_ADDBOB|PSPF_ALPHA|PSPF_RENDERSTYLE, true);
            #### # 0 A_OverlayRenderstyle(RIPR_HEAT_OVERLAY, STYLE_Add);
            #### # 0 A_CheckDefaultReflexReticle(RIPRS_DOT);
            goto select0bfg;
        deselect0:
            RIPG A 0;
            goto deselect0bfg;

        ready:
            RIPG A 1 {
                invoker.isOpen = false;
                A_SetCrosshair(21);
                A_WeaponReady(WRF_ALL);
            }
            goto readyend;

        fire:
        hold:
            RIPG A 0 A_JumpIf(invoker.weaponStatus[RIPRS_BATTERY] < 1, "nope");
            #### # 1 {
                A_WeaponReady(WRF_NOFIRE);

                if (invoker.weaponStatus[RIPRS_BATTERY] > 0 && !random[uzwepsrand](0, 700)) invoker.weaponStatus[RIPRS_BATTERY]--;
            }
        shoot:
            #### # 1 {
                A_WeaponReady(WRF_NOFIRE);

                if (invoker.weaponStatus[RIPRS_BATTERY] > 0 && !random[uzwepsrand](0, 210)) invoker.weaponStatus[RIPRS_BATTERY]--;

                // check speed and then shoot
                if (invoker.weaponStatus[RIPRS_BATTERY] < 2) {
                    A_SetTics(random[uzwepsrand](4, 6));
                } else if (invoker.weaponStatus[RIPRS_BATTERY] < 3) {
                    A_SetTics(random[uzwepsrand](3, 4));
                }

                RIPRShoot();
                RIPRNextRound();
            }
            #### # 1 {
                A_WeaponReady(WRF_NOFIRE);

                // check speed
                if (invoker.weaponStatus[RIPRS_BATTERY] < 2) {
                    A_SetTics(random[uzwepsrand](4, 6));
                } else if (invoker.weaponStatus[RIPRS_BATTERY] < 3) {
                    A_SetTics(random[uzwepsrand](3, 4));
                }
            }
            #### # 1 {
                A_WeaponReady(WRF_NOFIRE);

                if (invoker.weaponStatus[RIPRS_BATTERY] > 0) {
                    A_Refire("holdswap");
                }
            }
            goto spindown;

        holdswap:
            #### # 0 {
                if (invoker.weaponStatus[RIPRS_MAG1] < 1) {
                    RIPRNextMag();
                    A_StartSound("weapons/vulcshunt", CHAN_WEAPON, CHANF_OVERLAP);
                }
            }
            goto hold;

        spindown:
            RIPG A 0 A_ClearRefire();
            goto nope;

        barrelOverlay:
            RIPB # 0 A_JumpIf(player.readyWeapon != invoker, "nope");
            #### # 1 {
                let layer = OverlayID();
                
                player.FindPSprite(layer).frame = invoker.isOpen;
                
                A_OverlayAlpha(layer, player.FindPSprite(PSP_WEAPON).y < 100);
            }
            loop;

        heatOverlay:
            RIPH # 0 A_JumpIf(player.readyWeapon != invoker, "nope");
            #### # 1 {
                let layer = OverlayID();
                let heat = invoker.weaponStatus[RIPRS_HEAT] / 256.0;
                
                player.FindPSprite(layer).frame = (invoker.isOpen * 3) + clamp(heat * 3, 0, 2);
                
                A_OverlayAlpha(layer, player.FindPSprite(PSP_WEAPON).y < 100 ? heat : 0);
            }
            loop;

        flash1:
            RIPF ABC 1 bright HDFlashAlpha(invoker.weaponStatus[RIPRS_HEAT] * 48, layer: OverlayID());
            goto flashfollow;
        flash2:
            RIPF DEF 1 bright HDFlashAlpha(invoker.weaponStatus[RIPRS_HEAT] * 48, layer: OverlayID());
            goto flashfollow;
        flash3:
            RIPF GHI 1 bright HDFlashAlpha(invoker.weaponStatus[RIPRS_HEAT] * 48, layer: OverlayID());
            goto flashfollow;
        flashfollow:
            #### # 0 {
                A_MuzzleClimb(0,0,-frandom[uzwepsrand](0.1, 0.3), -frandom[uzwepsrand](0.4, 0.8));
                A_ZoomRecoil(0.99);
                A_WeaponBusy(false);
            }
            #### # 1 bright A_Light2();
            goto lightdone;


        reload:
            //abort if all mag slots taken or no spare ammo
            #### # 0 A_JumpIf(
                (
                    invoker.weaponStatus[RIPRS_MAG1] >= 0
                    && invoker.weaponStatus[RIPRS_MAG2] >= 0
                    && invoker.weaponStatus[RIPRS_MAG3] >= 0
                )
                || !countinv("HD4mMag"),
                "nope"
            );
            #### # 0 {
                invoker.weaponStatus[0] &= ~(RIPRF_JUSTUNLOAD|RIPRF_LOADCELL);
            }
            goto lowertoopen;

        altreload:
        cellreload:
            #### # 0 {
                int batt = invoker.weaponStatus[RIPRS_BATTERY];

                if (pressingUse()) {
                    invoker.weaponStatus[0] |= RIPRF_JUSTUNLOAD;
                    invoker.weaponStatus[0] |= RIPRF_LOADCELL;
                    SetWeaponState("lowertoopen");
                    return;
                } else if (batt < 20 && countinv("HDBattery")) {
                    invoker.weaponStatus[0] &= ~RIPRF_JUSTUNLOAD;
                    invoker.weaponStatus[0] |= RIPRF_LOADCELL;
                    SetWeaponState("lowertoopen");
                    return;
                }
            }
            goto nope;

        unload:
            #### # 0 {
                if (pressingUse()) {
                    invoker.weaponStatus[0] |= RIPRF_LOADCELL;
                } else {
                    invoker.weaponStatus[0] &= ~RIPRF_LOADCELL;
                }

                invoker.weaponStatus[0] |= RIPRF_JUSTUNLOAD;
            }
            goto lowertoopen;

        //what key to use for cellunload???
        cellunload:
            //abort if no cell to unload
            #### # 0 A_JumpIf(invoker.weaponStatus[RIPRS_BATTERY] < 0, "nope");
            #### # 0 {
                invoker.weaponStatus[0] |= RIPRF_JUSTUNLOAD|RIPRF_LOADCELL;
            }
            goto uncell;

        //lower the weapon, open it, decide what to do
        lowertoopen:
            #### # 2 offset(  0, 36);
            #### # 2 offset( -4, 38) {
                A_StartSound("weapons/vulcclick2", CHAN_WEAPON);
                A_MuzzleClimb(-frandom[uzwepsrand](1.2, 1.8), -frandom[uzwepsrand](1.8, 2.4));
            }
            #### # 1 {
                invoker.isOpen = true;
            }
            #### B 6 offset( -9, 41) A_StartSound("weapons/pocket", CHAN_WEAPON);
            #### # 8 offset(-12, 43) A_StartSound("weapons/vulcopen1", CHAN_WEAPON, CHANF_OVERLAP);
            #### # 5 offset(-10, 41) A_StartSound("weapons/vulcopen2", CHAN_WEAPON, CHANF_OVERLAP);
            #### # 0 A_JumpIf(invoker.weaponStatus[0]&RIPRF_LOADCELL, "uncell");
            #### # 0 A_JumpIf(invoker.weaponStatus[0]&RIPRF_JUSTUNLOAD, "unmag");
            goto loadmag;

        uncell:
            #### # 10 offset(-11, 42) {
                int btt = invoker.weaponStatus[RIPRS_BATTERY];
                invoker.weaponStatus[RIPRS_BATTERY] = -1;

                if (btt >= 0) {
                    if (pressingUnload() || PressingAltReload() || pressingReload()) {
                        A_StartSound("weapons/pocket", CHAN_WEAPON);
                        HDMagAmmo.GiveMag(self, "HDBattery", btt);
                    } else {
                        A_SetTics(4);
                        HDMagAmmo.SpawnMag(self, "HDBattery", btt);
                    }
                }
            }
            goto cellout;

        cellout:
            #### # 0 offset(-10, 40) A_JumpIf(invoker.weaponStatus[0]&RIPRF_JUSTUNLOAD, "reloadend");
        loadcell:
            #### # 0 {
                let bbb = HDMagAmmo(findinventory("HDBattery"));
                if (bbb) invoker.weaponStatus[RIPRS_BATTERY] = bbb.TakeMag(true);
            }
            goto reloadend;

        reloadend:
            #### # 3 offset(-9, 41);
            #### # 2 offset(-6, 38);
            #### # 3 offset(-2, 34);
        reloadendend:
            #### # 1 {
                if (!(pressingReload() || pressingAltReload() || pressingUnload())) {
                    invoker.isOpen = false;
                    setWeaponState("ready");
                }

                A_ReadyEnd();
                A_WeaponReady(WRF_NOFIRE);
            }
            loop;


        unchamber:
            #### # 8 {
                A_StartSound("weapons/vulcextract", CHAN_AUTO, CHANF_DEFAULT, 0.3);
                RIPRNextRound();
            }
            #### # 0 A_JumpIf(pressingUnload(), "unchamber");
            goto nope;
        unmag:
            //if no mags, remove battery
            //if not even battery, remove rounds from chambers
            #### # 0 {
                if (
                    invoker.weaponStatus[RIPRS_MAG1] < 0
                    && invoker.weaponStatus[RIPRS_MAG2] < 0
                    && invoker.weaponStatus[RIPRS_MAG3] < 0
                ) {
                    if (invoker.weaponStatus[RIPRS_BATTERY] >= 0) {
                        SetWeaponState("cellunload");    
                    } else {
                        SetWeaponState("unchamber");
                    }
                }
            }
            //first, check if there's a mag2-3.
            //if there's no mag2 but stuff after that, shunt everything over until there is.
            //if there's nothing but mag1, unload mag1.
            #### # 0 A_JumpIf(!invoker.weaponStatus[0]&RIPRF_JUSTUNLOAD, "loadmag");
            #### # 6 offset(-10, 40) {
                A_StartSound("weapons/vulcmag", CHAN_WEAPON, CHANF_OVERLAP);
                A_MuzzleClimb(-frandom[uzwepsrand](1.2, 1.8), -frandom[uzwepsrand](1.8, 2.4));
            }
        //remove mag #2 first, #1 only if out of options
        unmagpick:
            #### # 0 A_JumpIf(invoker.weaponStatus[RIPRS_MAG2] >= 0, "unmag2");
            #### # 0 A_JumpIf(invoker.weaponStatus[RIPRS_MAG3] >= 0, "unmagshunt");
            #### # 0 A_JumpIf(invoker.weaponStatus[RIPRS_MAG1] >= 0, "unmag1");
            goto reloadend;

        unmagshunt:
            #### # 0 {
                invoker.weaponStatus[RIPRS_MAG2] = invoker.weaponStatus[RIPRS_MAG3];
                invoker.weaponStatus[RIPRS_MAG3] = -1;

                A_StartSound("weapons/vulcshunt", CHAN_WEAPON, CHANF_OVERLAP);
            }
            #### ## 2 offset(-4, 37) A_MuzzleClimb(-frandom[uzwepsrand](0.4, 0.6), frandom[uzwepsrand](0.4, 0.6));
            goto reloadend;

        unmag2:
            #### # 0 {
                int mg = invoker.weaponStatus[RIPRS_MAG2];
                invoker.weaponStatus[RIPRS_MAG2] = -1;

                if (mg >= 0) {
                    if (!(pressingUnload() || pressingReload())) {
                        HDMagAmmo.SpawnMag(self, "HD4mMag", mg);
                        SetWeaponState("mag2out");
                    } else {
                        HDMagAmmo.GiveMag(self, "HD4mMag", mg);
                        SetWeaponState("pocketmag");
                    }
                }
            }
            goto mag2out;

        unmag1:
            #### # 0 {
                int mg = invoker.weaponStatus[RIPRS_MAG1];
                invoker.weaponStatus[RIPRS_MAG1] = -1;

                if (mg >= 0) {
                    if (!(pressingUnload() || pressingReload())) {
                        HDMagAmmo.SpawnMag(self, "HD4mMag", mg);
                        SetWeaponState("mag2out");
                    } else {
                        HDMagAmmo.GiveMag(self, "HD4mMag", mg);
                        SetWeaponState("pocketmag");
                    }
                }
            }
            goto reloadend;

        pocketmag:
            #### # 0 A_StartSound("weapons/pocket");
            #### ## 6 offset(-10, 40) A_MuzzleClimb(frandom[uzwepsrand](0.4, 0.6), -frandom[uzwepsrand](0.4, 0.6));
        mag2out:
            #### # 1 offset(-10, 40) {
                for (int i = RIPRS_MAG2; i < RIPRS_MAG3; i++) invoker.weaponStatus[i] = invoker.weaponStatus[i+1];

                invoker.weaponStatus[RIPRS_MAG3] = -1;

                A_StartSound("weapons/vulcshunt", CHAN_WEAPON, CHANF_OVERLAP);
            }
            #### ## 2 offset(-10, 40) A_MuzzleClimb(-frandom[uzwepsrand](0.4, 0.6), frandom[uzwepsrand](0.4, 0.6));
            #### # 6 offset(-10, 40) A_JumpIf(invoker.weaponStatus[RIPRS_MAG2] < 0, "reloadend");
            goto unmag2;

        loadmag:
            //pick the first empty slot and fill that
            #### # 0 A_StartSound("weapons/pocket");
            #### ## 6 offset(-10, 40) A_MuzzleClimb(-frandom[uzwepsrand](0.4, 0.6), frandom[uzwepsrand](-0.4, 0.4));
            #### # 6 offset(-10, 41) {
                if (HDMagAmmo.NothingLoaded(self, "HD4mMag")) {
                    SetWeaponState("reloadend");
                    return;
                }

                A_StartSound("weapons/vulcmag", CHAN_WEAPON, CHANF_OVERLAP);

                int magslot = -1;
                for (int i = RIPRS_MAG1; i <= RIPRS_MAG3; i++) {
                    if (invoker.weaponStatus[i] < 0) {
                        magslot = i;
                        break;
                    }
                }
                
                if (magslot < 0) {
                    SetWeaponState("reloadend");
                    return;
                }
                
                int lod = HDMagAmmo(findinventory("HD4mMag")).TakeMag(true);
                if (lod < 51) {
                    if (!random[uzwepsrand](0, 7)) {
                        A_StartSound("weapons/vulcforcemag",CHAN_WEAPON,CHANF_OVERLAP);

                        lod = max(0, lod - random[uzwepsrand](0, 1));

                        A_Log(StringTable.Localize("$426MAGMSG"),true);

                        if (magslot == RIPRS_MAG1) invoker.weaponStatus[0] |= RIPRF_DIRTYMAG;
                    }
                } else if (magslot == RIPRS_MAG1) {
                    invoker.weaponStatus[0] &= ~RIPRF_DIRTYMAG;
                }

                invoker.weaponStatus[magslot] = lod;

                A_MuzzleClimb(-frandom[uzwepsrand](0.4, 0.8), -frandom[uzwepsrand](0.5, 0.7));
            }
            #### # 8 offset(-9, 38) {
                A_StartSound("weapons/vulcclick", CHAN_WEAPON, CHANF_OVERLAP);
                A_MuzzleClimb(
                    -frandom[uzwepsrand](0.2, 0.8), -frandom[uzwepsrand](0.2, 0.3)
                    -frandom[uzwepsrand](0.2, 0.8), -frandom[uzwepsrand](0.2, 0.3)
                );
            }
            #### # 0 A_JumpIf(
                (
                    pressingReload()
                    || pressingUnload()
                    || PressingFire()
                    || !countinv("HD4mMag")
                ) || (
                    invoker.weaponStatus[RIPRS_MAG1] >= 0
                    && invoker.weaponStatus[RIPRS_MAG2] >= 0
                    && invoker.weaponStatus[RIPRS_MAG3] >= 0
                ),
                "reloadend"
            );
            goto loadmag;

        user3:
            RIPG A 0 A_MagManager("HD4mMag");
            goto ready;

        spawn:
            RIPP A -1;
    }
}
