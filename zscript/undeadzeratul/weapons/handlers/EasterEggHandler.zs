class UZWeaponsEasterEggsHandler : EventHandler {
    override void NetworkProcess(ConsoleEvent e) {
        if (e.IsManual || !PlayerInGame[e.Player] || !(PLAYERS[e.Player].mo)) return;

        let hpl = HDPlayerPawn(PLAYERS[e.Player].mo);

        if (!hpl) return;

        if (e.Name == 'IsActualBlackHole') {
            let bhg = UZBHGen(hpl.FindInventory('UZBHGen'));

            if (bhg) {
                bhg.actualBlackHole = e.Args[0];
            }
        }
    }
}