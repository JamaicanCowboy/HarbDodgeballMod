// THIS FILE IS AUTOGENERATED, DO NOT MODIFY
main()
{
	self setModel("xmodel/playerbody_german_waffen_winter");
	character\_utility::attachFromArray(xmodelalias\head_axis::main());
	
	self setViewmodel("xmodel/viewmodel_hands_waffen_winter");
	
	self.voice = "american";
}

precache()
{
	precacheModel("xmodel/playerbody_german_waffen_winter");
	character\_utility::precacheModelArray(xmodelalias\head_axis::main());
	
	precacheModel("xmodel/viewmodel_hands_waffen_winter");
	
}
