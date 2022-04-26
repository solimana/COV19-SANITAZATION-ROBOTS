clear
clc


rosshutdown
rosinit('192.168.1.7')
goalsa = rossubscriber("/Bgoals","DataFormat","struct");  
robotBstatuspub = rospublisher("/Bstatus","std_msgs/Int32","DataFormat","struct");
robotBgoalspub = rospublisher("/Bgoals","std_msgs/Int32MultiArray","DataFormat","struct");
robotBgoalspubms = rosmessage(robotBgoalspub);


while(1)


    
 try
    [msg2] = receive(goalsa, 3);
    goalsa_d = double(msg2.Data)
catch
    goalsa_d = 0;
end




% parfeval(@robotA_move,1,)
robotbgoalms = rosmessage(robotBstatuspub);

x = goalsa_d(1)

if goalsa_d(1) ~= 0

for i=1:length(goalsa_d)
    goal = goalsa_d(i)

    

robotposeB = rossubscriber("/pos_robB","DataFormat","struct");  
[msg2] = receive(robotposeB,10);
robposB = double(msg2.Data); 

robotposeB_or = rossubscriber("/qualisys/robotB/pose","DataFormat","struct");       
[msg2] = receive(robotposeB_or,10);
robotposeB_orv = double([msg2.Pose.Orientation.X msg2.Pose.Orientation.Y msg2.Pose.Orientation.Z msg2.Pose.Orientation.W]);
robotposeB_orv = rad2deg(quat2eul(robotposeB_orv,'XYZ'));
   
initialOrientation = deg2rad(robotposeB_orv(2)+90);
C_Robot_Pos = [robposB(3) robposB(1)];
C_Robot_Angr = initialOrientation;
% initialOrientation = deg2rad(90);


goals = ["/pos_st1";"/pos_st2";"/pos_st3";"/pos_st4";"/pos_st5"];
pause_times = [1;2;3;4;4];

goalpose = rossubscriber(goals(goal),"DataFormat","struct");
   [msg2] = receive(goalpose,10);
   goalposed = double(msg2.Data); 
  
pause(1);




% drawbotn([C_Robot_Pos C_Robot_Angr], .1, 1);
% hold on

D_Robot_Pos = [goalposed(3) goalposed(1)];
D_Robot_Angr = 0;
% drawbotn([D_Robot_Pos D_Robot_Angr], .1, 1);

% P controller gains
k_rho = 1.5;                           %should be larger than 0, i.e, k_rho > 0
k_alpha = 50;                          %k_alpha - k_rho > 0
k_beta = -0.0280;                        %should be smaller than 0, i.e, k_beta < 0


d = 0.122;                                 %robot's distance
dt = .1;                                %timestep between driving and collecting sensor data

robotBpub = rospublisher("/motorsB","std_msgs/Int32MultiArray","DataFormat","struct");
robotBmsg = rosmessage(robotBpub);

goalRadius = 0.4;
distanceToGoal = norm(C_Robot_Pos - D_Robot_Pos);

%%
while( distanceToGoal > goalRadius )
    distanceToGoal;
robotbgoalms.Data = int32(goal);
send(robotBstatuspub,robotbgoalms);
    delta_x = D_Robot_Pos(1) - C_Robot_Pos(1);
    delta_y = D_Robot_Pos(2) - C_Robot_Pos(2);
    rho = sqrt(delta_x^2+delta_y^2);    %distance between the center of the robot's wheel axle and the goal position.
    alpha = -C_Robot_Angr+atan2(delta_y,delta_x); %angle between the robot's current direction and the vector connecting the center of the axle of the sheels with the final position.
    
    %limit alpha range from -180 degree to +180
    if rad2deg(alpha) > 180
        temp_alpha = rad2deg(alpha) - 360;
        alpha = deg2rad(temp_alpha);
    elseif rad2deg(alpha) < -180
        temp_alpha = rad2deg(alpha) + 360;
        alpha = deg2rad(temp_alpha);
    end
    
    beta = -C_Robot_Angr-alpha;
    
    % P controller

%     rad2deg(alpha)
    v = k_rho*rho;

    w = k_alpha*alpha + k_beta*beta;
    vL = v + d/2*w;
    vR = v - d/2*w;
%     if rad2deg(alpha) > 120
%         vL = 2
%         vR = 0 
%     end
    
    vl_command = (floor(vL* 1200));
    vr_command = (floor(vR*1200));
    robotBmsg.Data = int32([vl_command,vr_command]);
    
    send(robotBpub,robotBmsg);
    
    
    
        
   [msg2] = receive(robotposeB,10);
   robposB = double(msg2.Data);
      
    [msg2] = receive(robotposeB_or,10);
   robotposeB_orv = double([msg2.Pose.Orientation.X msg2.Pose.Orientation.Y msg2.Pose.Orientation.Z msg2.Pose.Orientation.W]);
   robotposeB_orv = rad2deg(quat2eul(robotposeB_orv,'XYZ'));
   corientation = deg2rad(robotposeB_orv(2)+90);
   
   posr = [robposB(3);robposB(1);corientation];
    
%     posr = [C_Robot_Pos C_Robot_Angr];
%     posr = drive(posr, d, vL, vR, dt, posr(3)); %determine new position
%     drawbotn(posr, .1, 1);
    C_Robot_Pos = [posr(1) posr(2)];
    C_Robot_Angr = corientation;
%     pause(0.05); % if you notice any lagging, try to increase pause time a bit, e.g., 0.05 -> 0.1
    
    distanceToGoal = norm(C_Robot_Pos(:) - D_Robot_Pos(:));

%     pause(0.1)
end
close all

    robotBmsg.Data = int32([0,0]);
    
    send(robotBpub,robotBmsg);
    pause(pause_times(goal));


end
done =1 ;


%   for i = 1:100
  robotbgoalms.Data = int32(0)
    send(robotBstatuspub,robotbgoalms);
    
    robotBgoalspubms.Data = int32([0,0]);
    send(robotBgoalspub,robotBgoalspubms);
    pause(0.01);
%     end

else 
      robotbgoalms.Data = int32(0)
    send(robotBstatuspub,robotbgoalms);
        inhere = 1

        robotBgoalspubms.Data = int32([0,0]);
    send(robotBgoalspub,robotBgoalspubms);
%     pause(1);
end
end
