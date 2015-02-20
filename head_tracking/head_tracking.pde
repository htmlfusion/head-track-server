import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.net.InetSocketAddress;
import java.net.UnknownHostException;
import java.util.Collection;

import org.java_websocket.WebSocket;
import org.java_websocket.WebSocketImpl;
import org.java_websocket.handshake.ClientHandshake;
import org.java_websocket.server.WebSocketServer;

import org.json.simple.JSONObject;

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
ChatServer s;

//create a separate thread for the server not to freeze/interfere with Processing's default animation thread
public class ServerThread extends Thread{
  @Override
  public void run(){
    try{
          WebSocketImpl.DEBUG = true;
          int port = 8887; // 843 flash policy port
          try {
            port = Integer.parseInt( args[ 0 ] );
          } catch ( Exception ex ) {
          }
          s = new ChatServer( port );
          s.start();
          System.out.println( "ChatServer started on port: " + s.getPort() );

          BufferedReader sysin = new BufferedReader( new InputStreamReader( System.in ) );
          while ( true ) {
            String in = sysin.readLine();
            s.sendToAll( in );
          }
        }catch(IOException e){
          e.printStackTrace();
        }  
  }
}
public class ChatServer extends WebSocketServer {

  public ChatServer( int port ) throws UnknownHostException {
    super( new InetSocketAddress( port ) );
  }

  public ChatServer( InetSocketAddress address ) {
    super( address );
  }

  @Override
  public void onOpen( WebSocket conn, ClientHandshake handshake ) {
    this.sendToAll( "new connection: " + handshake.getResourceDescriptor() );
    System.out.println( conn.getRemoteSocketAddress().getAddress().getHostAddress() + " entered the room!" );
  }

  @Override
  public void onClose( WebSocket conn, int code, String reason, boolean remote ) {
    this.sendToAll( conn + " has left the room!" );
    System.out.println( conn + " has left the room!" );
  }

  @Override
  public void onMessage( WebSocket conn, String message ) {
    this.sendToAll( message );
    System.out.println( conn + ": " + message );
  }

  @Override
  public void onError( WebSocket conn, Exception ex ) {
    ex.printStackTrace();
    if( conn != null ) {
      // some errors like port binding failed may not be assignable to a specific websocket
    }
  }

  /**
   * Sends <var>text</var> to all currently connected WebSocket clients.
   * 
   * @param text
   *            The String to send across the network.
   * @throws InterruptedException
   *             When socket related I/O errors occur.
   */
  public void sendToAll( String text ) {
    Collection<WebSocket> con = connections();
    synchronized ( con ) {
      for( WebSocket c : con ) {
        c.send( text );
      }
    }
  }
}

void setup()
{
  size(640,480);
  
  context = new SimpleOpenNI(this);
  if(context.isInit() == false)
  {
     println("Can't init SimpleOpenNI, maybe the camera is not connected!"); 
     exit();
     return;  
  }
  
  // enable depthMap generation 
  context.enableDepth();
   
  // enable skeleton generation for all joints
  context.enableUser();
  
 
  background(200,0,0);

  stroke(0,0,255);
  strokeWeight(3);
  smooth();  
  new ServerThread().start();

}

void draw()
{
  // update the cam
  context.update();
  
  // draw depthImageMap
  //image(context.depthImage(),0,0);
  image(context.userImage(),0,0);
  
  // draw the skeleton if it's available
  int[] userList = context.getUsers();
  for(int i=0;i<userList.length;i++)
  {
    if(context.isTrackingSkeleton(userList[i]))
    {
      stroke(userClr[ (userList[i] - 1) % userClr.length ] );
      drawSkeleton(userList[i]);
    }      
      
    // draw the center of mass
    if(context.getCoM(userList[i],com))
    {
      context.convertRealWorldToProjective(com,com2d);
      stroke(100,255,0);
      strokeWeight(1);
      beginShape(LINES);
        vertex(com2d.x,com2d.y - 5);
        vertex(com2d.x,com2d.y + 5);

        vertex(com2d.x - 5,com2d.y);
        vertex(com2d.x + 5,com2d.y);
      endShape();
      
      fill(0,255,100);
      text(Integer.toString(userList[i]),com2d.x,com2d.y);
    }
  }    
}

