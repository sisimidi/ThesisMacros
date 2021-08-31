/*
 * 																					Laura Murphy
 * 																					IGMM Advanced Imaging Resource
 * 																					January 2018												
 */

//--------------------------------//-----------------------------------------------------------------------------------
//-- Part 0: Preparation steps: get directories from user
//--------------------------------//-----------------------------------------------------------------------------------
setBatchMode(true);
inputFolder = getDirectory("Choose the folder containing your images");
outputFolder = getDirectory("Choose the folder where you want to save your results");
list = getFileList(inputFolder);

count = list.length
print("There are " + count + " nuclei to be processed");

Image = newArray;
Slice = newArray;
Label = newArray;
Area = newArray;
C1_Mean = newArray;
C2_Mean = newArray;
//C3_Mean = newArray;
C1_PercentNucleoplasm = newArray;
C2_PercentNucleoplasm = newArray;
//C3_PercentNucleoplasm = newArray;
C2_PosArea = newArray;
//C3_PosArea = newArray;
C2_PercentArea = newArray;
//C3_PercentArea = newArray;
	
//--------------------------------//-----------------------------------------------------------------------------------
//-- Part 1: Open image, duplicate and gaussian blur on both channels
//--------------------------------//-----------------------------------------------------------------------------------
//Macro is designed for 2 or 3 channels,
//if two channels leave as is: channels need to be in this order: 1-Green(histone), 2- Blue(DAPI)
//if three channels remove // from functional lines starting from line 187 and lines 24, 27, 29 and 31
	
