//Macro for quantifying mean signal intensity of specific antibody inside nucleus 
inputFolder = getDirectory("Choose the folder containing your images");

list = getFileList(inputFolder);  
count = nImages;
run("Set Measurements...", "area mean min limit display redirect=None decimal=4");

fullDir=getFileList(inputFolder)
for (i=0; i<fullDir.length; i++) {
	fileName = inputFolder + list[i];
	run("Bio-Formats Importer", "open=["+ fileName +"] autoscale color_mode=Composite rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT");
	title = getTitle;
	run("Duplicate...", "duplicate"); 
	rename("Dup");
	selectWindow("Dup");
	run("Stack to Images");
	selectWindow("Dup-0001");
	run("Duplicate...", " ");
	run("Gaussian Blur...", "sigma=2");
//run("Threshold...");
	setAutoThreshold("Otsu dark");
	setOption("BlackBackground", true);
	waitForUser("adjust threshold");
	run("Convert to Mask");
	run("Watershed");
	run("Analyze Particles...", "size=50-Infinity clear add exclude");
	waitForUser("add or remove ROI");
	/// check which channel is the one you want to measure before running the macro
	selectWindow("Dup-0003");
	run("From ROI Manager");
	roiManager("Deselect");
	roiManager("Measure");
	String.copyResults();
	waitForUser("copy results to excel");
	run("Clear Results");
	roiManager("Deselect");
	roiManager("Delete");
	run("Close All");
}