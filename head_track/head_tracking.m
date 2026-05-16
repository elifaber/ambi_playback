%%
a = arduino('/dev/tty.usbserial-A10LSMK4', 'Nano3', 'Libraries', 'I2C');
%%
fs = 100; % Sample Rate in Hz   
imu = mpu9250(a,'SampleRate',fs,'OutputFormat','matrix'); 

%%

ts = tic; 
stopTimer = 50; 
magReadings=[]; 
while(toc(ts) < stopTimer) 
    % Rotate the sensor along x axis from 0 to 360 degree. 
    % Take 2-3 rotations to improve accuracy. 
    % For other axes, rotate along that axes. 
   [accel,gyro,mag] = read(imu); 
   magReadings = [magReadings;mag]; 
end 

[A, b] = magcal(magReadings); % A = 3x3 matrix for soft iron correction 
                              % b = 3x1 vector for hard iron correctio

%%

% GyroscopeNoise and AccelerometerNoise is determined from datasheet.
GyroscopeNoiseMPU9250 = 3.0462e-06; % GyroscopeNoise (variance value) in units of rad/s
AccelerometerNoiseMPU9250 = 0.0061; % AccelerometerNoise(variance value)in units of m/s^2
viewer = HelperOrientationViewer('Title',{'AHRS Filter'});
FUSE = ahrsfilter('SampleRate',imu.SampleRate, 'GyroscopeNoise',GyroscopeNoiseMPU9250,'AccelerometerNoise',AccelerometerNoiseMPU9250);
stopTimer = 100;

%%

% The correction factors A and b are obtained using magcal function as explained in one of the
% previous sections, 'Compensating Magnetometer Distortions'.
magx_correction = b(1);
magy_correction = b(2);
magz_correction = b(3);
ts = tic;
while(toc(ts) < stopTimer)
    [accel,gyro,mag] = read(imu);
    % Align coordinates in accordance with NED convention
    accel = [-accel(:,2), -accel(:,1), accel(:,3)];
    gyro = [gyro(:,2), gyro(:,1), -gyro(:,3)];
    mag = [mag(:,1)-magx_correction, mag(:, 2)- magy_correction, mag(:,3)-magz_correction] * A;
    rotators = FUSE(accel,gyro,mag);
    for j = numel(rotators)
        viewer(rotators(j));
    end
end

%%


% GyroscopeNoise and AccelerometerNoise is determined from datasheet.
GyroscopeNoiseMPU9250 = 3.0462e-06; % GyroscopeNoise (variance) in units of rad/s
AccelerometerNoiseMPU9250 = 0.0061; % AccelerometerNoise (variance) in units of m/s^2
viewer = HelperOrientationViewer('Title',{'IMU Filter'});
FUSE = imufilter('SampleRate',imu.SampleRate, 'GyroscopeNoise',GyroscopeNoiseMPU9250,'AccelerometerNoise', AccelerometerNoiseMPU9250);
stopTimer=100;


% Use imufilter to estimate orientation and update the viewer as the sensor moves for time specified by stopTimer 
tic; 
while(toc < stopTimer)
    [accel,gyro] = read(imu);
    accel = [-accel(:,2), -accel(:,1), accel(:,3)]; 
    gyro = [gyro(:,2), gyro(:,1), -gyro(:,3)]; 
    rotators = FUSE(accel,gyro); 
    for j = numel(rotators) 
        viewer(rotators(j)); 
    end 
end 

%%


viewer = HelperOrientationViewer('Title',{'Ecompass Algorithm'});
% Use ecompass algorithm to estimate orientation and update the viewer as the sensor moves for time specified by stopTimer.
% The correction factors A and b are obtained using magcal function as explained in one of the
% previous sections, 'Compensating Magnetometer Distortions'.
magx_correction = b(1);
magy_correction = b(2);
magz_correction = b(3);
stopTimer = 100;
tic;
while(toc < stopTimer)
    [accel,~,mag] = read(imu);
    accel = [-accel(:,2), -accel(:,1), accel(:,3)];
    mag = [mag(:,1)-magx_correction, mag(:, 2)- magy_correction, mag(:,3)-magz_correction] * A;
    rotators = ecompass(accel,mag);
    for j = numel(rotators)
        viewer(rotators(j));
    end
end

%%

release(imu);
clear;