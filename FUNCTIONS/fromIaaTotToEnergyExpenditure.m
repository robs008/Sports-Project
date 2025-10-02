function EE = fromIaaTotToEnergyExpenditure(IAA_tot,body_mass,EE_passed_in)
% Input arguments
% IAAtot: single element variable, containing the sum of the integrated,
%   absolute, acceleration values.
% body_mass: single element variable, containing the total mass (kg) of the subject carrying the smartphone.
% EE_passed_in: optional, single element variable.  
%   This should correspond to the EE value computed for the previous call to the function.  
%   When this third argument is not passed in to the function, a persistent variable EE_w is used.
%
% Output arguments
% EE: single element variable, containing the accumulated work done so far.

    % declaring persistent variables (their value is preserved between function calls)
    persistent T_k alpha beta EE_w
    
    if isempty(T_k) % if this is the first time this function is invoked
        alpha = 0.104; % intercept Bouten regression equation
        beta = 0.023; % slope Bouten regression equation
        T_k = 30; % duration over which acceleration data (IAAtot) has been integrated
        EE_w = 0; % relative work
    end
    
    EEact=alpha+beta*IAA_tot;
    % from W/kg to J/kg
    EEact=EEact*T_k;

    if nargin == 2
        % use the persistent variable to retrieve previous, relative work value
        EE_w=EEact+EE_w;
    else
        % use the third input argument to retrieve previous, relative work value
        EE_w=EEact+EE_passed_in;
    end
    % j/kg-->kcal
    EE=EE_w*body_mass/4184;

end
