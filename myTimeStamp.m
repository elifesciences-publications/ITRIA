%% myTimeStamp

%{
//-------- TimeStamper ----------

function timeStamp(startTArray, timeArray, imgCount, deltaT, startT, timePoints){
	lastTpoint = 0;
	//setFont("SanSerif", 18, "antialiased");
  	//setColor("white");
  	setForegroundColor(255,255,255);
	if (concatChoice=="yes"){// if images are concatenated take the right start time for each stack
		for (i=0; i<(imgCount); i++){
			print("concat i:  "+i);
			if (i==0){//the first loop is different
				run("Label...", "format=00:00 starting="+startTArray[i]+" interval="+deltaT+
				" x=5 y=20 font=14 text=hr:min range=1-"+timeArray[i]+" use");	
			}else{
				run("Label...", "format=00:00 starting="+startTArray[i]+" interval="+deltaT+
				" x=5 y=20 font=14 text=hr:min range="+(lastTpoint+1)+"-"+(lastTpoint+timeArray[i])+" use");			
			}
			
			lastTpoint = lastTpoint + timeArray[i];			
		}//end of loop through the concat stack		
	}else if (concatChoice=="no"){//if the images are not concatenated
		run("Label...", "format=00:00 starting="+startT+" interval="+deltaT+" x=5 y=20 font=14 text=hr:min range=1-"
		+timePoints+" use");			
	}//end concat choice

}// end function timeStamp

%}

function myTimeStamp(inputImg, timeData)

end