// THIS FILE IS AUTOGENERATED, DO NOT MODIFY
main()
{
	self setModel("xmodel/playerbody_russian_conscript_winter");
	character\_utility::attachFromArray(xmodelalias\head_allied::main());
	
	self setViewmodel("xmodel/viewmodel_hands_russian");
	
	self.voice = "american";
}

precache()
{
	precacheModel("xmodel/playerbody_russian_conscript_winter");
	character\_utility::precacheModelArray(xmodelalias\head_allied::main());

	precacheModel("xmodel/viewmodel_hands_russian");
	
}
