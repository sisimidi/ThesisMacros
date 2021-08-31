/*Macro used to create images for montages from representative nuclei 
 *and plot the signal distribution through the chromocenter
 * Macro can be adapted for use in monolayer cells (Z-projections) or 
 * multilayer cells (choosing a slice)
 * Macro uses image of a colony and asks to draw rectangle around nucleus
 * Macro can be adapted for use with 2 and 3 channels
*/
inputFolder = getDirectory("Choose the folder containing your images");
outputFolder = getDirectory("Choose the folder where you want to save your results");

list = getFileList(inputFolder);  
count = list.length;

print("There are " + count + " images to be processed");
run("Set Measurements...", "area mean min limit display redirect=None decimal=4");


for (j=0; j<count; j++) {
	fileName = inputFolder + list[j];
	run("Bio-Formats Importer", "open=["+ fileName +"] autoscale color_mode=Composite rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT");
	title = getTitle;
	run("Duplicate...", "duplicate");
	run("Z Project...", "projection=[Max Intensity]");
	//waitForUser("Use slider to select Z-Slice you want to quantify");
	//Stack.getPosition(channel, slice, frame);
	//Stack.setSlice(slice);
	//run("Duplicate...", "title=Dup duplicate slices=" + slice);
	rename("Dup");
	selectWindow("Dup");
	run("Brightness/Contrast...");
	Stack.setChannel(1);
	resetMinAndMax();
	Stack.setChannel(2);
	resetMinAndMax();
	Stack.setChannel(3);
	resetMinAndMax();
	setTool("rectangle");
	waitForUser("Draw around nucleus");
	run("Duplicate...", "title=Display duplicate channels=1-2");
	selectWindow("Display");
	run("Split Channels");
	run("Merge Channels...", "c2=C1-Display c3=C2-Display create keep ignore");
	//run("Merge Channels...", "c2=C1-Display c3=C2-Display c6=C3-Display create keep ignore");
	rename("Composite");
	run("Duplicate...", "title=Chromocenter duplicate");
	selectWindow("Composite");
	run("Scale Bar...", "width=5 height=5 font=18 color=White background=None location=[Lower Right] hide overlay");
	run("RGB Color");
	run("Flatten");
	saveAs("tiff", outputFolder+title+"Nucleus");
	selectWindow("Chromocenter");
	setTool("rectangle");
	waitForUser("Draw around chromocenter");
	run("Duplicate...", "title=Chromocenter-2 duplicate");
	selectWindow("Chromocenter-2");
	run("RGB Color");
	saveAs("tiff", outputFolder+title+"Chromocenter");
	selectWindow("C1-Display");
	run("Grays");
	run("RGB Color");
	saveAs("tiff", outputFolder + "Green-" + title);
	selectWindow("C2-Display");
	run("Grays");
	run("RGB Color");
	saveAs("tiff", outputFolder + "Blue-" + title);
	//selectWindow("C3-Display");
	//run("Grays");
	//run("RGB Color");
	//saveAs("tiff", outputFolder + "Mag-" + title);
	selectWindow("Chromocenter");
	run("RGB Color");
	setTool("line");
	selectWindow("Chromocenter (RGB)");
	waitForUser("Draw line over chromocenter");
		
		 ylabel = "Intensity";
 		 if (bitDepth!=24)
   			  exit("RGB image required");
 				setKeyDown("none");
  				setRGBWeights(1,0,0); r=getProfile();
 				setRGBWeights(0,1,0); g=getProfile();
  				setRGBWeights(0,0,1); b=getProfile();
  				getVoxelSize(vw, vh, vd, unit);
  			x = newArray(r.length);
  			for (i=0; i<x.length; i++)
    			 x[i] = i*vw;
 				 Plot.create("RGB Profiles","Distance ("+unit+")", ylabel);
 				 ymax = getMax(r,g,b)+5;
  				//if (ymax>255) ymax=255;
 				Plot.setLimits(0, (r.length-1)*vw, 0, ymax);
  				Plot.setColor("magenta");
  				Plot.add("line", x, r);
  				Plot.setColor("green");
  				Plot.add("line", x, g);
  				Plot.setColor("blue");
  				Plot.add("line", x, b);
  				Plot.update();

  			function getMax(a,b,c) {
     			max=a[0];
     		for (i=0; i<a.length; i++) {
        		max = maxOf(max,a[i]);
       			max = maxOf(max,b[i]);
        		max = maxOf(max,c[i]);
     		}
     		return max;
  		}
  		
	pos=indexOf(title, '-');
	name=substring(title, 0, pos);
	saveAs("Tiff", outputFolder +"Plot profile-" + name);	
	run("Close All");
	
}