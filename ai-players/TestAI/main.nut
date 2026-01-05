
 class TestAI extends AIController
 {
  function Start();
 }
 
 
 function TestAI::Start()
 {
   AILog.Info("TestAI Started.");
   SetCompanyName();

   local sum = testadd(10,5);
   AILog.Info("Printed: " + sum);
  
   //set a legal railtype. 
   local types = AIRailTypeList();
   AIRail.SetCurrentRailType(types.Begin());
       
   //Keep running. If Start() exits, the AI dies.
   while (true) {
     this.Sleep(100);
     AILog.Warning("TODO: Add functionality to the AI.");
   }
 }
 
 function TestAI::Save()
 {
   local table = {};	
   //TODO: Add your save data to the table.
   return table;
 }
 
 function TestAI::Load(version, data)
 {
   AILog.Info(" Loaded");
   //TODO: Add your loading routines.
 }
 
 
 function TestAI::SetCompanyName()
 {
   if(!AICompany.SetName("Testing AI")) {
     local i = 2;
     while(!AICompany.SetName("Testing AI #" + i)) {
       i = i + 1;
       if(i > 255) break;
     }
   }
   AICompany.SetPresidentName("P. Resident");
 }