import org.json.simple.*;
import org.json.simple.parser.*;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.net.InetSocketAddress;
import java.net.UnknownHostException;
import java.util.Collection;


import org.json.simple.JSONObject;
import org.json.simple.JSONArray;

/* --------------------------------------------------------------------------
 * SimpleOpenNI User Test
 * --------------------------------------------------------------------------
 * Processing Wrapper for the OpenNI/Kinect 2 library
 * http://code.google.com/p/simple-openni
 * --------------------------------------------------------------------------
 * prog:  Max Rheiner / Interaction Design / Zhdk / http://iad.zhdk.ch/
 * date:  12/12/2012 (m/d/y)
 * ----------------------------------------------------------------------------
 */

import SimpleOpenNI.*;

SimpleOpenNI  context;
color[]       userClr = new color[]{ color(255,0,0),
                                     color(0,255,0),
                                     color(0,0,255),
                                     color(255,255,0),
                                     color(255,0,255),
                                     color(0,255,255)
                                   };
PVector com = new PVector();                                   
PVector com2d = new PVector();                                   

void setup()
{
  size(1280, 480);
  
  context = new SimpleOpenNI(this);
  if(context.isInit() == false)
  {
     println("Can't init SimpleOpenNI, maybe the camera is not connected!"); 
     exit();
     return;  
  }
  
  // enable depthMap generation 
  context.enableDepth();
  
  // enable RGB Image
  context.enableRGB(); 
  context.alternativeViewPointDepthToImage();

 
  background(200,0,0);

  stroke(0,0,255);
  strokeWeight(3);
  smooth();  

}

void draw()
{
  // update the cam
  context.update();
  
  //draws the rgb image to the window at position next to the depth image
  image(context.rgbImage(),0,0);
  
  // draw depthImageMap
  image(context.depthImage(),640,0);

}


float z=0;
int corner=0;
String[] jsonString = new String[1];
JSONArray jsonBox = new JSONArray();

void mouseClicked() {
   int offset = mouseY * 640 + mouseX;
   PVector sample = context.depthMapRealWorld()[offset];
   print(sample);
   print('\n');
   JSONArray point = new JSONArray();
   point.add(sample.x);
   point.add(sample.y);
   point.add(sample.z);
   jsonBox.add(point);
   corner+=1;
   if(corner>5){
     corner = 0;
     JSONObject boxObj = new JSONObject();
     boxObj.put("box", jsonBox);
     jsonString[0] = boxObj.toString();
     saveStrings("/tmp/box.json", jsonString);
     jsonBox = new JSONArray();
   }

}


void keyPressed()
{
  print("key");
  print(key);
  print("\n");
  switch(key)
  {
  case 'r':
    corner = 0;
  case 's':
    print("saving file");
    String[] obj = new String[640*480];
    for(int i=0; i<640*480; i++){
      PVector sample = context.depthMapRealWorld()[i];
      String vertex = "v " + Float.toString(sample.x) + " " + 
        Float.toString(sample.y) + " " + Float.toString(sample.z);
        obj[i] = vertex;
    }
    saveStrings("/tmp/frame.obj", obj);
    break;
  }
}  

