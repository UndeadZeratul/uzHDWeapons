class UZPlacedClaymore : HDUPK {

    //$Category Monsters
    //$Title "Placed Claymore Mine (Friendly)"

    Default {
        Health 1;
        Radius 8;
        Height 16;
        Scale 0.4;

        +SHOOTABLE;
        +NOBLOOD;
        +FRIENDLY;
        +NOTARGET;
        +NOTAUTOAIMED;
        
        hdupk.pickupmessage "$PICKUP_CLAYMORE";
        hdupk.pickuptype "UZClaymoreAmmo";

        Obituary "$OB_CLAYMORE";
    }

    States {
        Spawn:
            CLAP A 35;    
            CLAP A 0 A_StartSound("Claymore/Armed");
        Arm:
            CLAP A 1 {
                // look for a new target in a 90 degree arc to the front of the mine every tic
                // red particles depict the visible arc
                A_LookEx(LOF_NOSOUNDCHECK, 4, HDCONST_ONEMETRE * 8, 0, 90, "Trigger");
                A_ClearTarget();
                A_SpawnParticle("Red", SPF_FULLBRIGHT|SPF_RELATIVE|SPF_NOTIMEFREEZE, 18, 2, 45, 0, 0, 9, 2, 0, 0, 0, 0, 0, 1, -1, 0);
                A_SpawnParticle("Red", SPF_FULLBRIGHT|SPF_RELATIVE|SPF_NOTIMEFREEZE, 18, 2, -45, 0, 0, 9, 2, 0, 0, 0, 0, 0, 1, -1, 0);
            }
            Loop;
        Trigger:
            CLAP A 8 A_StartSound("Claymore/Trigger");
            CLAP A 0 A_Die;
        Death:
            TNT1 A 0 {
				let speed = getDefaultByType("HDB_Frag").speed;
				A_SpawnChunks("HDB_frag", 90, speed * 0.8, speed * 1.2, 45, 45);
			}
            stop;
    }
}

class UZEnemyClaymore : PlacedClaymore {
    //$Title "Placed Claymore Mine (Enemy)"

    Default {
        -FRIENDLY;

        Translation "0:255=%[0.00,0.00,0.00]:[1.64,1.13,0.57]";
    }
    
    States {
        Trigger:
            CLAP A 16 A_StartSound ("Claymore/Trigger");
            CLAP A 0 A_Die;
    }
}

class UZClaymoreMine : HDPickup {
    Default {
        +Inventory.invbar

        hdpickup.bulk ENC_CLAYMORE;
        hdpickup.refid UZLD_CLAYMORE;

		scale 0.25;

        tag "$TAG_CLAYMORE";
        Inventory.PickupMessage "$PICKUP_CLAYMORE";
        Inventory.Icon "CLAYITEM";
    }

    action void A_PlantClaymore() {
        if (invoker.amount < 1) {
            invoker.destroy();
            return;
        }

        vector3 startpos = HDMath.GetGunPos(self);
        flinetracedata dlt;
        linetrace(
            angle, 96, pitch, flags: TRF_THRUACTORS,
            offsetz: startpos.z,
            data: dlt
        );

        if(
            !dlt.hitType == TRACE_HitFloor
            || HDF.linetracehitsky(dlt)
        ){
            A_Log(string.format(StringTable.Localize("$DORBUSTLOG1")), true);
            return;
        }

        vector3 plantspot = dlt.hitlocation;
        let ddd = PlacedClaymore(spawn("PlacedClaymore", plantspot, ALLOW_REPLACE));

        if (!ddd) {
            A_Log(StringTable.Localize("$DORBUSTLOG2"), true);
            return;
        }

        ddd.A_StartSound("doorbuster/stick");
        ddd.translation = translation;
        ddd.master = invoker.owner;
        ddd.angle = self.angle;
        
        string feedback = StringTable.Localize("$DORBUSTLOG3");

        if (HDWeapon.CheckDoHelpText(self)) feedback.appendformat(StringTable.Localize("$DORBUSTLOG4"));
        
        A_Log(feedback, true);
        
        invoker.amount--;
        if (invoker.amount < 1) invoker.destroy();
    }
  
    States {
        Spawn:
            CLAP A -1;
            stop;
        use:
            TNT1 A 0 A_PlantClaymore();
            fail;
    }
}

class UZClaymoreMineBox : HDUPK {

    //$Category Monsters
    //$Title "Box of Claymore Mines"

    Default {
        Scale 0.4;

        tag "$TAG_CLAYMORE_BOX";

        hdupk.amount 5;
        hdupk.pickupmessage "$PICKUP_CLAYMORE_BOX";
        hdupk.pickuptype "UZClaymoreAmmo";
    }

    States {
        Spawn:
            CLAA A -1;    
            stop;
    }
}