// draw the skeleton with the selected joints
void drawSkeleton(int userId)
{
  PVector jointHeadPos = new PVector();
  context.getJointPositionSkeleton(userId, SimpleOpenNI.SKEL_HEAD, jointHeadPos);
  
//  JSONArray values = new JSONArray();
//  values.setFloat(0, jointPos.x);
//  values.setFloat(1, jointPos.y);
//  values.setFloat(2, jointPos.z);

  JSONObject head = new JSONObject();
  head.put("x", jointHeadPos.x);
  head.put("y", jointHeadPos.y);
  head.put("z", jointHeadPos.z);
 
  PVector jointLeftHandPos = new PVector();
  context.getJointPositionSkeleton(userId, SimpleOpenNI.SKEL_LEFT_HAND, jointLeftHandPos);
  
  JSONObject leftHand = new JSONObject();
  leftHand.put("x", jointLeftHandPos.x);
  leftHand.put("y", jointLeftHandPos.y);
  leftHand.put("z", jointLeftHandPos.z);

  PVector jointRightHandPos = new PVector();
  context.getJointPositionSkeleton(userId, SimpleOpenNI.SKEL_LEFT_HAND, jointRightHandPos);
     
  JSONObject rightHand = new JSONObject();
  rightHand.put("x", jointRightHandPos.x); 
  rightHand.put("y", jointRightHandPos.y); 
  rightHand.put("z", jointRightHandPos.z); 
                    
  JSONObject bodyPos = new JSONObject();   
  bodyPos.put("head", head);
  bodyPos.put("left_hand", leftHand);
  bodyPos.put("right_hand", rightHand);

  println(bodyPos);
  //String bodyPosText = JSONValue.toJSONString(bodyPos);
  s.sendToAll(bodyPos.toString());
  
  //s.sendToAll(Float.toString(jointPos.x) + ", " + Float.toString(jointPos.y) +", " + Float.toString(jointPos.z));
  
  context.drawLimb(userId, SimpleOpenNI.SKEL_HEAD, SimpleOpenNI.SKEL_NECK);
  

  context.drawLimb(userId, SimpleOpenNI.SKEL_NECK, SimpleOpenNI.SKEL_LEFT_SHOULDER);
  context.drawLimb(userId, SimpleOpenNI.SKEL_LEFT_SHOULDER, SimpleOpenNI.SKEL_LEFT_ELBOW);
  context.drawLimb(userId, SimpleOpenNI.SKEL_LEFT_ELBOW, SimpleOpenNI.SKEL_LEFT_HAND);

  context.drawLimb(userId, SimpleOpenNI.SKEL_NECK, SimpleOpenNI.SKEL_RIGHT_SHOULDER);
  context.drawLimb(userId, SimpleOpenNI.SKEL_RIGHT_SHOULDER, SimpleOpenNI.SKEL_RIGHT_ELBOW);
  context.drawLimb(userId, SimpleOpenNI.SKEL_RIGHT_ELBOW, SimpleOpenNI.SKEL_RIGHT_HAND);

  context.drawLimb(userId, SimpleOpenNI.SKEL_LEFT_SHOULDER, SimpleOpenNI.SKEL_TORSO);
  context.drawLimb(userId, SimpleOpenNI.SKEL_RIGHT_SHOULDER, SimpleOpenNI.SKEL_TORSO);

  context.drawLimb(userId, SimpleOpenNI.SKEL_TORSO, SimpleOpenNI.SKEL_LEFT_HIP);
  context.drawLimb(userId, SimpleOpenNI.SKEL_LEFT_HIP, SimpleOpenNI.SKEL_LEFT_KNEE);
  context.drawLimb(userId, SimpleOpenNI.SKEL_LEFT_KNEE, SimpleOpenNI.SKEL_LEFT_FOOT);

  context.drawLimb(userId, SimpleOpenNI.SKEL_TORSO, SimpleOpenNI.SKEL_RIGHT_HIP);
  context.drawLimb(userId, SimpleOpenNI.SKEL_RIGHT_HIP, SimpleOpenNI.SKEL_RIGHT_KNEE);
  context.drawLimb(userId, SimpleOpenNI.SKEL_RIGHT_KNEE, SimpleOpenNI.SKEL_RIGHT_FOOT);  
}

// -----------------------------------------------------------------
// SimpleOpenNI events

void onNewUser(SimpleOpenNI curContext, int userId)
{
  println("onNewUser - userId: " + userId);
  println("\tstart tracking skeleton");
  
  curContext.startTrackingSkeleton(userId);
}

void onLostUser(SimpleOpenNI curContext, int userId)
{
  println("onLostUser - userId: " + userId);
}

void onVisibleUser(SimpleOpenNI curContext, int userId)
{
  //println("onVisibleUser - userId: " + userId);
}


void keyPressed()
{
  switch(key)
  {
  case ' ':
    context.setMirror(!context.mirror());
    break;
  }
}  

