%% Active Portfolio Management Project -- Danny Guo
% Importing Data
HistPrices = readtable("Historical Prices (1).xlsx") ;
AnalystRets = readtable("Historical Prices (1).xlsx",Sheet = "Forecast") ;
AnalystRets = AnalystRets(:,[1,2]) ; 
HistPrices = flip(HistPrices) ; 
total = table2array(HistPrices(:,2:31)) ;
sample = table2array(HistPrices(1:40,2:31)) ; 
test = table2array(HistPrices(41:60,2:31)) ; 
% convert analyst returns to monthly for use later
a_rets = table2array(AnalystRets(3:31,"Var2"))/12 ; 

%% Converting Prices to Returns
samp_rets = zeros(39,30);
for i = 2:40
    for j = 1:30
    samp_rets(i-1,j) = sample(i,j)/sample(i-1,j)-1 ;
    end
end
clear i ; 
clear j ; 
% Sample expected returns calculated through sample mean of monthly returns
samp_mu = sum(samp_rets(1:39,:))/39 ;

%% Calculating covariance matrix and betas for the sample
samp_cov = cov(samp_rets) ; 
% Finding Betas, divide Cov(Stock i,DJI) by Var(DJI)
samp_beta = samp_cov(1:29,30)/samp_cov(30,30) ; 

%% DIFFERENT OPTIMAL PORTFOLIOS - Static Sample
% 1.) Long-only, minimum variance portfolio with beta = 1 
H_1 = samp_cov(1:29,1:29) ; 
Aeq_1 = [ones(1,29) ; samp_beta'] ; 
beq_1 = ones(2,1) ; 
lb_1 = zeros(29,1) ; 

x_1 = quadprog(H_1,[],[],[],Aeq_1,beq_1,lb_1) ; 


% 2.) Long-Short, min variance portfolio with beta = 1 
x_2  = quadprog(H_1,[],[],[],Aeq_1,beq_1) ; 


%% Max Sharpe Ratio portfolios with different constraints
% 3a.) Max Sharpe Ratio, with beta = 1, long only
H_3 = [H_1 zeros(29,1) ; zeros(1,30)] ; 
Aeq_3 = [samp_mu(:,1:29) 0 ; Aeq_1 [-1 ; -1]] ; 
b_3 = [1 ; 0 ; 0] ; 
lb_3 = zeros(30,1) ;

z_a = quadprog(H_3, [],[],[],Aeq_3,b_3,lb_3) ; 
x_3a = z_a(1:29,:)/z_a(30,1) ; 


% 3b.) Max Sharpe Ratio, with beta = 1, long short
z_b = quadprog(H_3, [],[],[],Aeq_3,b_3) ; 
x_3b = z_b(1:29,:)/z_b(30,1) ; 


