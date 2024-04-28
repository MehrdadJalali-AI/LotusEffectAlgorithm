function [yes_valley ] = hill_valley( iq , ip , samples )
%HILL_VALLEY Summary of this function goes here
%   Detailed explanation goes here
  i_interior[0,0];
min_fit=min(fitness(ip),fitness(iq));
for j=1:samples
    i_interior(1)=(ip(1)+(iq(1)-ip(1))*samples);
    i_interior(2)=(ip(2)+(iq(2)-ip(2))*samples);
    if (min_fit>fitness(i_interior))
        return yes_valley=1;
    end 
    end 
        return yes_valley=0;
end