for (i=0; i<list.length; i++) {
	open(inputFolder + File.separator + list[i]);
	stack = getTitle();
	//parts = split(stack, ".");
	//imgName = parts[0];

	//Stack.setFrame(5);
	//Stack.setChannel(1);
	resetMinAndMax();
	//Stack.setChannel(2);
	//resetMinAndMax();
	//Stack.setChannel(3);
	//resetMinAndMax();
	
	//waitForUser("Use slider to select Z-Slice you want to quantify");
	Stack.getPosition(channel, slice, frame);
	run("Duplicate...", "title=Dup duplicate");
	run("Duplicate...", "title=Measure duplicate");
	
	
	selectWindow("Dup");
	run("Duplicate...", "title=Display duplicate");
	selectWindow("Dup");
	run("Split Channels");
	
//--------------------------------//-----------------------------------------------------------------------------------
//-- Part 2: Threshold on channel 1 for nucleus - user can adjust, then analyse particles
//--------------------------------//-----------------------------------------------------------------------------------
		//Check if channels are correct in order Green, Blue, //Red
	selectWindow("C2-Dup");
	run("Duplicate...", "title = Masked_Nucleus duplicate");
	run("Grays");
	run("Gaussian Blur...", "sigma=2");
	setAutoThreshold("Intermodes dark");
	run("Convert to Mask");
	run("Watershed Irregular Features", "erosion=50 convexity_threshold=0 separator_size=0-Infinity");
	run("Analyze Particles...", "size=30-Infinity exclude clear add");


	nucCount = roiManager("count");
	if (nucCount == 0){
		run("Close All");
		continue;
	}

	roiManager("select", 0);
	roiManager("Rename", "Nucleus");

//--------------------------------//-----------------------------------------------------------------------------------
//-- Part 3: Threshold on channel 1 for chromocentres - user can adjust, then analyse particles
//--------------------------------//-----------------------------------------------------------------------------------

		//Check if channels are correct in order Green, Blue, //Red
	selectWindow("C2-Dup");
	run("Duplicate...", "title = Masked_Chromo duplicate");
	roiManager("select", 0);
	getStatistics(area, mean, min, max, std, histogram);
	
	nuc_calc = mean + 1.2*std; 
	run("Gaussian Blur...", "sigma=2");
	setAutoThreshold("Default dark");
	setThreshold(nuc_calc, 65535);
		
	run("Analyze Particles...", "  show = None add");
	chromcount = roiManager("count");
	if (chromcount == 1) {
		run("Close All");
		continue;
	}
	if (chromcount > 2) {
		
		chromocentres = newArray; 
	
		for(j = 1; j < chromcount; j++){
			roiManager("Select", j);
			roiManager("Rename", "Chromocentre_"+(j));
			roiManager("Set Color", "cyan");
			chromocentres = Array.concat(chromocentres, j);
		}
	
		// Combine chromocentres and add to ROI, also take XOR between chromocentres and nucleus to be left with remaining nucleus area	
		roiManager("select", chromocentres);
		roiManager("Combine");
		Roi.setName("Combined_chromocentres"); 
		Roi.setStrokeColor("Magenta");
		roiManager("Add");	
		roiManager("Select", newArray(0, chromcount));
		roiManager("XOR");
		Roi.setName("Nucleoplasm");
		Roi.setStrokeColor("Yellow"); 
		roiManager("Add");

	} else {
		
		// Print number of chromocenters
		print("Nucleus_ " + (i+1) + " has 1 chromocentre");
	
		roiManager("select", 1);
		roiManager("Rename", "Chromocentre_1");

		roiManager("Select", newArray(0, 1));
		roiManager("XOR");
		Roi.setName("Nucleoplasm");
		Roi.setStrokeColor("Yellow"); 
		roiManager("Add");
	} 

	selectWindow("Display");
	run("Duplicate...", "duplicate");
	run("RGB Color");
	roiManager("Deselect");
	roiManager("Show All without labels");
	run("Flatten");
	saveAs("PNG", outputFolder + stack + "_Outlines.png");
	
//--------------------------------//-----------------------------------------------------------------------------------
//-- Part 5: Measure and save results. Results table will contain the Image name, the ROI labels and the channel number (after the :)
//--------------------------------//-----------------------------------------------------------------------------------

	run("Set Measurements...", "area mean min display redirect=None decimal=4");

	// change below - creating arrays with results and creating table at end of arrays

	totalROI = roiManager("count");
	
	for(r = totalROI-1; r >= 0; r--){
		roiManager("Select", r);
		getStatistics(area, mean, min, max, std, histogram);
		Image = Array.concat(Image, stack);
		Slice = Array.concat(Slice, frame);
		roiName = Roi.getName;
		Label = Array.concat(Label, roiName);
		Area = Array.concat(Area, area);
		
		selectWindow("Measure");
		Stack.setChannel(1);
		roiManager("Select", r);
		getStatistics(area, C1mean, min, max, C1std, histogram);
		C1_Mean = Array.concat(C1_Mean, C1mean);
		
		selectWindow("Measure");
		Stack.setChannel(2);
		roiManager("Select", r);
		getStatistics(area, C2mean, min, max, C2std, histogram);
		C2_Mean = Array.concat(C2_Mean, C2mean);
		
		
		//selectWindow("Measure");
		//Stack.setChannel(3);
		//roiManager("Select", r);
		//getStatistics(area, C3mean, min, max, C3std, histogram);
		//C3_Mean = Array.concat(C3_Mean, C3mean);	
				
		if (r == totalROI-1){
			C1_calc = C1mean + 1.2*C1std;
			C2_calc = C2mean + 1.2*C2std;
			//C3_calc = C3mean + 1.2*C3std;
			NucPlasmC1 = C1mean;
			NucPlasmC2 = C2mean;
			//NucPlasmC3 = C3mean;
		}
		plasmCalcC1 = 100*(C1mean/NucPlasmC1);
		C1_PercentNucleoplasm = Array.concat(C1_PercentNucleoplasm, plasmCalcC1);
		plasmCalcC2 = 100*(C2mean/NucPlasmC2);
		C2_PercentNucleoplasm = Array.concat(C2_PercentNucleoplasm, plasmCalcC2);	
		//plasmCalcC3 = 100*(C3mean/NucPlasmC3);
		//C3_PercentNucleoplasm = Array.concat(C3_PercentNucleoplasm, plasmCalcC3);	
		
		selectWindow("Measure");
		roiManager("Deselect");
		run("Select None");
	//Check if channels are correct
		run("Duplicate...", "title=Green duplicate channels=1");
		setThreshold(C1_calc, 65535);
		roiManager("Select", r);
		run("Set Measurements...", "area limit display redirect=None decimal=4");
		roiManager("Measure");

		C1area = getResult("Area", 0);
		C1_PosArea = Array.concat(C1_PosArea, C1area);	
	
		run("Clear Results");
		
		selectWindow("Measure");
		roiManager("Deselect");
		run("Select None");
	//Check if channels are correct
		run("Duplicate...", "title=Blue duplicate channels=2");
		setThreshold(C2_calc, 65535);
		roiManager("Select", r);
		run("Set Measurements...", "area limit display redirect=None decimal=4");
		roiManager("Measure");

		C2area = getResult("Area", 0);
		C2_PosArea = Array.concat(C2_PosArea, C2area);	
	
		run("Clear Results");
		//selectWindow("Measure");
		//roiManager("Deselect");
		//run("Select None");
		//run("Duplicate...", "title=Red duplicate channels=3");
		//setThreshold(C3_calc, 65535);
		//roiManager("Select", r);
		//run("Set Measurements...", "area limit display redirect=None decimal=4");
		//roiManager("Measure");
	
		//C3area = getResult("Area", 0);
		//C3_PosArea = Array.concat(C3_PosArea, C3area);		

		C1_Percent = 100*(C1area/area);
		C2_Percent = 100*(C2area/area);
		//C3_Percent = 100*(C3area/area);
		C1_PercentArea  = Array.concat(C1_PercentArea, C1_Percent);
		C2_PercentArea  = Array.concat(C2_PercentArea, C2_Percent);	
		//C3_PercentArea  = Array.concat(C3_PercentArea, C3_Percent);


		run("Clear Results");
		selectWindow("Results");
		run("Close");		
	}

	run("Close All");
	roiManager("reset");
	run("Collect Garbage");

}

Array.show(Image, Slice, Label, Area, C1_Mean, C2_Mean, C1_PercentNucleoplasm, C2_PercentNucleoplasm, C1_PosArea, C1_PercentArea, C2_PosArea, C2_PercentArea);
saveAs("Results", outputFolder + File.separator + "Results.csv");

// Let user know it's done!
Dialog.create("Progress"); 
Dialog.addMessage("Macro Complete!");
Dialog.show;



	