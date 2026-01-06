 import("pathfinder.road", "RoadPathFinder", 3);

 class RoutePlanner
 {

 }

 class RouteCandidate {
    produceID = null;    // Source Industry ID
    acceptID = null;     // Sink Industry ID
    cargoID = null;      // Cargo Type
    surplus = -1;         // Remaining production
    distance = -1;        // Distance between them


    constructor(p, a, c, s, d) {
        produceID = p;
        acceptID = a;
        cargoID = c;
        surplus = s;
        distance = d;
    }
}

function CompareRouteCandidates(a, b) {
    if (a.surplus > b.surplus) return -1;
    if (a.surplus < b.surplus) return 1;
    return 0;
}
function FastGetIncome(routeCandidate, vID)

 function RoutePlanner::GetCandidateRoutes() {
 	local candidates = [];
    local industries = AIIndustryList();

    foreach (pID, _ in industries) {
        local producedCargoes = AICargoList_IndustryProducing(pID);

        foreach (cID, _ in producedCargoes) {
            local surplus = AIIndustry.GetLastMonthProduction(pID, cID) -
                            AIIndustry.GetLastMonthTransported(pID, cID);

            if (surplus < 20) continue; // Skip low production

            // Find industries that accept this cargo
            local acceptors = AIIndustryList_CargoAccepting(cID);
            foreach (aID, _ in acceptors) {
                local dist = AIMap.DistanceManhattan(AIIndustry.GetLocation(pID),
                                                     AIIndustry.GetLocation(aID));

                candidates.push(RouteCandidate(pID, aID, cID, surplus, dist));
            }
        }
    }

    // Sort candidates by surplus (highest first)
    candidates.sort(CompareRouteCandidates);
	local i = 0
	foreach (candidate in candidates) {
		AILog.Info("Route " + i + " from " + candidate.produceID + " to " + candidate.acceptID + " transporting " + candidate.surplus + " units of " + AICargo.GetName(candidate.cargoID) + " a distance of " + candidate.distance);
		i++;
	}


    return candidates;
}