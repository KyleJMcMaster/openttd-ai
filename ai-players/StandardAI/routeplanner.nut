
 class RoutePlanner
 {

 }

 class RouteCandidate {
    produceID = null;    // Source Industry ID
    acceptID = null;     // Sink Industry ID
    cargoID = null;      // Cargo Type
    surplus = -1;         // Remaining production
    distance = -1;        // Distance between them
	expected_profit = -1;
	engineID = null;
	cost = -1;


    constructor(p, a, c, s, d) {
        produceID = p;
        acceptID = a;
        cargoID = c;
        surplus = s;
        distance = d;
    }
}

function CompareRouteCandidates(a, b) {
    if (a.expected_profit > b.expected_profit) return -1;
    if (a.expected_profit < b.expected_profit) return 1;
    return 0;
}
function FastGetRouteProfit(routeCandidate, eID) {
	if (!AIEngine.CanRefitCargo(eID, routeCandidate.cargoID)){
		return [-999999999,99999999];
	}

	local num_trips = routeCandidate.surplus / AIEngine.GetCapacity(eID);
	local days_in_transit = routeCandidate.distance / AIEngine.GetMaxSpeed(eID);
	local num_vehicles = 0.0667 * days_in_transit * num_trips;
	local monthly_cost_per_vehicle = AIEngine.GetPrice(eID) / (AIEngine.GetMaxAge(eID) / 30) + AIEngine.GetRunningCost(eID) / 12; // capex / (lifespan in days / 30 days per month) + running cost per year / 12 months per year
	local build_cost = AIRoad.GetBuildCost(AIRoad.ROADTYPE_ROAD, AIRoad.BT_ROAD) * routeCandidate.distance
	local operational_cost = num_vehicles * monthly_cost_per_vehicle + build_cost / 60; // 5 year time horizon for builds

	local upfront_cost = build_cost + num_vehicles * AIEngine.GetPrice(eID);
	local operational_profit = AICargo.GetCargoIncome(routeCandidate.cargoID, routeCandidate.distance, days_in_transit) * routeCandidate.surplus - operational_cost;

	return [operational_profit, upfront_cost];
}

function GetCandidateVehicles(vehicle_type, cargoID){
	// gets all vehicles which could return the best profit. Groups by speed, then finds vehicle which minimizes (1/c)*(2p/a + r/180)
	local engine_list = AIEngineList(vehicle_type);
	foreach (eID, _ in engine_list) {
		engine_list.SetValue(eID, AIEngine.CanRefitCargo(eID, cargoID));
	}
	engine_list.KeepValue(1);
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
	local cargos = [];

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


	//local candidate_engines = GetCandidateVehicles(AIVehicle.VT_ROAD);
	local candidate_engines = AIEngineList(AIVehicle.VT_ROAD);
	foreach (eID, _ in candidate_engines) {
		AILog.Info(AIEngine.GetName(eID));
	}
	local i = 0;
	foreach (candidate in candidates) {
		local max_profit = -1;
		local max_engine = -1;
		local max_cost = -1;
		foreach (eID, _ in candidate_engines) {
			local result = FastGetRouteProfit(candidate, eID);
			//AILog.Info(profit);
			if (result[0] > max_profit){
				max_profit = result[0];
				max_engine = eID;
				max_cost = result[1];
			}
		}
		candidate.expected_profit = max_profit;
		candidate.engineID = max_engine;
		candidate.cost = max_cost;

		AILog.Info("Route " + i + " from " + candidate.produceID + " to " + candidate.acceptID + " transporting " + candidate.surplus + " units of " + AICargo.GetName(candidate.cargoID) + " a distance of " + candidate.distance +
	" with expected profit of " + max_profit + " using vehicle " + AIEngine.GetName(max_engine) + " with cost " + max_cost);
		i++;
	}

	candidates.sort(CompareRouteCandidates);
	AILog.Info("\n-------BEST ROUTES-------\n")
	for (local i = 0; i < 5; i++){
		local candidate = candidates[i];
		AILog.Info(AIIndustry.GetName(candidate.produceID) + " to " + AIIndustry.GetName(candidate.acceptID) + " transporting " + AICargo.GetName(candidate.cargoID) + " a distance of " + candidate.distance +
	" with expected profit of " + candidate.expected_profit + " using vehicle " + AIEngine.GetName(candidate.engineID) + " with cost " + candidate.cost);
	}





    return candidates;
}