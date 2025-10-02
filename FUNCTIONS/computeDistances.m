function dist = computeDistances(latitude,longitude)
% Input argument:
    % latitude: 1D vector containing at least two LATITUDE values, in degrees.
    % longitude: 1D vector containing at least two LONGITUDE values, in degrees.
% Output arguments:
% dist: store the distance values, in kilometers, computed using  Euclidean
%       distance method
    
    
    a = 6378.137; % semi-major axis 
    e = 0.08181919; % eccentricity
    
    % Compute distances using Spherical Law of Cosines (slc)
    for i = 1:numel(latitude)-1
        lat1 = deg2rad(latitude(i));
        lon1 = deg2rad(longitude(i));
        lat2 = deg2rad(latitude(i+1));
        lon2 = deg2rad(longitude(i+1));
    
        % first set of coordinates
        R1 = a/sqrt(1 - e^2 * sin(lat1)^2) ; % distance from Earth surface to the Earth rotation axis, along a line normal to the Earth surface   
        x1 = R1* cos(lat1) * cos(lon1);
        y1 =R1 * cos(lat1) * sin(lon1);
        z1 =(R1*(1-e^2)) * sin(lat1);
        
        % second set of coordinates
        R2= a/sqrt(1 - e^2 * sin(lat2)^2);
        x2 = R2 * cos(lat2) * cos(lon2);
        y2 = R2 * cos(lat2) * sin(lon2);
        z2 =(R2*(1-e^2)) * sin(lat2);
    
    
        % Compute distance using Spherical Law of Cosines
        dist(i) = sqrt((x2 - x1)^2 + (y2 - y1)^2 + (z2 - z1)^2);
    end
end