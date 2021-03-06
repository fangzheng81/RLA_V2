%% Measurement mode module
% -- this is the measurement mode module used to conduct the continuing
% measurement when Lidar starts to measure the location
function [mea_status,Lidar_update_xy] = measurement_mode(num_ref_pool_orig,num_detect_pool,Reflector_map,Reflector_ID,measurement_data,scan_data,amp_thres,angle_delta,dist_delta,Lidar_trace,thres_dist_match,thres_dist_large)
%% 1. Read the scan data, identify reflectors and define how many scanned reflectors are used from the list(nearest distance or most distingushed).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% identify the reflectors
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[detected_ID,detected_reflector]=identify_reflector(amp_thres,angle_delta,dist_delta,measurement_data,scan_data);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
amp_thres;
angle_delta;
dist_delta;
measurement_data;
scan_data;
detected_ID;
num_ref_pool=num_ref_pool_orig;
Lidar_x=0;
Lidar_y=0;
%Lidar_init_xy(1,1)=Lidar_trace(1,1);
%Lidar_init_xy(1,2)=Lidar_trace(1,2);
Lidar_init_xy=Lidar_trace(end,:);
%% 2. Match the N x scanned reflectors with match reflector table and find the location of lidar.
% -- create match detect pool 
[match_reflect_pool,match_reflect_pool_ID] = create_match_ref_pool(num_ref_pool,Reflector_map,Lidar_init_xy);
Lidar_current_xy=Lidar_trace(end,:)
[match_detected_pool,match_detected_pool_ID] = create_match_detect_pool(num_detect_pool,detected_reflector,detected_ID,Lidar_current_xy);

%% 2.a Calculate distance between any two reflectors
%[match_reflect_vector_pool1,match_reflect_vec_ID1] = calc_distance(match_reflect_pool,match_reflect_pool_ID);
%[match_detected_vector_pool1,match_detected_vec_ID1] = calc_distance(match_detected_pool,match_detected_pool_ID);
%% 2.b match detected reflectors with match reflector pool and return matched point ID.
% -- match the distance vector and return point array and point ID
% -- update match pool if 
num_ref_pool=num_ref_pool_orig;
a=1;
[match_reflect_vector_pool] = calc_distance(match_reflect_pool,match_reflect_pool_ID);
[match_detected_vector_pool] = calc_distance(match_detected_pool,match_detected_pool_ID);
[Reflect_vec_ID] = index_reflector(match_reflect_vector_pool);
[detected_vec_ID] = index_reflector(match_detected_vector_pool);
(match_reflect_vector_pool);
(match_detected_vector_pool);
while a==1
    [matched_reflect_ID,matched_reflect_vec_ID,matched_detect_ID,matched_detect_vec_ID,match_result] = match_reflector(match_reflect_vector_pool,Reflect_vec_ID,match_detected_vector_pool,detected_vec_ID,thres_dist_large,thres_dist_match);
    if match_result==1
    disp('No matched distance found, update reference map with new reflectors')
    num_ref_pool=num_ref_pool+1;
    [match_reflect_pool,match_reflect_pool_ID] = create_match_ref_pool(num_ref_pool,Reflector_map,Lidar_current_xy);
    [match_reflect_vector_pool] = calc_distance(match_reflect_pool,match_reflect_pool_ID);
    [Reflect_vec_ID] = index_reflector(match_reflect_vector_pool);
    elseif match_result==0 
    disp('Matched reflector found!!')
    break
end
end
%% plot map new Lidar scan
figure(102)
hold on;plot(measurement_data(:,1),measurement_data(:,2),'+g');
color='g';
%% plot map with random displacement
%plot_reflector(detected_reflector1,detected_ID1,color)
%% 2.c calculate rotation and transition
[ret_R,ret_T,Lidar_update_xy]=locate_reflector_xy(match_reflect_pool,matched_reflect_ID,detected_reflector,matched_detect_ID,Lidar_x,Lidar_y);
ret_R;
ret_T;
% Calculate reflector rmse errors
[reflector_rmse]=reflector_rmse_error(ret_R,ret_T,match_reflect_pool,matched_reflect_ID,detected_reflector,matched_detect_ID);
%% 2.d calculate updated map in the world map 

[Lidar_update_Table,Lidar_update_xy]=update_Lidar_scan_xy(ret_R,ret_T,measurement_data,scan_data,Lidar_x,Lidar_y);
% calculate map rmse errors
[map_rmse]=map_rmse_error(ret_R,ret_T,measurement_data,scan_data);
%% Plot reference map in the world coordinate
figure(103)
plot(Lidar_update_Table(:,1),Lidar_update_Table(:,2),'o','Color',[rand(),rand(),rand()]);
hold on;
plot(match_reflect_pool(matched_reflect_ID,1),match_reflect_pool(matched_reflect_ID,2),'+k')
color='b';
%% Plot the reflectors in the world map
%plot_reflector(detected_reflector,detected_ID,color) % plot reference reflector 
hold on;
%% Plot update map in the world map
%plot(Lidar_update_Table(1,:),Lidar_update_Table(2,:),'+g');
% identify the reflector in the updated map
%amp_thres=80;  % loss should be proportional to distance -- constant/distance ?
%angle_delta=0.4;   % angle delta value to identify different reflectors  
%distance_delta=10;   % distance to tell the different reflectors
[detected_ID2,detected_reflector2]=identify_reflector(amp_thres,angle_delta,dist_delta,Lidar_update_Table,scan_data);
hold on;
color='g';
plot_reflector(detected_reflector2,detected_ID2,color)
hold on;
%plot(Lidar_update_xy(1,1),Lidar_update_xy(1,2),'o-k')
%% Save new Lidar location to the trace and plot
%Lidar_trace=[Lidar_trace; Lidar_update_xy];
%plot(Lidar_trace(:,1),Lidar_trace(:,2),'o-k')
disp(sprintf("RMSE: %f for %i th step", reflector_rmse));
disp("RMSE errors for each reflector matching calculation ");
pause(1)

if reflector_rmse<1
    mea_status=0;
elseif reflector_rmse>1 && reflector_rmse<10
    mea_status=1;
elseif reflector_rmse>10 && reflector_rmse<100
    mea_status=2;
elseif reflector_rmse>100 
    mea_status=3;    
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Last Step!!!
%% Update match reflector pool to get the latest nearest points from reflector map
[match_reflect_pool,match_reflect_pool_ID] = create_match_ref_pool(num_ref_pool,Reflector_map,Lidar_current_xy);

end  % Simulation loop end up here!!!