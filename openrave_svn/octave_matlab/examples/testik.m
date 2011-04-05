% testrosik(robotfile,manipid,ikfastlib)
%
% tests the inverse kinematics solver of a robot
% Arguments:
%  robotfile - openrave robot
%  manipid [optional] - if specified, only tests ik for those manipulators (zero-indexed)
%  rotonly [optional] - if specified and true, only test rotation component of ik solution
%  ikfastlib [optional] - the ikfast shared object to dynamically load as an openrave iksolver
function testik(robotfile,manipid)

more off; % turn off output paging
addopenravepaths()

if( ~exist('robotfile','var') )
    robotfile = 'robots/barrettwam.robot.xml';
end

orEnvLoadScene('',1);
robotid = orEnvCreateRobot('robot',robotfile);
probid = orEnvCreateProblem('ikfast');
manips = orRobotGetManipulators(robotid);

%% SetActiveManip command not supported
%orProblemSendCommand(sprintf('SetActiveManip %d',i-1),probid);

% if( ~exist('manipid','var') )
%     for i = 1:length(manips)
%         orProblemSendCommand(sprintf('SetActiveManip %d',i-1),probid);
%         tic;
%         orProblemSendCommand(cmd,probid);
%         toc
%     end
% else
%     orProblemSendCommand(sprintf('SetActiveManip %d',manipid),probid);
%     tic;
%     orProblemSendCommand(cmd,probid);
%     toc
% end


%% test any specific ik configuration
orBodySetJointValues(robotid,[ 0.919065 -1.4331 1.45619 1.31858 0.696941 1.52955 -0.314613],manips{1}.armjoints);
links = orBodyGetLinks(robotid);
Thand = reshape(links(:,manips{1}.eelink+1),[3 4]);
Tee = [Thand; 0 0 0 1]*[manips{1}.Tgrasp; 0 0 0 1]
%Thand_frombase = inv([reshape(links(:,manips{1}.baselink+1),[3 4]);0 0 0 1]) * [Thand; 0 0 0 1];
s = orProblemSendCommand(['IKTest robot robot matrix ' sprintf('%f ',Tee(1:3,1:4))],probid);
s
if( isempty(s) )
    return;
end
orBodySetJointValues(robotid,sscanf(s,'%f'),manips{1}.armjoints);

%% can also do this through the ik param type:
quat = QuatFromRotationMatrix(Tee(1:3,1:3))
s = orProblemSendCommand(['IKTest robot robot ikparam  ' sprintf('%d ',0x67000001) sprintf('%f ',[quat(:);Tee(1:3,4)])],probid);

%% if ik solver supports translation 3d, can also call its ik using 0x33000003
%s = orProblemSendCommand(['IKTest robot robot ikparam  ' sprintf('%d ',0x33000003) ' 0.1 0.2 0.3'])

disp('now testing ik')
cmd = 'debugik numtests 100 robot robot ';
out=orProblemSendCommand(cmd,probid);
res=sscanf(out,'%f');
disp(['success rate ' sprintf('%f',res(2)/res(1))])