% 3c.) Max Sharpe Ratio, 130/30 portfolio, with beta = 1
H_3c = [H_1 zeros(29,30) ; zeros(30,59)] ; 
Aeq_3c = [samp_mu(:,1:29) zeros(1,30) ; ones(1,29) zeros(1,29) -1 ; samp_beta' zeros(1,29) -1] ; 
beq_3c = [1 ; 0 ; 0] ;
D_3c = [-eye(29,29) -eye(29,29) zeros(29,1) ; zeros(1,29) ones(1,29) -.3] ; 
d_3c = [zeros(30,1)] ; 
lb_3c = [-inf(29,1) ; zeros(30,1)] ;

z_c = quadprog(H_3c,[],D_3c,d_3c,Aeq_3c,beq_3c,lb_3c) ; 
x_3c = z_c(1:29)/z_c(59) ; 

%checking that the sum of leverage is actually bounded to 30%
checky = sum(z_c(30:58)/z_c(59));

% consolidated the optimal portfolios into one matrix
% each column is a different portfolio
ports = [x_1 x_2 x_3a x_3b x_3c] ; 

%% Test portfolios on out of sample data, and plot
% normalize out of sample returns
os_rets = zeros(19,30) ; 
for e = 2:20
    for f = 1:30
        os_rets(e-1,f) = test(e,f)/test(e-1,f)-1 ; 
    end
end
clear e ; 
clear f ; 

%DJI returns on the out of sample data
DJI_value = zeros(20,1) ; 
for r = 1:19
    DJI_value(1) = 1000 ; 
    DJI_value(r+1) = (os_rets(r,30)+1)*DJI_value(r) ; 
end
% portfolio returns on the out of sample data through
port_values = zeros(20,1) ; 
for r = 1:19
    for q = 1:5
    port_values(1,1:5) = 1000 ; 
    port_values(r+1,q) = (dot(ports(:,q) , os_rets(r,1:29)') + 1) * port_values(r,q) ; 
    end
end
clear r ; 
clear q ; 

%% Building the line plots of portfolio value
% legend key: MV = min var, L = long only, LS = long short,
% MSR = Max Sharpe Ratio, 130 = 130/30 
% beta = 1 assumed
% example: "MSR-L" is the line plot of Max sharpe ratio, long only
%%plotted the following together because they are more closely related and
%%look good together on the graph
plotx = 1:1:20 ; 

graph1 = figure ;
plot(plotx,DJI_value)
hold on
plot(plotx,port_values(:,1))
plot(plotx,port_values(:,2))
plot(plotx,port_values(:,3))
plot(plotx,port_values(:,5))

title('Value of DJI vs Different Static Portfolios')
xlabel('months')
ylabel('portfolio value ($)')
legend('DJI','MV-L', 'MV-LS', 'MSR-L','MSR-130')
hold off

% Plotted Max Sharpe ratio Long short separately due to high volatility

graph2 = figure ; 
plot(plotx,DJI_value)
hold on
plot(plotx,port_values(:,4))

title('Value of DJI vs Static Max Sharpe Ratio Long Short')
xlabel('months')
ylabel('portfolio value ($)')
legend('DJI','MSR-LS')
hold off

%% After graphing, I noticed that using sample mu gives a much more correlated graph than using analyst returns, so for the previous programs I used sample mu
%% It seems that Max Sharpe Ratio 130/30 performed the best with the out of sample data

%% build the model for a rolling time window, actively rebalancing the portfolio. make sure to change the sample mus to analyst returns
% First we build the big returns matrix with the entire historical data
rets = zeros(59,30) ; 
for i = 2:60
    for j = 1:30
    rets(i-1,j) =  total(i,j)/total(i-1,j)-1 ; 
    end
end
clear i ; 
clear j ; 

% Rolling rebalanced portfolios, with numbering the same as above
% i.e. roll_1 is for min var long only
roll_3a = zeros(30,20) ; 
roll_3b = zeros(30,20) ; 
roll_3c = zeros(59,20) ;

for q = 1:20 
        roll_3a(:,q) = quadprog([cov(rets(q:q+39,1:29)) zeros(29,1) ; zeros(1,30)],[],[],[], [sum(rets(q:q+39,1:29))/40 0 ; ones(1,29) -1; samp_beta' -1],[1;0;0],zeros(30,1) );
        roll_3b(:,q) = quadprog([cov(rets(q:q+39,1:29)) zeros(29,1) ; zeros(1,30)],[],[],[], [sum(rets(q:q+39,1:29))/40 0 ; ones(1,29) -1; samp_beta' -1],[1;0;0] ); 
        roll_3c(:,q) = quadprog([cov(rets(q:q+39,1:29)) zeros(29,30) ; zeros(30,59)],[],[-eye(29,29) -eye(29,29) zeros(29,1) ; zeros(1,29) ones(1,29) -.3],[zeros(30,1)],...
            [sum(rets(q:q+39,1:29))/40 zeros(1,30) ; ones(1,29) zeros(1,29) -1 ; samp_beta' zeros(1,29) -1],[1;0;0],[-inf(29,1); zeros(30,1)] );
end
clear q ; 

%% Cleaning up the max sharpe ratio portfolios
% for the max sharpe ratio portfolios, divide kappa out of the z values
for i = 1:20
    roll_3a(1:29,i) = roll_3a(1:29,i)/roll_3a(30,i) ;
    roll_3b(1:29,i) = roll_3b(1:29,i)/roll_3b(30,i) ; 
    roll_3c(1:29,i) = roll_3c(1:29,i)/roll_3c(59,i) ;
end
% take out the extra variables
roll_3a = roll_3a(1:29,:) ; 
roll_3b = roll_3b(1:29,:) ; 
roll_3c = roll_3c(1:29,:) ; 

%% Plot the rolling window portfolio values (only doing the max sharpe ratio portfolios because they have been shown graphically to beat the DJI)

roll_3a_values = zeros(20,1); 
for i = 1:19
    roll_3a_values(1) = 1000 ; 
    roll_3a_values(i+1) = (dot(roll_3a(:,i),os_rets(i,1:29)'+1))*roll_3a_values(i,1) ; 
end
clear i ;
roll_3b_values = zeros(20,1); 
for i = 1:19
    roll_3b_values(1) = 1000 ; 
    roll_3b_values(i+1) = (dot(roll_3b(:,i),os_rets(i,1:29)'+1))*roll_3b_values(i,1) ; 
end
clear i ; 
roll_3c_values = zeros(20,1); 
for i = 1:19
    roll_3c_values(1) = 1000 ; 
    roll_3c_values(i+1) = (dot(roll_3c(:,i),os_rets(i,1:29)'+1))*roll_3c_values(i,1) ; 
end
clear i; 
% plotting rolling portfolios
% once again plotting MSR-Long short separately due to high volatility
graph3 = figure ; 
plot(plotx,DJI_value)
hold on
plot(plotx,roll_3a_values)
plot(plotx,roll_3c_values)

legend('DJI','MSR-L', 'MSR-130')
title('Value of DJI vs rolling MSR-long and MSR-130/30')
xlabel('months')
ylabel('portfolio value ($)')
hold off

graph4 = figure ;
plot(plotx,DJI_value)
hold on
plot(plotx,roll_3b_values)

legend('DJI','MSR-LS')
title('Value of DJI vs rolling Max Sharpe Ratio long short')
xlabel('months')
ylabel('portfolio value ($)')
hold off

%% Rolling variance plots

roll_DJI_var = zeros(20,1);
for i = 1:20
    roll_DJI_var(i) = var(rets(i:i+39,30)) ; 
end
clear i ; 
roll_3a_var = zeros(20,1); 
roll_3b_var = zeros(20,1) ;
roll_3c_var = zeros(20,1) ; 
for i = 1:20
    roll_3a_var(i) = roll_3a(:,i)'*cov(rets(i:i+39,1:29))*roll_3a(:,i) ; 
    roll_3b_var(i) = roll_3b(:,i)'*cov(rets(i:i+39,1:29))*roll_3b(:,i) ; 
    roll_3c_var(i) = roll_3c(:,i)'*cov(rets(i:i+39,1:29))*roll_3c(:,i) ; 
end
clear i ; 

% Plot the variances
graph5 = figure ; 
plot(plotx,roll_DJI_var)
hold on 
plot(plotx, roll_3a_var)
plot(plotx,roll_3c_var)

legend('DJI','MSR-L', 'MSR-130')
title('Rolling Variance of DJI vs MSR-L and MSR-130')
xlabel('months')
ylabel('variance')
hold off

graph6 = figure ; 
plot(plotx,roll_DJI_var)
hold on
plot(plotx,roll_3b_var)

legend('DJI','MSR-LS')
title('Rolling Variance of DJI vs MSR-LS')
xlabel('months')
ylabel('variance')
hold off

%% While the unconstrained Max Sharpe ratio long short portfolio achieves high levels of return relative to the DJI, it also has extreme variance
% This relationship is seen in the other portfolios as well.
%% For all the Max Sharpe Ratio portfolios, it seems like an active rebalancing strategy has beaten the DJI, based on portfolio value over 20 months

%% Now lets add alpha to the constraint matrix of the rolling portfolios and observe any changes (only doing the max sharpe ratio portfolios once again)
% Exact same code but with alpha as a constraint instead of a sample mean
% of returns from the time window
aroll_3a = zeros(30,20) ; 
aroll_3b = zeros(30,20) ; 
aroll_3c = zeros(59,20) ;
for q = 1:20
        aroll_3a(:,q) = quadprog([cov(rets(q:q+39,1:29)) zeros(29,1) ; zeros(1,30)],[],[],[], [a_rets' 0 ; ones(1,29) -1; samp_beta' -1],[1;0;0],zeros(30,1) );
        aroll_3b(:,q) = quadprog([cov(rets(q:q+39,1:29)) zeros(29,1) ; zeros(1,30)],[],[],[], [a_rets' 0 ; ones(1,29) -1; samp_beta' -1],[1;0;0] ); 
        aroll_3c(:,q) = quadprog([cov(rets(q:q+39,1:29)) zeros(29,30) ; zeros(30,59)],[],[-eye(29,29) -eye(29,29) zeros(29,1) ; zeros(1,29) ones(1,29) -.3],[zeros(30,1)],...
            [a_rets' zeros(1,30) ; ones(1,29) zeros(1,29) -1 ; samp_beta' zeros(1,29) -1],[1;0;0],[-inf(29,1); zeros(30,1)] );
end
clear q ; 

%% Clean up the portfolios again
% for the max sharpe ratio portfolios, divide kappa out of the z values
for i = 1:20
    aroll_3a(1:29,i) = aroll_3a(1:29,i)/aroll_3a(30,i) ;
    aroll_3b(1:29,i) = aroll_3b(1:29,i)/aroll_3b(30,i) ; 
    aroll_3c(1:29,i) = aroll_3c(1:29,i)/aroll_3c(59,i) ;
end
% take out the extra variables
aroll_3a = aroll_3a(1:29,:) ; 
aroll_3b = aroll_3b(1:29,:) ; 
aroll_3c = aroll_3c(1:29,:) ; 


aroll_3a_values = zeros(20,1); 
for i = 1:19
    aroll_3a_values(1) = 1000 ; 
    aroll_3a_values(i+1) = (dot(aroll_3a(:,i),os_rets(i,1:29)'+1))*aroll_3a_values(i,1) ; 
end
clear i ;
aroll_3b_values = zeros(20,1); 
for i = 1:19
    aroll_3b_values(1) = 1000 ; 
    aroll_3b_values(i+1) = (dot(aroll_3b(:,i),os_rets(i,1:29)'+1))*aroll_3b_values(i,1) ; 
end
clear i ; 
aroll_3c_values = zeros(20,1); 
for i = 1:19
    aroll_3c_values(1) = 1000 ; 
    aroll_3c_values(i+1) = (dot(aroll_3c(:,i),os_rets(i,1:29)'+1))*aroll_3c_values(i,1) ; 
end
clear i; 

graph7 = figure ; 
plot(plotx,DJI_value)
hold on
plot(plotx,aroll_3a_values)
plot(plotx,aroll_3c_values)

legend('DJI','MSR-L-Alpha', 'MSR-130-Alpha')
title('Value of DJI vs rolling Alpha MSR-long and MSR-130/30')
xlabel('months')
ylabel('portfolio value ($)')
hold off

graph8 = figure ;
plot(plotx,DJI_value)
hold on
plot(plotx,aroll_3b_values)

legend('DJI','MSR-LS-Alpha')
title('Value of DJI vs rolling Alpha Max Sharpe Ratio long short')
xlabel('months')
ylabel('portfolio value ($)')
hold off

%% Do the rolling variance plots again for the alpha portfolios

roll_DJI_var = zeros(20,1);
for i = 1:20
    roll_DJI_var(i) = var(rets(i:i+39,30)) ; 
end
clear i ; 
aroll_3a_var = zeros(20,1); 
aroll_3b_var = zeros(20,1) ;
aroll_3c_var = zeros(20,1) ; 
for i = 1:20
    aroll_3a_var(i) = aroll_3a(:,i)'*cov(rets(i:i+39,1:29))*aroll_3a(:,i) ; 
    aroll_3b_var(i) = aroll_3b(:,i)'*cov(rets(i:i+39,1:29))*aroll_3b(:,i) ; 
    aroll_3c_var(i) = aroll_3c(:,i)'*cov(rets(i:i+39,1:29))*aroll_3c(:,i) ; 
end
clear i ; 

% Plot the variances
graph9 = figure ; 
plot(plotx,roll_DJI_var)
hold on 
plot(plotx, aroll_3a_var)
plot(plotx,aroll_3c_var)

legend('DJI','MSR-L-Alpha', 'MSR-130-Alpha')
title('Rolling Variance of DJI vs Alpha MSR-L and MSR-130')
xlabel('months')
ylabel('variance')
hold off

graph10 = figure ; 
plot(plotx,roll_DJI_var)
hold on
plot(plotx,aroll_3b_var)

legend('DJI','MSR-LS-Alpha')
title('Rolling Variance of DJI vs Alpha MSR-LS')
xlabel('months')
ylabel('variance')
hold off

disp('Conclusions: After graphing the rolling portfolios that take analyst returns in consideration, it seems as though they perform worse than the DJI, with more variance.')
disp('Perhaps alpha is the difference between the returns you can yield from optimizing based on the sample mean of returns and those from optimizing with analyst returns')
disp('Another possibility is that analysts somehow achieved negative idiosyncratic return, maybe a function of outside forces in the market.')