function y = f4( x )
%optimal difficult Summary of this function goes here
%   Detailed explanation goes here
a = [3.040,1.098,0.674,3.537,6.173,8.679,4.503,3.328,6.937,0.700];
k = [2.983,2.378,2.439,1.168,2.406,1.236,2.868,1.378,2.348,2.268];
c = [0.192,0.140,0.127,0.132,0.125,0.189,0.187,0.171,0.188,0.176];

for i=1:10
    y=y+(1/(k(i).*(x-a(i)).^2+c(i)));
end
end

