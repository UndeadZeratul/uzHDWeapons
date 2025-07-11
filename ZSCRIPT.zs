version 4.14

// Loadout Codes (RefIDs)
const UZLD_BHG                = "bhg";
const UZLD_CLAYMORE           = "cly";
const UZLD_PIPEBOMBS          = "pbg";
const UZLD_PIPEBOMB_DETONATOR = "pbd";

// Encumbrance/Bulk Constants
const ENC_CLAYMORE            = ENC_FRAG;
const ENC_PIPEBOMBS           = 19;
const ENC_PIPEBOMB_DETONATOR  = 10;

// Weapons
#include "zscript/undeadzeratul/weapons/black-hole-generator/BlackHoleGenerator.zs"
#include "zscript/undeadzeratul/weapons/claymore-mines/ClaymoreMines.zs"
#include "zscript/undeadzeratul/weapons/pipe-bombs/PipeBombs.zs"

// Event Handlers
#include "zscript/undeadzeratul/weapons/handlers/EasterEggHandler.zs"
#include "zscript/undeadzeratul/weapons/handlers/SpawnHandler.zs"
