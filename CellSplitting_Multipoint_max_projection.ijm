/*
 * Macro for saving single nuclei from image of colony												
 * To be used for cells growing as a monolayer
 */

//--------------------------------//-----------------------------------------------------------------------------------
//-- Part 0: Preparation steps: get directories from user
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
	run("Bio-Formats Importer", "open=[" + path + "] autoscale color_mode=Composite concatenate_series rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT series_1");
	ori = getTitle();
	
	
	setTool("rectangle");
	waitForUser("Draw around cells and add to ROI Manager by pressing 't' after each one");

	nROIs = roiManager("Count");

	for (r = 0; r<nROIs; r++){
		selectWindow(ori);
		roiManager("Select", r);	
		run("Duplicate...", "duplicate");
		run("Z Project...", "projection=[Max Intensity]");
		saveAs("Tiff", outputFolder + ori + "_Nucleus_" + r+1);	
	}

	run("Close All");
	roiManager("Reset");
}

// Let user know it's done!
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





