% processes AET Gorilla task data and outputs for SPSS analysis
% need to filter out all but RT lines from Gorilla output first

clear all
n_ppts = 162; %number of ppts in Gorilla output
%%% create master datasheet
datasheet = ones(n_ppts,9);

%%% load Gorilla output file
gorilladata = xlsread('AETdata_MatlabPay.xlsx');

%%% loop through datafiles
for p = 1:n_ppts
    
    pptID = gorilladata((((p-1)*160)+1),13); % (p*160)-159 is first row or (p-1)*160)+1 to the same +160
    datasheet(p,1) = pptID; % need to point it to a non-text value for pay ppts - column 12 above for credit, column 13 for pay
    
        data.trial = gorilladata((((p-1)*160)+1):(p*160),33);%column 31 for credit, 33 for pay
        data.rt = gorilladata((((p-1)*160)+1):(p*160),38);%column 36 for credit, 38 for pay
        data.err = gorilladata((((p-1)*160)+1):(p*160),44);%column 41 is correct, 42 is incorrect for credit, 43/44 for pay
        data.laterality = gorilladata((((p-1)*160)+1):(p*160),55);%53 thro 56 for credit, 55-58 for pay
        data.socialness = gorilladata((((p-1)*160)+1):(p*160),56); %%%NO - CHECK THIS
        data.painfulness = gorilladata((((p-1)*160)+1):(p*160),57); %%%NO - CHECK THIS
        data.limb = gorilladata((((p-1)*160)+1):(p*160),58);
        
    %%% pull together data variables for this ppt 
    results(:,1:7) = [data.trial, data.limb, data.laterality, data.painfulness, data.socialness, data.err, data.rt]; 
    
    rts = results(:,7);
    errors = results(:,6);
    
    for t = 1:160
            if results(t,6)==0&&results(t,4)==1&&results(t,5)==1 %accurate socail pain trial
                results(t,10)=1; %social pain
            elseif results(t,6)==0&&results(t,4)==1&&results(t,5)==0 
                results(t,10)=2; %soc no pain
            elseif results(t,6)==0&&results(t,4)==0&&results(t,5)==1
                results(t,10)=3; %nonsoc Pain
            elseif results(t,6)==0&&results(t,4)==0&&results(t,5)==0
                results(t,10)=4; %nonsocial nopain
            else
                results(t,10)=0;
            end
       end
    
sopamean = mean(rts(results(:,10)==1)); 
sopasd = std(rts(results(:,10)==1));
nspamean = mean(rts(results(:,10)==2));
nspasd = std(rts(results(:,10)==2));
sonpmean = mean(rts(results(:,10)==3));
sonpsd = std(rts(results(:,10)==3));
nsnpmean = mean(rts(results(:,10)==4));
nsnpsd = std(rts(results(:,10)==4)); 
for t=1:160
    switch(results(t,10))
        case 1
            if results(t,7)>sopamean+(2.5*sopasd)||results(t,7)<sopamean-(2.5*sopasd)
                results(t,10)=0; %outlying RT
            end
        case 2
            if results(t,7)>nspamean+(2.5*nspasd)||results(t,7)<nspamean-(2.5*nspasd)
                results(t,10)=0;
            end
        case 3
            if results(t,7)>sonpmean+(2.5*sonpsd)||results(t,7)<sonpmean-(2.5*sonpsd)
                results(t,10)=0; %outlying RT
            end
        case 4
            if results(t,7)>nsnpmean+(2.5*nsnpsd)||results(t,7)<nsnpmean-(2.5*nsnpsd)
                results(t,10)=0;
            end
            
    end 
end
%results column 10 now has 0 for outlying RTs or errors, 1/2/3/4 for the four
%conditions 

%%% now find means for each condition
sopameanrt = mean(rts(results(:,10)==1)); 
nspameanrt = mean(rts(results(:,10)==2));
sonpmeanrt = mean(rts(results(:,10)==3));
nsnpmeanrt = mean(rts(results(:,10)==4));
overallmeanrt = mean(rts(results(:,10)>0));

for t = 1:160
            if results(t,4)==1&&results(t,5)==1 % socail pain trial
                results(t,8)=1; %social pain
            elseif results(t,4)==1&&results(t,5)==0 
                results(t,8)=2; %social nopain
            elseif results(t,4)==0&&results(t,5)==1
                results(t,8)=3; %nonsocial pain
            elseif results(t,4)==0&&results(t,5)==0
                results(t,8)=4; %nonsocial nopain
            end
end

%results column 8 now has codes 1-4 for four conditions ignoring outlying
%RTs or errors
sopaerrors = sum(errors(results(:,8)==1));
nspaerrors = sum(errors(results(:,8)==2));
sonperrors = sum(errors(results(:,8)==3));
nsnperrors = sum(errors(results(:,8)==4));
totalerrors = sum(errors);

%%% add the values to the overall datasheet
datasheet(p,2:11) = [overallmeanrt totalerrors sopameanrt nspameanrt sonpmeanrt nsnpmeanrt sopaerrors nspaerrors sonperrors nsnperrors];
end
%%% save datasheet
save('AETdata4.mat','datasheet'); % as mat file
dlmwrite('AETdata4.csv', datasheet); %create a csv file
