import("pathfinder.road", "RoadPathFinder", 4);

require("routeplanner.nut");


 class StandardAI extends AIController
 {
  function Start();
 }


 function StandardAI::Start()
 {
   AILog.Info("StandardAI Started.");
   SetCompanyName();
    local route = RoutePlanner.GetCandidateRoutes()[0];
    local start = FindStationTile(route.produceID);
    local end = FindStationTile(route.acceptID);
    AILog.Info("Found Start " + start + " and end " + end);

    BuildRoute(start, end);


   while (true) {
    this.Sleep(1000);

   }
 }

 function StandardAI::Save()
 {
   local table = {};
   //TODO: Add your save data to the table.
   return table;
 }

 function StandardAI::Load(version, data)
 {
   AILog.Info(" Loaded");
   //TODO: Add your loading routines.
 }


 function StandardAI::SetCompanyName()
 {
   if(!AICompany.SetName("Standard AI")) {
     local i = 2;
     while(!AICompany.SetName("Standard AI #" + i)) {
       i = i + 1;
       if(i > 255) break;
     }
   }
   AICompany.SetPresidentName("P. Resident");
 }

function StandardAI::GetIndustrySize(industryID){
  local location = AIIndustry.GetLocation(industryID);
  local x = 0;
  local y = 0;
  while (AIIndustry.GetIndustryID(location + AIMap.GetTileIndex(x,0)) == industryID){
    x++;
  }
  while (AIIndustry.GetIndustryID(location + AIMap.GetTileIndex(0,y)) == industryID){
    y++;
  }
  return [x, y];
}


function StandardAI::FindStationTile(industryID) {
    local location = AIIndustry.GetLocation(industryID);
    local size = GetIndustrySize(industryID);
    // Dynamically get the coverage radius for truck stops
    local radius = AIStation.GetCoverageRadius(AIStation.STATION_TRUCK_STOP);
    local top = location - AIMap.GetTileIndex(radius, radius);
    local bottom = location + AIMap.GetTileIndex(size[0], size[1]) + AIMap.GetTileIndex(radius, radius);
    local candidate_spots = AITileList();
    candidate_spots.AddRectangle(top, bottom);

    foreach (spot, _ in candidate_spots) {

    	if (!AIMap.IsValidTile(spot)) continue;

    	// 1. Basic buildability check
    	if (!AITile.IsBuildable(spot)) continue;

    	// 2. Stations must be built on flat land
    	if (AITile.GetSlope(spot) == AITile.SLOPE_FLAT) return spot;
    }

    return null;
}

function StandardAI::BuildRoute(startTile, endTile) {
    // 1. Build the Stations
    // We use a neighboring tile as the "front" to give it a direction
    local frontStart = startTile + AIMap.GetTileIndex(0, 1);
    local frontEnd = endTile + AIMap.GetTileIndex(0, 1);

    AIRoad.BuildRoadStation(startTile, frontStart, AIRoad.ROADVEHTYPE_TRUCK, AIStation.STATION_NEW);
    AIRoad.BuildRoadStation(endTile, frontEnd, AIRoad.ROADVEHTYPE_TRUCK, AIStation.STATION_NEW);

    // 2. Pathfinding
    local pf = RoadPathFinder();
    AIRoad.SetCurrentRoadType(AIRoad.ROADTYPE_ROAD);

    pf.InitializePath([frontStart], [frontEnd]);

    local path = false;
    while (path == false) {
        path = pf.FindPath(1000);
        AIController.Sleep(1);
        if (path == false) AILog.Info("couldn't find path");
    }

    if (path == null) {
    /* No path was found. */
    AILog.Error("pathfinder.FindPath return null");
    }

    // 3. Construct the Road
    while (path != null) {
      local par = path.GetParent();
      if (par != null) {
        local last_node = path.GetTile();
        if (AIMap.DistanceManhattan(path.GetTile(), par.GetTile()) == 1 ) {
          if (!AIRoad.BuildRoad(path.GetTile(), par.GetTile())) {
            /* An error occurred while building a piece of road. TODO: handle it.
            * Note that this could mean the road was already built. */
          }
        } else {
          /* Build a bridge or tunnel. */
          if (!AIBridge.IsBridgeTile(path.GetTile()) && !AITunnel.IsTunnelTile(path.GetTile())) {
            /* If it was a road tile, demolish it first. Do this to work around expended roadbits. */
            if (AIRoad.IsRoadTile(path.GetTile())) AITile.DemolishTile(path.GetTile());
            if (AITunnel.GetOtherTunnelEnd(path.GetTile()) == par.GetTile()) {
              if (!AITunnel.BuildTunnel(AIVehicle.VT_ROAD, path.GetTile())) {
                /* An error occured while building a tunnel. TODO: handle it. */
              }
            } else {
              local bridge_list = AIBridgeList_Length(AIMap.DistanceManhattan(path.GetTile(), par.GetTile()) + 1);
              bridge_list.Valuate(AIBridge.GetMaxSpeed);
              bridge_list.Sort(AIList.SORT_BY_VALUE, false);
              if (!AIBridge.BuildBridge(AIVehicle.VT_ROAD, bridge_list.Begin(), path.GetTile(), par.GetTile())) {
                /* An error occured while building a bridge. TODO: handle it. */
              }
            }
          }
        }
      }
      path = par;
}
}
