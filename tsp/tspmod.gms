$ontext
TSP with Pataki modifications
$offtext
set state /
$include set.csv
/
;
alias(state,i,j);
set Header /l_lat,l_long,select/;
$onexternalInput
table StateInfo(state,Header)
$onDelim
$include capitals.csv
$offDelim
;
$offexternalInput
set select(state) Selected capitals;
select(state)$(StateInfo(State,'select') eq 1)=yes;
scalar count /0/;
parameter OrderVal(i);
loop(select,count=count+1;OrderVal(select)=count;);

alias(select,k)
table  dist(i,j)  "distances" ;
dist(i,j)=arccos(sin(StateInfo(i,'l_lat')*pi/180)*sin(StateInfo(j,'l_long')*pi/180)
+cos(StateInfo(i,'l_lat')*pi/180)*cos(StateInfo(j,'l_long')*pi/180)*
cos((StateInfo(i,'l_long')-StateInfo(j,'l_lat'))*pi/180))*6371.004;
binary variables x(i,j);
free variable obj;
positive variables u(i) ;
equations defobj, assign1(j), assign2(i), mtz(i,j);
defobj..
obj =e= sum((select,k), dist(select,k) * x(select,k));

assign1(select)..
sum(k$(not sameas(select,k)), x(select,k)) =e= 1;

assign2(select)..
sum(k$(not sameas(select,k)), x(k,select)) =e= 1;

mtz(select,k)$(OrderVal(select) ne 1 and OrderVal(k) ne 1)..
  u(select) - u(k) + 1 =L= (card(select) - 1) * (1 - x(select,k)) ;

model tsp /defobj, assign1, assign2, mtz/;

x.fx(select,select) = 0;
u.lo(select) = 2; u.up(select) = card(i);
u.fx(select)$(OrderVal(select) eq 1) = 1;

option optcr = 1e-3;
$onecho > cplex.opt
lpmethod 4
$offecho
tsp.optfile = 1;
solve tsp using mip minimizing obj ;
display obj.l;
set tour(i,j) ;

tour(select,select) = no;
tour(select,k)$(x.l(select,k) > 0.01) = yes ;
set TourHeader /status 'whether selected',dist 'distance',lat1 'latitude1',long1 'longitude1',lat2 'latitude2',long2 'longitude2'/;
$OnexternalOutput
table TourT(i,j,TourHeader);
TourT(select,k,'status')$tour(select,k)=1;
TourT(i,j,'status')$(not tour(i,j))=-1;
TourT(i,j,'dist')=dist(i,j);
TourT(i,j,'lat1')=StateInfo(i,'l_lat');
TourT(i,j,'long1')=StateInfo(i,'l_long');
TourT(i,j,'lat2')=StateInfo(j,'l_lat');
TourT(i,j,'long2')=StateInfo(j,'l_long');
scalar TotalCost Total Cost;
TotalCost=obj.l;
$offExternalOutput
* Just print the tour in a simple way
option tour:0:0:1 ;

display tour;
display u.L;
