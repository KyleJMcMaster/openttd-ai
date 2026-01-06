
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
function FastGetRouteProfit(routeCandidate, eID) {
	if (!AIEngine.CanRefitCargo(eID, routeCandidate.cargoID)){
		return 0;
	}

	local num_trips = routeCandidate.surplus / AIEngine.GetCapacity(eID);
	local days_in_transit = routeCandidate.distance / AIEngine.GetMaxSpeed(eID);
	local num_vehicles = 0.0667 * days_in_transit * num_trips;
	local monthly_cost_per_vehicle = AIEngine.GetPrice(eID) / (AIEngine.GetMaxAge(eID) / 30) + AIEngine.GetRunningCost(eID) / 12; // capex / (lifespan in days / 30 days per month) + running cost per year / 12 months per year
	local build_cost = AIRoad.GetBuildCost(AIRoad.ROADTYPE_ROAD, AIRoad.BT_ROAD) * routeCandidate.distance / 60 // 5 year time horizon
	local operational_cost = num_vehicles * monthly_cost_per_vehicle + build_cost;

	return AICargo.GetCargoIncome(routeCandidate.cargoID, routeCandidate.distance, days_in_transit) * routeCandidate.surplus - operational_cost;
}

function GetCandidateVehicles(vehicle_type){
	// gets all vehicles which could return the best profit. Groups by speed, then finds vehicle which minimizes (1/c)*(2p/a + r/180)
	local engine_list = AIEngineList(vehicle_type);
	engine_list.Valuate(AIEngine.GetMaxSpeed);
	local candidate_list = AIList();
	local candidate_speeds = AIList();

	foreach (eID, speed in engine_list) {
		local score = (1000 * (1.0 / AIEngine.GetCapacity(eID)) * ((2 * AIEngine.GetPrice(eID) / AIEngine.GetMaxAge(eID)) + (AIEngine.GetRunningCost(eID) / 180))).tointeger();
		if (candidate_speeds.HasItem(speed)){
			if (candidate_speeds.GetValue(speed) > score){
				candidate_speeds.SetValue(speed, score);
				candidate_list.SetValue(speed, eID);
			}
		}
		else{
			candidate_speeds.AddItem(speed, score);
			candidate_list.AddItem(speed, eID);
		}
	}
	local engines = [];
	foreach (speed, eID in candidate_list) {
		engines.push(eID);
	}
	return engines;
}

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
    // candidates.sort(CompareRouteCandidates);


	local candidate_engines = GetCandidateVehicles(AIVehicle.VT_ROAD);
	foreach (eID in candidate_engines) {
		AILog.Info(eID);
	}
	local i = 0;
	foreach (candidate in candidates) {
		local max_profit = -1;
		local max_engine = -1;
		foreach (eID in candidate_engines) {
			local profit = FastGetRouteProfit(candidate, eID);
			if (profit > max_profit){
				max_profit = profit;
				max_engine = eID;
			}
		}
		AILog.Info("Route " + i + " from " + candidate.produceID + " to " + candidate.acceptID + " transporting " + candidate.surplus + " units of " + AICargo.GetName(candidate.cargoID) + " a distance of " + candidate.distance +
	" with expected profit of " + max_profit + " using vehicle " + max_engine);
		i++;
	}





    return candidates;
}