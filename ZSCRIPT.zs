version 4.14

// Loadout Codes (RefIDs)
const UZLD_BHG                = "bhg";
const UZLD_CLAYMORE           = "cly";
const UZLD_LANDMINE           = "min";

// Encumbrance/Bulk Constants
const ENC_CLAYMORE            = ENC_FRAG;
const ENC_LANDMINE            = 16;


// Weapons
#include "zscript/undeadzeratul/weapons/black-hole-generator/BlackHoleGenerator.zs"
#include "zscript/undeadzeratul/weapons/claymore-mines/ClaymoreMines.zs"
#include "zscript/undeadzeratul/weapons/land-mines/LandMines.zs"

// Event Handlers
#include "zscript/undeadzeratul/weapons/handlers/EasterEggHandler.zs"
#include "zscript/undeadzeratul/weapons/handlers/SpawnHandler.zs"
