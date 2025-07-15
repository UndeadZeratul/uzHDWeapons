class UZLaserTripBomb : HDPickup {

    default {
        //$Category "Gear/Hideous Destructor/Supplies"
        //$Title "Laser Tripbomb"
        //$Sprite "LTBPA0"

        +inventory.invbar

        hdpickup.bulk ENC_LASERTRIPBOMB;
        hdpickup.refid UZLD_LASERTRIPBOMB;
        
        tag "$TAG_LASER_TRIPBOMB";
        inventory.pickupmessage "$PICKUP_LASER_TRIPBOMB";
        inventory.icon "LTBPA0";
        
        scale 0.5;
    }
    
    action void A_PlantLTB() {
        if (invoker.amount < 1) {
            invoker.destroy();
            return;
        }

        vector3 startpos = HDMath.GetGunPos(self);

        flinetracedata dlt;
        linetrace(
            angle, 48, pitch, flags: TRF_THRUACTORS,
            offsetz: startpos.z,
            data: dlt
        );

        if(
            !dlt.hitline
            || HDF.linetracehitsky(dlt)
        ){
            A_Log(string.format(StringTable.Localize("$LASERTRIPBOMBLOG1")), true);
            return;
        }

        vector3 plantspot = dlt.hitlocation - dlt.hitdir;
        let ddd = UZLaserTripBombPlanted(spawn("UZLaserTripBombPlanted", plantspot, ALLOW_REPLACE));
        if (!ddd) {
            A_Log(StringTable.Localize("$LASERTRIPBOMBLOG2"),true);
            return;
        }

        ddd.A_StartSound("weapons/LaserTripbomb/plant",CHAN_BODY);

        let delta = -dlt.hitline.delta;
        if (dlt.lineside == line.back) delta = -delta;

        ddd.translation = translation;
        ddd.master      = self;
        ddd.angle       = VectorAngle(-delta.y, delta.x);

        string feedback = StringTable.Localize("$LASERTRIPBOMBLOG3");
        if (HDWeapon.CheckDoHelpText(self)) feedback.appendformat(StringTable.Localize("$LASERTRIPBOMBLOG4"));
        A_Log(feedback, true);

        invoker.amount--;
        if (invoker.amount < 1) invoker.destroy();
    }

    states {
        spawn:
            LTBP A -1;
            stop;
        use:
            TNT1 A 0 A_PlantLTB();
            fail;
    }
}

class UZLaserTripBombPlanted : HDUPK {

    default {
        +NOGRAVITY
        +SHOOTABLE
        +WALLSPRITE

        health 10;
        height 4;
        radius 3;
        scale 0.25;
    }

    override bool OnGrab(actor grabber) {
        actor dbbb = spawn("UZLaserTripBomb", pos, ALLOW_REPLACE);
        dbbb.translation = self.translation;
        GrabThinker.Grab(grabber, dbbb);

        destroy();
        return false;
    }

    action void A_LTBLook() {
        flinetracedata dlt;
        linetrace(
            angle, 1024, pitch,
            data: dlt
        );

        for (let i = 0.0; i < clamp(dlt.distance, 0, 1024); i += 0.5) A_SpawnParticle(
            "Red",
            SPF_FULLBRIGHT|SPF_RELATIVE,
            1, 1, 0,
            i, 0, 0,
            0, 0, 0,
            0, 0, 0,
            1, -1, 0
        );

        if (dlt.hitactor) {
            SetStateLabel("detonate");
            return;
        }
    }

    action void A_Detonate() {
        UZLaserTripBombPlanted.detonate(invoker);
    }

    static void detonate(HDActor caller) {
        caller.bSOLID         = false;
        caller.bPUSHABLE      = false;
        caller.bMISSILE       = false;
        caller.bNOINTERACTION = true;
        caller.bSHOOTABLE     = false;

        caller.A_HDBlast(
            pushradius: 256,
            pushamount: 128,
            fullpushradius: 96,
            fragradius: 256
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
        caller.A_SpawnChunks("HDB_frag", 90, 300, 700, 90, 90);

        DistantNoise.make(caller, "world/rocketfar");
    }

    states {
        spawn:
            LTBA A 12;
        laser:
            #### # 1 A_LTBLook();
            loop;
        detonate:
            #### # 12 A_StartSound("weapons/LaserTripbomb/beep", CHAN_AUTO);
            #### # 0 A_Die();
        Death:
            TNT1 A 0 A_Detonate();
            stop;
    }
}

class UZLaserTripBombP : HDUPK {
    default {
        //+forcexybillboard
        scale 0.5;
        height 6;
        radius 6;

        hdupk.amount 1;
        hdupk.pickuptype "UZLaserTripBomb";
        hdupk.pickupmessage "$PICKUP_LASER_TRIPBOMB";
        hdupk.pickupsound "weapons/rifleclick2";

        stamina 1;
    }

    states {
        spawn:
            LTBP A -1;
    }
}

class UZLaserTripBombPickup : UZLaserTripBombP {
    override void postbeginplay() {
        super.postbeginplay();

        A_SpawnItemEx("UZLaserTripBombP",  8, 8, flags: SXF_NOCHECKPOSITION);
        A_SpawnItemEx("UZLaserTripBombP",  8, 0, flags: SXF_NOCHECKPOSITION);
        A_SpawnItemEx("UZLaserTripBombP",  0, 8, flags: SXF_NOCHECKPOSITION);
        A_SpawnItemEx("UZLaserTripBombP", -8, 8, flags: SXF_NOCHECKPOSITION);
        A_SpawnItemEx("UZLaserTripBombP", -8, 0, flags: SXF_NOCHECKPOSITION);
    }
}