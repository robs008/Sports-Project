function IAAtot = fromBufferedAccToIaaTot(axyz,filter_acceleration,sf)
% Input arguments
% axyz: 2D matrix with N (time samples) rows and three columns (ax,ay,az).
% filter_acceleration: boolean indicating whether buffered acceleration is to be filtered or not.  
%       This variable was sought to allow students to appreciate the effect of gravity on the energy expenditure estimates.
% sf: sampling frequency used to collect acceleration data.
%
% Output arguments
% IAAtot: single element variable, containing the sum of the integrated, absolute, acceleration values.

    % declaring persistent variables (their value is preserved between function calls)
    persistent b a; % filter coefficients
    
    if isempty(b) % if this is the first time this function is called
        [b,a]=butter(8,[0.1,20]/(sf/2),'bandpass'); 
    end
    
    if filter_acceleration
     axyz = filtfilt(b,a,axyz); % apply a filter without distorting the signal
    end
    
    % Calculate the IAAtot
    IAA=trapz(abs(axyz))/sf;
    IAAtot=sum(IAA);

end