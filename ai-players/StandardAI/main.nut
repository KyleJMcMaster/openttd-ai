require("routeplanner.nut");


 class StandardAI extends AIController
 {
  function Start();
 }


 function StandardAI::Start()
 {
   AILog.Info("StandardAI Started.");
   SetCompanyName();

   //Keep running. If Start() exits, the AI dies.
   while (true) {
    RoutePlanner.GetCandidateRoutes();
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


