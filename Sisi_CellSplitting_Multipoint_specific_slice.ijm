/*
 * Macro for saving single nuclei from image of colony
 * To be used for cells growing in 3D																																	
 * Macro will can process up to 2 slices of the stack (in case stack is large enough)
 */
 // Part 0: Define function

function zslideSave(i) { 
// function description: select z-slice to isolate nuclei and saves them individually
	Stack.setChannel(1);
	resetMinAndMax();
	Stack.setChannel(2);
	resetMinAndMax();
	waitForUser("Use slider to select Z-Slice you want to quantify");

	Stack.getPosition(channel, slice, frame);
	Stack.setSlice(slice);
	run("Duplicate...", "title=Dup duplicate slices=" + slice);
	selectWindow("Dup");
	run("Duplicate...", "title=split duplicate");
	run("Split Channels");
	//for 3 channels 
	//check if channels are correct c2-green; c3-blue; c6-magenta 
	run("Merge Channels...", "c2=C1-split c3=C2-split c6=C3-split create keep ignore");
	//for 2 channels
	//run("Merge Channels...", "c2=C1-split c3=C2-split create keep ignore");
	rename("Composite");
	//check if DAPI channel is selected
	selectWindow("C2-split");
	run("Duplicate...", "title=threshold duplicate");
	run("Gaussian Blur...", "sigma=2 stack");

	setAutoThreshold("Intermodes dark");
	setOption("BlackBackground", true);
	waitForUser("Adjust threshold");
	run("Convert to Mask");
	run("Watershed Irregular Features", "erosion=50 convexity_threshold=0 separator_size=0-Infinity");
	run("Analyze Particles...", "size=50-Infinity exclude add");
	waitForUser("Add or remove nuclei");
	

	nROIs = roiManager("Count");

	for (r = 0; r<nROIs; r++){
		selectWindow("Composite");
		roiManager("Select", r);	
		run("Enlarge...", "enlarge=2");
		run("Fit Rectangle");
		run("Duplicate...", "duplicate");
		saveAs("Tiff", outputFolder + ori + slice + "_Nucleus_" + r+1);	
		run("Close");
	}

	roiManager("Reset");
	selectWindow("nuc");
	close("\\Others");
	}


//--------------------------------//-----------------------------------------------------------------------------------
//-- Part 1: Preparation steps: get directories from user
//--------------------------------//-----------------------------------------------------------------------------------

inputFolder = getDirectory("Choose the folder containing your images");
outputFolder = getDirectory("Choose the folder where you want to save your results");

dirList = newArray();
dirList = getFileTree(inputFolder, dirList);

count = dirList.length
print("There are " + count + " images to be processed");

//--------------------------------//-----------------------------------------------------------------------------------
//-- Part 0: Preparation steps: get directories from user
//--------------------------------//-----------------------------------------------------------------------------------

for (i = 0; i < dirList.length; i++) {
	path = dirList[i];
	run("Bio-Formats Importer", "open=[" + path + "] autoscale color_mode=Default concatenate_series rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT series_1");
	ori = getTitle();
	run("Duplicate...", "title=nuc duplicate");
	run("Duplicate...", "duplicate");
	zslideSave(i);

	Dialog.create(" New Slice?");
	Dialog.addMessage("Do you want to select another slice?");
	Dialog.addChoice("Type:", newArray("Yes", "No"));
	Dialog.show();

	choice = Dialog.getChoice();
	
	if (choice == "Yes"){
		String.resetBuffer;
		selectWindow("nuc");
		run("Duplicate...", "duplicate");
		
		zslideSave(i);
		run("Collect Garbage");
	}

		run("Close All");
}

// Let user know it's done!
run("Collect Garbage");
Dialog.create("Progress"); 
Dialog.addMessage("Macro Complete!");
Dialog.show;

function getFileTree(dir , fileTree){
	list = getFileList(dir);

	for(f = 0; f < list.length; f++){
		if (matches(list[f], "(?i).*\\.(tif|tiff|nd2|lif|ndpi|mvd2|ims|oib)$"))
			fileTree = Array.concat(fileTree, dir + list[f]);
		if(File.isDirectory(dir + File.separator + list[f]))
			fileTree = getFileTree(dir + list[f],fileTree);
	}
	return fileTree;





