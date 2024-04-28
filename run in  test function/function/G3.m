function f = G3( x )

aa=x(:,1).^2+x(:,2).^2;
bb=((x(:,1)+0.5).^2+x(:,2).^2).^0.1;
f=aa.^0.25.*sin(30*bb)+abs(x(:,1))+abs(x(:,2));


end

