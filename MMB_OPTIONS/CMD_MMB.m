function CMD_MMB(varargin)

%clear all; clc; close all;
% modelsvec = zeros(1,93); modelsvec(1, [3 65]) = 1;
% rule = zeros(1,11); rule(1,3) = 1;
% CMD_MMB('excersie',1,'modelsvec', modelsvec ,'rule',rule ,'shocks', [1, 0],'option1',0)
% CMD_MMB('exercise',2,'modelsvec', [1; zeros(92,1)]','rule',[zeros(2,1) ;  1; 1; zeros(7,1)]' ,'shocks', [1, 0],'option1',1)
%  CMD_MMB('excersie',1,'modelsvec', [1;1; zeros(90,1);1]','rule',[zeros(2,1) ;  1; 1; zeros(7,1)]' ,'shocks', [1, 1],'option1',1)
%  CMD_MMB('excersie',1,'modelsvec', [1;1; zeros(90,1);1]','rule',[zeros(2,1) ;  1; 1; zeros(7,1)]' ,'shocks', [1, 1],'option1',1)

%%%%%%%%%%%%%%%%%%% Declaration of key settings
warning('off','all')
%% Adding dynare to path if it was not
addpath c:\dynare\4.5.0\matlab
%% Adding MMB to path (required for Dynare and Octave)
cd(fileparts(mfilename('fullpath')));
cd ..
currentpath= cd;  cd(currentpath);
addpath(currentpath);
addpath([currentpath num2str('\ALTOOL\')]);
addpath([currentpath num2str('\MODELS\')]);
newpath=[currentpath num2str('\MMB_OPTIONS\')];
cd([currentpath num2str('\MMB_OPTIONS\')])

%% Loading in the MMB Settings
MMB_settings
% load Modelbase
%% Adding folder structure to path
modelbase.homepath = cd; cd(modelbase.homepath); addpath(modelbase.homepath);
modelbase.uphomepath =cd(cd('..')); addpath(modelbase.uphomepath);
%% Creating the additional variables needed
modelbase.totaltime = cputime;
modelbase.models = find(modelsvec~=0);
modelbase.savepath = [modelbase.uphomepath num2str('\OUTPUT\') num2str('results.xls')];
modelbase.rule = find(rule==1);
xls_check_if_open(modelbase.savepath, 'close');
if strcmp(results, 'results.xls')
    delete(modelbase.savepath); % overwrite the output file 'results.xls' if no output file is specified by the user
else
    modelbase.savepath = [modelbase.uphomepath num2str('\OUTPUT\') results]; % create a new output file
end
solution_found = zeros(size(find(modelsvec~=0)')); % solution_found(number)= 1 if a solution is found and 0 else

save Modelbase modelbase                                % neccessary to save in between as dynare clears the workspace

if modelbase.exercise == 1;
    %% One rule many models have been chosen
    disp('One policy rule, many models exercise has been selected.');
    disp(' ')
    disp('Selected Policy Rule:');
    disp(deblank(modelbase.rulenames(modelbase.rule,:)));
    disp(' ');
    disp('Selected options:');
    if modelbase.option(1) == 1
        disp('Autocorrelation functions will be plotted.');
    else disp('Autocorrelation functions will not be plotted.');
    end
    
    if modelbase.option(2) == 1
        disp('Impulse response functions will be plotted.');
    else disp('Impulse response functions will not be plotted.');
    end
    
    modelbase.namesshocks= char(['Mon. Pol. Shock      '
        'Fiscal Pol. Shock    ']);
    modelbase.namesinnos= char(['interest_'
        'fiscal_  ']);
    
    choices=[]; % initialize, otherwise we have an error when trying to save
    modelbase.innos = [];
    choices=find(shocks>0);
    if modelbase.option(2)==1
        choice=1;
        disp(' ');
        disp('Selected shocks:');
        modelbase.innos=modelbase.namesinnos(choices,:);
        modelbase.namesshocks = modelbase.namesshocks(choices,:); % this is neccesary for plotting the right shock in the right figure otherwise the order might get confused
        disp(modelbase.namesshocks)
        %end
    end;
    for epsilon=1:size(modelbase.models,2)
        %tic
        modelbase.modeltime(modelbase.models(epsilon)) = cputime;
        modelbase.setpath(modelbase.models(epsilon),:) = [modelbase.uphomepath num2str('\MODELS\') num2str(modelbase.names(modelbase.models(epsilon),:))]; % path for dynare file of specific model
        modelbase.epsilon = epsilon;
        al=deblank(modelbase.names(modelbase.models(epsilon),:));
        modelbase.AL=strcmp(al(end-1:end),'AL');
        if modelbase.AL
            if ~ismember(modelbase.rule,[8 9 10])
                control=0;
                while control==0
                    gain=str2num(selectgain(modelbase.names,modelbase.models,epsilon));
                    if gain>=0 && gain<=0.05
                        control=1;
                    end
                end
                modelbase.control=control;
                modelbase.gain=gain;
                modelbase.ModelGAIN(modelbase.models(epsilon))=modelbase.gain;
            else
                modelbase.gain=0;
                modelbase.ModelGAIN(modelbase.models(epsilon))=modelbase.gain;
                modelbase.control=[];
            end
        end
        
        save -append Modelbase modelbase
        cd(modelbase.setpath(modelbase.models(epsilon),:));      % go to directory of specific model
        disp(' ');
        disp(['Currently Solving: ', num2str(deblank(modelbase.names((modelbase.models(epsilon)),:)))]);
        eval(['dynare '  modelbase.names(modelbase.models(epsilon),:)]);% solve model "epsilon" in dynare by running the .mod file --> translates Dynare syntax into .m file, that is run
        cd('..');
        cd('..'); % insert one more cd('..');
        cd MMB_OPTIONS
        load Modelbase
        options_.ar=100;
        if modelbase.AL
            if ~ismember(modelbase.rule,[8 9 10])
                thepath=cd;
                cd(modelbase.setpath(modelbase.models(epsilon),:))
                load AL_Info
                cd(thepath);
                AL_.forwards = AL_Info.forwards;
                if ismember(modelbase.rule,[6 7])
                    AL_.states = AL_Info.states_short;
                else
                    AL_.states = AL_Info.states_long;
                end
                %menu for selection of states for learning
                control_sel_states=0;
                while control_sel_states==0
                    rb_temp=menu_AL_select_states;
                    if sum(rb_temp)==1
                        control_sel_states=1;
                    end
                end
                if rb_temp(2)==1
                    while control_sel_states==1
                        rb2_temp=menu_AL_select_subset(AL_.states);
                        if size(rb2_temp,2)~=0
                            control_sel_states=2;
                            AL_.states=rb2_temp;
                        end
                    end
                end
                modelbase.AL_=AL_;
                modelbase.ModelStates(modelbase.models(epsilon))={modelbase.AL_.states};
            else
                modelbase.AL_=[];
                modelbase.ModelStates(modelbase.models(epsilon))={[]};
            end
        end
        save -append Modelbase modelbase
        modelbase=stoch_simul_MMB(modelbase);                                     % solve model
        % Octave version check
        if (exist ('OCTAVE_VERSION', 'builtin') > 0)
            epsilon = modelbase.epsilon;
        end
        solution_found(epsilon)=modelbase.solution;
        cd(modelbase.homepath);                                                   % go back to main directory
        %toc
        modelbase.modeltime(modelbase.models(modelbase.epsilon))=cputime-modelbase.modeltime(modelbase.models(modelbase.epsilon));
        disp(['Elapsed cputime is ' ,num2str(modelbase.modeltime(modelbase.models(modelbase.epsilon))), ' seconds.']);
    end;
    
    %**********************************************************************************************************************
    %                    Display Variances on screen                                                                    %
    %**********************************************************************************************************************
    statusbar(0, 'Busy...');
    if modelbase.option(5) == 1
        disp(' ')
        disp('Variance of the model variables you have chosen:')
        disp(' ')
        for j=1:size(modelbase.models,2)
            if modelbase.info(modelbase.models(j))==0
                disp(' ')
                disp(num2str(modelbase.names(modelbase.models(:,j),:)));
                disp(' ')
                disp('Variables           Variance       ')
                %Plotting the variance of interest rate
                vname='Interest ';
                var = modelbase.VAR.(num2str(deblank(modelbase.names(modelbase.models(j),:))))(loc(modelbase.VARendo_names.(num2str(deblank(modelbase.names(modelbase.models(j),:)))),'interest'),loc(modelbase.VARendo_names.(num2str(deblank(modelbase.names(modelbase.models(j),:)))),'interest'));
                st = sprintf('%9s %19f',...
                    vname,var);
                disp(st)
                %Plotting the variance of inflation
                vname='Inflation';
                var = modelbase.VAR.(num2str(deblank(modelbase.names(modelbase.models(j),:))))(loc(modelbase.VARendo_names.(num2str(deblank(modelbase.names(modelbase.models(j),:)))),'inflation'),loc(modelbase.VARendo_names.(num2str(deblank(modelbase.names(modelbase.models(j),:)))),'inflation'));
                st = sprintf('%9s %19f',...
                    vname,var);
                disp(st)
                %Plotting the variance of outputgap
                vname='outputgap';
                var = modelbase.VAR.(num2str(deblank(modelbase.names(modelbase.models(j),:))))(loc(modelbase.VARendo_names.(num2str(deblank(modelbase.names(modelbase.models(j),:)))),'outputgap'),loc(modelbase.VARendo_names.(num2str(deblank(modelbase.names(modelbase.models(j),:)))),'outputgap'));
                st = sprintf('%9s %19f',...
                    vname,var);
                disp(st)
                if loc(modelbase.VARendo_names.(num2str(deblank(modelbase.names(modelbase.models(j),:)))),'output')~=0
                    %Plotting the variance of output
                    vname='output   ';
                    var = modelbase.VAR.(num2str(deblank(modelbase.names(modelbase.models(j),:))))(loc(modelbase.VARendo_names.(num2str(deblank(modelbase.names(modelbase.models(j),:)))),'output'),loc(modelbase.VARendo_names.(num2str(deblank(modelbase.names(modelbase.models(j),:)))),'output'));
                    st = sprintf('%9s %19f',...
                        vname,var);
                    disp(st)
                end;
            end;
        end;
    end;
    statusbar(0, 'Busy...');
    %**********************************************************************************************************************
    %                    Set up figures, plot results                                                                     %
    %**********************************************************************************************************************
    time = (0:modelbase.horizon)';
    if modelbase.option(2)==1
        for p=1:size(modelbase.innos,1)
            % plot impulse responses
            warning off
            if strcmp(modelbase.namesshocks(p,:),'Mon. Pol. Shock      ')
                figHandle{1}=figure;
                set(figHandle{1}, 'visible', 'off');
            elseif strcmp(modelbase.namesshocks(p,:),'Fiscal Pol. Shock    ')
                figHandle{2} = figure;
                set(figHandle{2}, 'visible', 'off');
            end;
            orient landscape
            modelplottedIRF=[];
            for j=1:size(modelbase.models,2)
                if modelbase.pos_shock(p,modelbase.models(j))~=0
                    modelplottedIRF=[modelplottedIRF modelbase.models(j)]; % this is neccessary to plot a proper legend, that ignores the models,
                    % which lack the specific shock
                    subplot(2,2,1)
                    plot(time,modelbase.IRF.(num2str(deblank(modelbase.names(modelbase.models(j),:))))(loc(modelbase.IRFendo_names.(num2str(deblank(modelbase.names(modelbase.models(j),:)))),'outputgap'),:,p),modelbase.mycolor(j,:),'LineWidth',2,'MarkerSize',5); hold on
                    grid on
                    title('Output Gap','FontUnits','normalized')
                    legend(num2str(modelbase.namesplot(modelplottedIRF,:)));
                    subplot(2,2,2)
                    plot(time,modelbase.IRF.(num2str(deblank(modelbase.names(modelbase.models(j),:))))(loc(modelbase.IRFendo_names.(num2str(deblank(modelbase.names(modelbase.models(j),:)))),'inflation'),:,p),modelbase.mycolor(j,:),'LineWidth',2,'MarkerSize',5); hold on
                    grid on
                    title('Inflation','FontUnits','normalized')
                    subplot(2,2,3)
                    plot(time,modelbase.IRF.(num2str(deblank(modelbase.names(modelbase.models(j),:))))(loc(modelbase.IRFendo_names.(num2str(deblank(modelbase.names(modelbase.models(j),:)))),'interest'),:,p),modelbase.mycolor(j,:),'LineWidth',2,'MarkerSize',5); hold on
                    grid on
                    title('Interest Rate','FontUnits','normalized')
                    if loc(modelbase.IRFendo_names.(num2str(deblank(modelbase.names(modelbase.models(j),:)))),'output')~=0
                        subplot(2,2,4)
                        plot(time,modelbase.IRF.(num2str(deblank(modelbase.names(modelbase.models(j),:))))(loc(modelbase.IRFendo_names.(num2str(deblank(modelbase.names(modelbase.models(j),:)))),'output'),:,p),modelbase.mycolor(j,:),'LineWidth',2,'MarkerSize',5); hold on
                        grid on
                        title('Output','FontUnits','normalized')
                    end
                end;
            end;
        end;
    end
    
    
    
    if modelbase.option(1)==1
        % plot autocorrelation function
        time = (0:modelbase.horizon)';
        figHandle{3}=figure;
        set(figHandle{3}, 'visible', 'off');
        warning off
        orient landscape
        modelplottedAC=[];
        for j=1:size(modelbase.models,2)
            if modelbase.info(modelbase.models(j))==0
                modelplottedAC=[modelplottedAC modelbase.models(j)]; % this is neccessary to plot a proper legend, that ignores the models, which lack the specific shock
                subplot(2,2,1)
                plot(time,modelbase.AUTR.(num2str(deblank(modelbase.names(modelbase.models(j),:))))(loc(modelbase.AUTendo_names.(num2str(deblank(modelbase.names(modelbase.models(j),:)))),'outputgap'),:),modelbase.mycolor(j,:),'LineWidth',2,'MarkerSize',5); hold on
                grid on
                title('Output gap','FontUnits','normalized')
                legend(num2str(modelbase.namesplot(modelplottedAC,:)));
                
                subplot(2,2,2)
                plot(time,modelbase.AUTR.(num2str(deblank(modelbase.names(modelbase.models(j),:))))(loc(modelbase.AUTendo_names.(num2str(deblank(modelbase.names(modelbase.models(j),:)))),'inflation'),:),modelbase.mycolor(j,:),'LineWidth',2,'MarkerSize',5); hold on
                grid on
                title('Inflation','FontUnits','normalized')
                
                subplot(2,2,3)
                plot(time,modelbase.AUTR.(num2str(deblank(modelbase.names(modelbase.models(j),:))))(loc(modelbase.AUTendo_names.(num2str(deblank(modelbase.names(modelbase.models(j),:)))),'interest'),:),modelbase.mycolor(j,:),'LineWidth',2,'MarkerSize',5); hold on
                grid on
                title('Interest Rate','FontUnits','normalized')
                
                if loc(modelbase.AUTendo_names.(num2str(deblank(modelbase.names(modelbase.models(j),:)))),'output')~=0
                    subplot(2,2,4)
                    plot(time,modelbase.AUTR.(num2str(deblank(modelbase.names(modelbase.models(j),:))))(loc(modelbase.AUTendo_names.(num2str(deblank(modelbase.names(modelbase.models(j),:)))),'output'),:),modelbase.mycolor(j,:),'LineWidth',2,'MarkerSize',5); hold on
                    grid on
                    title('Output','FontUnits','normalized')
                end
            end
        end
    end
    if ~isempty(find(solution_found>0))
        if modelbase.option(2)==1
            for p=1:size(modelbase.innos,1)
                % Show impulse responses
                warning off
                orient landscape
                if  strcmp(modelbase.namesshocks(p,:),'Mon. Pol. Shock      ')
                    figure(figHandle{1});
                    set(subplot(2,2,1), 'Position',[0.131 0.495 0.335 0.341])
                    set(subplot(2,2,2), 'Position',[0.570 0.495 0.335 0.341])
                    set(subplot(2,2,3), 'Position',[0.131 0.066 0.335 0.341])
                    isoutput=0;
                    for j=1:size(modelbase.models,2)
                        if (modelbase.pos_shock(p,modelbase.models(j))~=0)
                            isoutput=isoutput+((loc(modelbase.IRFendo_names.(num2str(deblank(modelbase.names(modelbase.models(j),:)))),'output')~=0));
                        end
                    end
                    if isoutput>0
                        set(subplot(2,2,4), 'Position',[0.570 0.066 0.335 0.341])
                    else set(subplot(2,2,4), 'visible','off')
                    end
                    annotation('textbox', [0.0007 0.891 1 0.1], ...
                        'String', ['IRF ',num2str(deblank(modelbase.namesshocks(p,:))) ': ' modelbase.rulenamesshort(modelbase.rule,:)], ...%[0.5 0.8 0.95 0.1]
                        'EdgeColor', 'none', 'FontUnits','normalized',...
                        'HorizontalAlignment', 'center');
                    set(figHandle{1}, 'visible', 'on')
                elseif  strcmp(modelbase.namesshocks(p,:),'Fiscal Pol. Shock    ')
                    isfiscal=0;
                    isoutput=0;
                    for j=1:size(modelbase.models,2)
                        isfiscal=isfiscal+(modelbase.pos_shock(p,modelbase.models(j))~=0);
                        if (modelbase.pos_shock(p,modelbase.models(j))~=0)
                            isoutput=isoutput+((loc(modelbase.IRFendo_names.(num2str(deblank(modelbase.names(modelbase.models(j),:)))),'output')~=0));
                        end
                    end
                    if isfiscal>0
                        figure(figHandle{2});
                        set(subplot(2,2,1), 'Position',[0.131 0.495 0.335 0.341])
                        set(subplot(2,2,2), 'Position',[0.570 0.495 0.335 0.341])
                        set(subplot(2,2,3), 'Position',[0.131 0.066 0.335 0.341])
                        if isoutput>0
                            set(subplot(2,2,4), 'Position',[0.570 0.066 0.335 0.341])
                        else set(subplot(2,2,4), 'visible','off')
                        end
                        annotation('textbox', [0.0007 0.891 1 0.1], ...
                            'String', ['IRF ',num2str(deblank(modelbase.namesshocks(p,:))) ': ' modelbase.rulenamesshort(modelbase.rule,:)], ...%[0.5 0.8 0.95 0.1]
                            'EdgeColor', 'none', 'FontUnits','normalized',...
                            'HorizontalAlignment', 'center');
                        set(figHandle{2}, 'visible', 'on')
                    end
                end
            end
        end;
        if modelbase.option(1)==1
            figure(figHandle{3});
            set(subplot(2,2,1), 'Position',[0.131 0.495 0.335 0.341])
            set(subplot(2,2,2), 'Position',[0.570 0.495 0.335 0.341])
            set(subplot(2,2,3), 'Position',[0.131 0.066 0.335 0.341])
            isoutput=0;
            for j=1:size(modelbase.models,2)
                if modelbase.info(modelbase.models(j))==0
                    isoutput=isoutput+((loc(modelbase.AUTendo_names.(num2str(deblank(modelbase.names(modelbase.models(j),:)))),'output')~=0));
                end
            end
            if isoutput>0
                set(subplot(2,2,4), 'Position',[0.570 0.066 0.335 0.341])
            else set(subplot(2,2,4), 'visible','off')
            end
            
            annotation('textbox', [0.0007 0.891 1 0.1], ...
                'String', ['Autocorrelation Function: ' modelbase.rulenamesshort(modelbase.rule,:)], ...%[0.5 0.8 0.95 0.1]
                'EdgeColor', 'none', 'FontUnits','normalized',...
                'HorizontalAlignment', 'center');
            set(figHandle{3}, 'visible', 'on');
        end
    end
    modelbase.totaltime = cputime-modelbase.totaltime;
    disp(' '); disp(' ');
    disp(['Total elapsed cputime: ' ,num2str(modelbase.totaltime), ' seconds.']);
    
    % save the results
    keyvariables = ['outputgap';
        'inflation';
        'interest ';
        'output   '];
    for p=1:size(modelbase.innos,1)
        rownr = 1;
        result.IRF.(num2str(deblank(modelbase.innos(p,:))))(rownr,:) = {num2str(deblank(modelbase.namesshocks(p,:)))}; rownr = rownr+1;
        for k = 1:size(keyvariables,1);
            result.IRF.(num2str(deblank(modelbase.innos(p,:))))(rownr,1) = {keyvariables(k,:)}; rownr = rownr+1;
            for j=1:size(modelbase.models,2)
                result.IRF.(num2str(deblank(modelbase.innos(p,:))))(rownr,1) = {num2str(deblank(modelbase.names(modelbase.models(j),:)))};
                if modelbase.info(modelbase.models(j)) == 0
                    if isfield(modelbase,'IRFendo_names') == 1
                        if isfield(modelbase.IRFendo_names,(num2str(deblank(modelbase.names(modelbase.models(j),:)))));
                            if loc(modelbase.IRFendo_names.(num2str(deblank(modelbase.names(modelbase.models(j),:)))),keyvariables(k,:))~=0 && modelbase.pos_shock(p,modelbase.models(j))~=0
                                for i=1:modelbase.horizon+1
                                    result.IRF.(num2str(deblank(modelbase.innos(p,:))))(rownr,i+1) = {modelbase.IRF.(num2str(deblank(modelbase.names(modelbase.models(j),:))))(loc(modelbase.IRFendo_names.(num2str(deblank(modelbase.names(modelbase.models(j),:)))),keyvariables(k,:)),i,p)};
                                end
                            end
                        else
                            result.IRF.(num2str(deblank(modelbase.innos(p,:))))(rownr,2:modelbase.horizon+2) = {[]};
                        end
                    else
                        result.IRF.(num2str(deblank(modelbase.innos(p,:))))(rownr,2:modelbase.horizon+2) = {[]};
                    end
                    try
                        ListStates=modelbase.ModelStates(modelbase.models(j));
                        result.AL{rownr} = [{num2str(deblank(modelbase.names(modelbase.models(j),:)))},...
                            {'Gain'},{num2str(modelbase.ModelGAIN(modelbase.models(j)))},...
                            {'States'}, ListStates{:}];
                    catch
                    end
                    
                else
                    result.IRF.(num2str(deblank(modelbase.innos(p,:))))(rownr,2:modelbase.horizon+2) = {[]};
                end
                try
                    if p==1&&k==1
                        xlswrite(modelbase.savepath, result.AL{rownr}, 'AL Settings',['A' num2str(rownr)]);
                    end
                catch
                end
                rownr = rownr+1;
            end
        end
        xlswrite(modelbase.savepath, result.IRF.(num2str(deblank(modelbase.innos(p,:)))), ['IRF ' modelbase.namesshocks(p,:)]);
    end
    if modelbase.option(1) ==1
        rownr  = 1;
        for k = 1:size(keyvariables,1);
            result.AC(rownr,1) = {keyvariables(k,:)}; rownr = rownr+1;
            for j=1:size(modelbase.models,2)
                result.AC(rownr,1) = {num2str(deblank(modelbase.names(modelbase.models(j),:)))};
                if modelbase.info(modelbase.models(j)) == 0
                    if loc(modelbase.AUTendo_names.(num2str(deblank(modelbase.names(modelbase.models(j),:)))),keyvariables(k,:))~=0
                        for i=1:modelbase.horizon+1
                            result.AC(rownr,i+1) = {modelbase.AUTR.(num2str(deblank(modelbase.names(modelbase.models(j),:))))(loc(modelbase.AUTendo_names.(num2str(deblank(modelbase.names(modelbase.models(j),:)))),keyvariables(k,:)),i)};
                        end
                    else
                        result.AC(rownr,2:modelbase.horizon+2) = {[]};
                    end
                else
                    result.AC(rownr,2:modelbase.horizon+2) = {[]};
                end
                rownr = rownr+1;
            end
        end
        xlswrite(modelbase.savepath, result.AC, 'ACF');
    end
    
    %Saving the IRFs of all variables in Excel, if one Model is chosen
    if size(modelbase.models,2)==1
        if modelbase.info(modelbase.models(modelbase.epsilon))==0
            if isfield(modelbase,'IRFendo_names') == 1
                for p=1:size(modelbase.innos,1)
                    for i=1:size(modelbase.IRFendo_names.(num2str(deblank(modelbase.names(modelbase.models(1),:)))),1)
                        result.allIRFs(i,1)={modelbase.IRFendo_names.(num2str(deblank(modelbase.names(modelbase.models(1),:))))(i,:)};
                    end;
                    if modelbase.pos_shock(p,modelbase.models(1))~=0
                        for j=1:size(modelbase.IRF.(num2str(deblank(modelbase.names(modelbase.models(1),:))))(:,:,p),1)
                            for k=1:size(modelbase.IRF.(num2str(deblank(modelbase.names(modelbase.models(1),:))))(:,:,p),2)
                                result.allIRFs(j,k+1)={modelbase.IRF.(num2str(deblank(modelbase.names(modelbase.models(1),:))))(j,k,p)};
                            end;
                        end;
                        xlswrite(modelbase.savepath, result.allIRFs, ['all IRFs ' num2str(deblank(modelbase.namesshocks(p,:)))]);
                    end;
                end;
            end;
        end;
    else
    end;
    statusbar(0, '');
    try
        modelbase=rmfield(modelbase,'figHandle');
        modelbase=rmfield(modelbase,'figHandleRest');
    catch
    end
    save Modelbase.mat modelbase % Save settings
    rmpath(modelbase.homepath);
    
else
    %% One model many rules
    disp('One model many policy rules exercise has been selected.');
    modelbase.rule=rule;
    rulechosen=find(rule>0);
    modelbase.info = ones(size(rule,2),1);
    modelbase.modelchosen=find(modelsvec>0);
    modelbase.modelplottedIRF=[];
    modelbase.modelplottedIRF=modelbase.modelchosen; % this is neccessary to plot a proper legend, that ignores the models,
    modelbase.time = (0:modelbase.horizon)';
    modelbase.time2 = (0:modelbase.horizon)';
    modelbase.str={};
    modelbase.rulelegend=[];
    modelbase.rownrfp = 1;modelbase.rownrmp=1;
    modelbase.rulerank=0;  
    modelbase.myrulecolor = myrulecolor;
    disp(' ');
    disp('Selected options:');
    if modelbase.option(1) == 1
        disp('Autocorrelation functions will be plotted.');
    else disp('Autocorrelation functions will not be plotted.');
    end
    modelbase.option(2) = option2;
    modelbase.namesshocks= char(['Mon. Pol. Shock      '
        'Fiscal Pol. Shock    ']);
    modelbase.namesinnos= char(['interest_'
        'fiscal_  ']);
    if modelbase.option(2) == 1
        disp('Impulse response functions will be plotted.');
    else disp('Impulse response functions will not be plotted.');
    end
    
    modelbase.innos = [];
    choices=find(modelbase.shocks>0);
    if modelbase.option(2)==1
        if modelbase.option(6)==1
            inno='allshocks';
            modelbase.innos=inno;
        else modelbase.innos=modelbase.namesinnos(choices,:);
        end
        modelbase.namesshocks = modelbase.namesshocks(choices,:);
        % this is neccesary for plotting the right shock in the right figure otherwise the order might get confused; if all model specific shocks are chosen, we put [] here. The names are assigned in stoch_simul_modelbase
        
    end;
    
    %%
    %%%%%%%%   Loop for Solving a model together with each chosen rule and producing results %%%%%%
    
    for i=1:size(modelbase.rulenames,1)
        if (modelbase.rule(i)>0) % If the i-th rule has been chosen
            modelbase.l=i; %Save the legend for the i-th rule
            %% The code block for rule choices
            if (i>2)
                
                cofintintb1 = modelbase.common_rule(i,1); cofintintb2 = modelbase.common_rule(i,2); cofintintb3 = modelbase.common_rule(i,3);
                cofintintb4 = modelbase.common_rule(i,4); cofintinf0 = modelbase.common_rule(i,5); cofintinfb1 = modelbase.common_rule(i,6); cofintinfb2 = modelbase.common_rule(i,7);
                cofintinfb3 = modelbase.common_rule(i,8); cofintinfb4 = modelbase.common_rule(i,9); cofintinff1 = modelbase.common_rule(i,10); cofintinff2 = modelbase.common_rule(i,11);
                cofintinff3 = modelbase.common_rule(i,12); cofintinff4 = modelbase.common_rule(i,13); cofintout = modelbase.common_rule(i,14); cofintoutb1 = modelbase.common_rule(i,15);
                cofintoutb2 = modelbase.common_rule(i,16); cofintoutb3 = modelbase.common_rule(i,17); cofintoutb4 = modelbase.common_rule(i,18); cofintoutf1 = modelbase.common_rule(i,19);
                cofintoutf2 = modelbase.common_rule(i,20); cofintoutf3 = modelbase.common_rule(i,21); cofintoutf4 = modelbase.common_rule(i,22);
                cofintoutp = modelbase.common_rule(i,23); cofintoutpb1 = modelbase.common_rule(i,24); cofintoutpb2 = modelbase.common_rule(i,25); cofintoutpb3 = modelbase.common_rule(i,26);
                cofintoutpb4 = modelbase.common_rule(i,27); cofintoutpf1 = modelbase.common_rule(i,28); cofintoutpf2 = modelbase.common_rule(i,29); cofintoutpf3 = modelbase.common_rule(i,30);
                cofintoutpf4 = modelbase.common_rule(i,31);
                std_r_ = modelbase.common_rule(i,32);
                std_r_quart = modelbase.common_rule(i,33);
                disp(' ')
                disp('Selected Policy Rule:');
                disp(deblank(modelbase.rulenames(i,:)));
                
            elseif i==1
                %
                % User-specified policy rule
                %
                
                cofintintb1 =  modelbase.data(2,1); cofintintb2 = modelbase.data(3,1); cofintintb3 = modelbase.data(4,1); cofintintb4 = modelbase.data(5,1);
                cofintinf0 = modelbase.data(1,2); cofintinfb1 = modelbase.data(2,2); cofintinfb2 = modelbase.data(3,2); cofintinfb3 = modelbase.data(4,2); cofintinfb4 = modelbase.data(5,2);
                cofintinff1 = modelbase.data(6,2); cofintinff2 = modelbase.data(7,2); cofintinff3 = modelbase.data(8,2); cofintinff4 = modelbase.data(9,2);
                cofintout = modelbase.data(1,3); cofintoutb1 = modelbase.data(2,3); cofintoutb2 = modelbase.data(3,3); cofintoutb3 = modelbase.data(4,3); cofintoutb4 = modelbase.data(5,3);
                cofintoutf1 = modelbase.data(6,3); cofintoutf2 = modelbase.data(7,3); cofintoutf3 = modelbase.data(8,3); cofintoutf4 = modelbase.data(9,3);
                cofintoutp = modelbase.data(1,4); cofintoutpb1 = modelbase.data(2,4); cofintoutpb2 = modelbase.data(3,4); cofintoutpb3 = modelbase.data(4,4); cofintoutpb4 = modelbase.data(5,4);
                cofintoutpf1 = modelbase.data(6,4); cofintoutpf2 = modelbase.data(7,4); cofintoutpf3 = modelbase.data(8,4); cofintoutpf4 = modelbase.data(9,4);
                std_r_ = 1;
                std_r_quart = 0.25;
                disp(' ')
                disp('Selected Policy Rule:');
                disp(deblank(modelbase.rulenames(i,:)));
            elseif  i==2
                %
                % Original Model-Specific Policy Rule
                %
                coeff_vec=MSR_COEFFS(modelbase.modelchosen);
                cofintintb1 =  coeff_vec(1); cofintintb2 = coeff_vec(2); cofintintb3 = coeff_vec(3); cofintintb4 = coeff_vec(4);
                cofintinf0 = coeff_vec(5); cofintinfb1 = coeff_vec(6); cofintinfb2 = coeff_vec(7); cofintinfb3 = coeff_vec(8); cofintinfb4 = coeff_vec(9);
                cofintinff1 = coeff_vec(10); cofintinff2 = coeff_vec(11); cofintinff3 = coeff_vec(12); cofintinff4 = coeff_vec(13);
                cofintout = coeff_vec(14); cofintoutb1 = coeff_vec(15); cofintoutb2 = coeff_vec(16); cofintoutb3 = coeff_vec(17); cofintoutb4 = coeff_vec(18);
                cofintoutf1 = coeff_vec(19); cofintoutf2 =  coeff_vec(20); cofintoutf3 = coeff_vec(21); cofintoutf4 = coeff_vec(22);
                cofintoutp = coeff_vec(23); cofintoutpb1 = coeff_vec(24); cofintoutpb2 = coeff_vec(25); cofintoutpb3 = coeff_vec(26); cofintoutpb4 = coeff_vec(27);
                cofintoutpf1 = coeff_vec(28); cofintoutpf2 =  coeff_vec(29); cofintoutpf3 = coeff_vec(30); cofintoutpf4 = coeff_vec(31);
                std_r_ = coeff_vec(32);
                std_r_quart = coeff_vec(33);
                disp(' ')
                disp('Selected Policy Rule:');
                disp('Model Specific Policy Rule');
                
            end
            %%
            
            %**********************************************************************************************************************
            %                                DON'T CHANGE ANYTHING AFTER THIS LINE                                                %
            %**********************************************************************************************************************
            
            cd('..');
            cd MODELS
            save policy_param.mat cofintintb1 cofintintb2 cofintintb3 cofintintb4...
                cofintinf0 cofintinfb1 cofintinfb2 cofintinfb3 cofintinfb4 cofintinff1 cofintinff2 cofintinff3 cofintinff4...
                cofintout cofintoutb1 cofintoutb2 cofintoutb3 cofintoutb4 cofintoutf1 cofintoutf2 cofintoutf3 cofintoutf4...
                cofintoutp cofintoutpb1 cofintoutpb2 cofintoutpb3 cofintoutpb4 cofintoutpf1 cofintoutpf2 cofintoutpf3 cofintoutpf4...
                std_r_ std_r_quart ;
            cd('..');
            cd MMB_OPTIONS
            % disp(' ')
            % disp('Selected Policy Rule:');
            % disp(deblank(modelbase.rulenames(modelbase.rule,:)));
            
            %**********************************************************************************************************************
            %                    Solving the Model, Computing Statistics                                                          %
            %**********************************************************************************************************************
            save Modelbase modelbase                                % neccessary to save in between as dynare clears the workspace
            epsilon=1;
            %tic
            modelbase.modeltime(modelbase.models(epsilon)) = cputime;
            modelbase.setpath(modelbase.models(epsilon),:) = [modelbase.uphomepath num2str('\MODELS\') num2str(modelbase.names(modelbase.models(epsilon),:))]; % path for dynare file of specific model
            modelbase.epsilon = epsilon;
            al=deblank(modelbase.names(modelbase.models(epsilon),:));
            modelbase.AL=strcmp(al(end-1:end),'AL');
            
            if modelbase.AL
                if modelbase.l==min(find(modelbase.rule>0)) % If the model is solved for the first rule chosen
                    control=0;
                    while control==0
                        gain=str2num(selectgain(modelbase.names,modelbase.models,epsilon));
                        if gain>=0 && gain<=0.05
                            control=1;
                        end
                    end
                    modelbase.control=control;
                    modelbase.gain=gain;
                    modelbase.ModelGAIN(modelbase.models(epsilon))=modelbase.gain;
                end
            end
            
            save -append Modelbase modelbase
            cd(modelbase.setpath(modelbase.models(epsilon),:));                                 % go to directory of specific model
            disp(' ');
            disp(['Currently Solving: ', num2str(deblank(modelbase.names((modelbase.models(epsilon)),:)))]);
            eval(['dynare '  modelbase.names(modelbase.models(epsilon),:)]);% solve model "epsilon" in dynare by running the .mod file --> translates Dynare syntax into .m file, that is run
            %eval(['dynare '  modelbase.names(modelbase.models(epsilon),:) ' noclearall']);
            cd('..');
            cd('..'); % insert one more cd('..');
            cd MMB_OPTIONS
            load Modelbase
            options_.ar=100;
            if modelbase.AL
                if modelbase.l==min(find(modelbase.rule>0)) % If the model is solved for the first rule chosen
                    thepath=cd;
                    cd(modelbase.setpath(modelbase.models(epsilon),:))
                    load AL_Info
                    cd(thepath);
                    AL_.forwards = AL_Info.forwards;
                    if ismember(modelbase.rule,[6 7])
                        AL_.states = AL_Info.states_short;
                    else
                        AL_.states = AL_Info.states_long;
                    end
                    %menu for selection of states for learning
                    control_sel_states=0;
                    while control_sel_states==0
                        rb_temp=menu_AL_select_states;
                        if sum(rb_temp)==1
                            control_sel_states=1;
                        end
                    end
                    if rb_temp(2)==1
                        while control_sel_states==1
                            rb2_temp=menu_AL_select_subset(AL_.states);
                            if size(rb2_temp,2)~=0
                                control_sel_states=2;
                                AL_.states=rb2_temp;
                            end
                        end
                    end
                    modelbase.AL_=AL_;
                    modelbase.ModelStates(modelbase.models(epsilon))={modelbase.AL_.states};
                end
            end
            
            save -append Modelbase modelbase
            modelbase=stoch_simul_MMB(modelbase);                                     % solve model
            cd(modelbase.homepath);                                                   % go back to main directory
            %toc
            modelbase.modeltime(modelbase.models(modelbase.epsilon))=cputime-modelbase.modeltime(modelbase.models(modelbase.epsilon));
            disp(['Elapsed cputime is ' ,num2str(modelbase.modeltime(modelbase.models(modelbase.epsilon))), ' seconds.']);
            
            %**********************************************************************************************************************
            %                    Display Variances on screen                                                                    %
            %**********************************************************************************************************************
            
        end
    end
    statusbar(0, 'Busy...');
    if modelbase.option(5) == 1
        
        disp(' ')
        disp('Variance of the model variables you have chosen:')
        disp(' ')
        for i=1:size(modelbase.rulenames,1)
            if (modelbase.rule(i)>0) % If the i-th rule has been chosen
                modelbase.l=i;
                j=modelbase.models;
                if modelbase.info(modelbase.l)==0
                    disp(' ')
                    disp([num2str(deblank(modelbase.names(modelbase.models,:))) ': ' num2str(modelbase.rulenamesshort1(modelbase.l,:))]);
                    disp(' ')
                    disp('Variables           Variance       ')
                    %Plotting the variance of interest rate
                    vname='Interest ';
                    var = modelbase.VAR.(num2str(deblank(modelbase.rulenamesshort1(modelbase.l,:))))(loc(modelbase.VARendo_names.(num2str(deblank(modelbase.rulenamesshort1(modelbase.l,:)))),'interest'),loc(modelbase.VARendo_names.(num2str(deblank(modelbase.rulenamesshort1(modelbase.l,:)))),'interest'));
                    st = sprintf('%9s %19f',...
                        vname,var);
                    disp(st)
                    %Plotting the variance of inflation
                    vname='Inflation';
                    var = modelbase.VAR.(num2str(deblank(modelbase.rulenamesshort1(modelbase.l,:))))(loc(modelbase.VARendo_names.(num2str(deblank(modelbase.rulenamesshort1(modelbase.l,:)))),'inflation'),loc(modelbase.VARendo_names.(num2str(deblank(modelbase.rulenamesshort1(modelbase.l,:)))),'inflation'));
                    st = sprintf('%9s %19f',...
                        vname,var);
                    disp(st)
                    %Plotting the variance of outputgap
                    vname='outputgap';
                    var = modelbase.VAR.(num2str(deblank(modelbase.rulenamesshort1(modelbase.l,:))))(loc(modelbase.VARendo_names.(num2str(deblank(modelbase.rulenamesshort1(modelbase.l,:)))),'outputgap'),loc(modelbase.VARendo_names.(num2str(deblank(modelbase.rulenamesshort1(modelbase.l,:)))),'outputgap'));
                    st = sprintf('%9s %19f',...
                        vname,var);
                    disp(st)
                    if loc(modelbase.VARendo_names.(num2str(deblank(modelbase.rulenamesshort1(modelbase.l,:)))),'output')~=0
                        %Plotting the variance of output
                        vname='output   ';
                        var = modelbase.VAR.(num2str(deblank(modelbase.rulenamesshort1(modelbase.l,:))))(loc(modelbase.VARendo_names.(num2str(deblank(modelbase.rulenamesshort1(modelbase.l,:)))),'output'),loc(modelbase.VARendo_names.(num2str(deblank(modelbase.rulenamesshort1(modelbase.l,:)))),'output'));
                        st = sprintf('%9s %19f',...
                            vname,var);
                        disp(st)
                    end;
                end;
            end;
        end
    end
    %**********************************************************************************************************************
    %                    Set up figures, plot results                                                                     %
    %**********************************************************************************************************************
    keyvariables = ['outputgap'; 'inflation'; 'interest '; 'output   '];
    titlekeyvariables={'Output Gap';'Inflation';'Interest Rate';'Output'};
    if modelbase.option(2)==1
        for i=1:size(modelbase.rulenames,1)
            if (modelbase.rule(i)>0) % If the i-th rule has been chosen
                modelbase.l=i;
                if ~modelbase.info(modelbase.l)
                    modelbase.rulelegend=[modelbase.rulelegend; modelbase.rulenamesshort(modelbase.l,:)];
                    modelbase.str = cellstr(modelbase.rulelegend);
                    time = (0:modelbase.horizon)';
                    %remove auxiliary endo variables
                    if (i== min(find(modelbase.info==0)))
                        All_Endo_Var           = modelbase.IRFendo_names.(num2str(deblank(modelbase.rulenamesshort1(modelbase.l,:))));
                        All_Endo_IRF           = modelbase.IRF.(num2str(deblank(modelbase.rulenamesshort1(modelbase.l,:))));
                        Index_Non_Aux_Var      = find(cellfun(@isempty,strfind(cellstr(All_Endo_Var),'AUX_ENDO'))==1);
                        IRFendo_names_Non_Aux  = All_Endo_Var(Index_Non_Aux_Var,:);
                        IRFendo_names_Non_Aux_0= IRFendo_names_Non_Aux;
                        number=size(Index_Non_Aux_Var,1);
                    end
                    IRF_Non_Aux_Var       = modelbase.IRF.(num2str(deblank(modelbase.rulenamesshort1(modelbase.l,:))))(Index_Non_Aux_Var,:,:);
                    
                    if modelbase.option(3)==1
                        modelbase.namesshocks(1,:)='Combined shocks      ';
                        modelbase=rmfield(modelbase,'innos');
                        modelbase.innos(1,:)='Combined_Shocks';
                    end
                    
                    for p=1:size(modelbase.innos,1)
                        if modelbase.option(4)==1
                            try
                                figure(modelbase.figHandle{p,1});
                                set(modelbase.figHandle{p,1}, 'visible', 'off')
                            catch
                                modelbase.figHandle{p,1}=figure;
                                warning off
                                orient landscape
                                set(modelbase.figHandle{p,1}, 'visible', 'off')
                            end
                            To_be_plotted=Index_Non_Aux_Var;
                            IRF_Non_Aux_Var=modelbase.IRF.(num2str(deblank(modelbase.rulenamesshort1(modelbase.l,:))))(To_be_plotted,:,:);
                            IRFendo_names_Non_Aux = All_Endo_Var(To_be_plotted,:);
                            for pp=1:4
                                if loc(IRFendo_names_Non_Aux,keyvariables(pp,:))~=0
                                    subplot(2,2,pp)
                                    plot(time,IRF_Non_Aux_Var(loc(IRFendo_names_Non_Aux,keyvariables(pp,:)),:,p),modelbase.myrulecolor(modelbase.l,:),'LineWidth',2,'MarkerSize',5); hold on
                                    grid on
                                    title(titlekeyvariables(pp,:),'FontUnits','normalized')
                                    if pp==1
                                        if p==2
                                            legend(modelbase.str);
                                        else
                                            legend(modelbase.str, 'location','SouthEast');
                                        end
                                    end
                                end
                            end
                        else
                            [IRF_Non_Aux_Var,IRFendo_names_Non_Aux]=Get_IRF_VAR(p,modelbase.l,i, modelbase.rulenames,modelbase.rule,modelbase.info,modelbase.rulenamesshort1,modelbase.IRF,Index_Non_Aux_Var,All_Endo_Var,10^(-5));
                            number(p)=size(IRFendo_names_Non_Aux,1);
                            rest=number(p)-floor(number(p)/9)*9;
                            for q=1:floor(number(p)/9)+(rest~=0)
                                n_var=9*(floor(number(p)/9)>=q)*(q>0)+rest*(floor(number(p)/9)<q);
                                try
                                    figure(modelbase.figHandle{p,q});
                                    set(modelbase.figHandle{p,q}, 'visible', 'off');
                                catch
                                    modelbase.figHandle{p,q}=figure('name',modelbase.innos(p,:));
                                    set(modelbase.figHandle{p,q}, 'visible', 'off');
                                    warning off
                                    orient landscape
                                end
                                for r=1:n_var
                                    subplot(3,3,r)
                                    plot(modelbase.time,IRF_Non_Aux_Var((q-1)*9+r,:,p),modelbase.myrulecolor(modelbase.l,:),'LineWidth',2,'MarkerSize',5); hold on
                                    if r==1
                                        legend(modelbase.str);
                                    end
                                    grid on
                                    title(num2str(deblank(IRFendo_names_Non_Aux((q-1)*9+r,:))),'FontUnits','normalized')
                                end;
                            end;
                        end;
                    end;
                end;
            end
        end
    end
    
    
    % save the results
    for p=1:size(modelbase.innos,1)
        if ~isempty(find(modelbase.info == 0))
            modelbase.rulerank=0;
            if modelbase.option(3)==1
                jj=(p==1);
                p=1;
                modelbase.namesshocks(p,:)='Combined shocks      ';
            end
            n=max(size(find(modelbase.info==0)))+2;
            for i=1:size(modelbase.rulenames,1)
                if (modelbase.rule(i)>0) % If the i-th rule has been chosen
                    modelbase.l=i;
                    modelbase.rulerank=modelbase.rulerank+(~modelbase.info(modelbase.l));
                    if modelbase.info(modelbase.l) == 0
                        for k = 1:size(keyvariables,1);
                            if (i==min(find(modelbase.info==0)))
                                result.IRF.(num2str(deblank(modelbase.innos(p,:))))((k-1)*n+1,:) = [{keyvariables(k,:)},num2cell(NaN(1,(modelbase.horizon+1)))];
                            end
                            [IRF_Non_Aux_Var,IRFendo_names_Non_Aux]=Get_IRF_VAR(p,modelbase.l,i, modelbase.rulenames,modelbase.rule,modelbase.info,...
                                modelbase.rulenamesshort1,modelbase.IRF,Index_Non_Aux_Var,All_Endo_Var,10^(-5));
                            if  (loc(IRFendo_names_Non_Aux,keyvariables(k,:))~=0)
                                result.IRF.(num2str(deblank(modelbase.innos(p,:))))((k-1)*n+1+modelbase.rulerank,1:(modelbase.horizon+2))=...
                                    [{num2str(deblank(modelbase.rulenamesshort(modelbase.l,:)))},num2cell(IRF_Non_Aux_Var(loc(IRFendo_names_Non_Aux,keyvariables(k,:)),1:(modelbase.horizon+1),p))];
                            else
                                result.IRF.(num2str(deblank(modelbase.innos(p,:))))((k-1)*n+1+modelbase.rulerank,2:modelbase.horizon+2) = {[]};
                            end
                        end
                    end
                    if (i==min(find(modelbase.info==0)))
                        try
                            ListStates=modelbase.ModelStates(modelbase.models(j));
                            result.AL = [{num2str(deblank(modelbase.names(modelbase.models(j),:)))},...
                                {'Gain'},{num2str(modelbase.ModelGAIN(modelbase.models(j)))},...
                                {'States'}, ListStates{:}];
                            xlswrite(modelbase.savepath, result.AL, 'AL','A1');
                        catch
                        end
                    end
                end
            end
            if (modelbase.option(3)==1)&&(jj==1)
                xlswrite(modelbase.savepath, result.IRF.(num2str(deblank(modelbase.innos(p,:)))), ['IRF ' modelbase.namesshocks(p,:)]);
            elseif (modelbase.option(3)~=1)
                xlswrite(modelbase.savepath, result.IRF.(num2str(deblank(modelbase.innos(p,:)))), ['IRF ' modelbase.namesshocks(p,:)]);
            end
        end
    end
    modelbase.rulerank=0;
    
    if modelbase.option(1) ==1
        if ~isempty(find(modelbase.info == 0))
            for i=1:size(modelbase.rulenames,1)
                n=max(size(find(modelbase.info==0)))+2;
                if (modelbase.rule(i)>0) % If the i-th rule has been chosen
                    modelbase.l=i;
                    modelbase.rulerank=modelbase.rulerank+(~modelbase.info(modelbase.l));
                    for k = 1:size(keyvariables,1);
                        if (modelbase.info(modelbase.l) == 0)
                            if (i==min(find(modelbase.info==0)))
                                result.AC((k-1)*n+1,:) = [{keyvariables(k,:)},num2cell(NaN(1,(modelbase.horizon+1)))];
                            end
                            if loc(modelbase.AUTendo_names.(num2str(deblank(modelbase.rulenamesshort1(modelbase.l,:)))),keyvariables(k,:))~=0
                                result.AC((k-1)*n+1+modelbase.rulerank,1:(modelbase.horizon+2)) =[{num2str(deblank(modelbase.rulenamesshort(modelbase.l,:)))},...
                                    num2cell(modelbase.AUTR.(num2str(deblank(modelbase.rulenamesshort1(modelbase.l,:))))...
                                    (loc(modelbase.AUTendo_names.(num2str(deblank(modelbase.rulenamesshort1(modelbase.l,:)))),keyvariables(k,:)),1:(modelbase.horizon+1)))];
                            end
                        end
                    end
                    if (i==min(find(modelbase.rule>0)))
                        try
                            ListStates=modelbase.ModelStates(modelbase.models(j));
                            result.AL = [{num2str(deblank(modelbase.names(modelbase.models(j),:)))},...
                                {'Gain'},{num2str(modelbase.ModelGAIN(modelbase.models(j)))},...
                                {'States'}, ListStates{:}];
                            xlswrite(modelbase.savepath, result.AL, 'AL','A1');
                        catch
                        end
                    end
                end
            end
            xlswrite(modelbase.savepath, result.AC, 'ACF');
        end
    end
    %Saving the IRFs of all variables in Excel
    
    for p=1:size(modelbase.innos,1)
        if ~isempty(find(modelbase.info == 0))
            modelbase.rulerank=0;
            m=max(size(find(modelbase.info==0)))+2;
            for i=1:size(modelbase.rulenames,1)
                if (modelbase.rule(i)>0) % If the i-th rule has been chosen
                    modelbase.l=i;
                    if modelbase.info(modelbase.l)==0
                        modelbase.rulerank=modelbase.rulerank+1;
                        [IRF_Non_Aux_Var,IRFendo_names_Non_Aux]=Get_IRF_VAR(p,modelbase.l,i, modelbase.rulenames,modelbase.rule,modelbase.info,modelbase.rulenamesshort1,modelbase.IRF,Index_Non_Aux_Var,All_Endo_Var,10^(-5));
                        if ~isempty(IRFendo_names_Non_Aux)
                            for v=1:size(IRFendo_names_Non_Aux,1)
                                if (i==min(find(modelbase.info==0)))
                                    result.allIRFs.(num2str(deblank(modelbase.innos(p,:))))((v-1)*m+1,1:(modelbase.horizon+2)) = [{IRFendo_names_Non_Aux(v,:)},num2cell(NaN(1,(modelbase.horizon+1)))];
                                end
                                result.allIRFs.(num2str(deblank(modelbase.innos(p,:))))((v-1)*m+modelbase.rulerank+1,1:(modelbase.horizon+2)) =...
                                    [{num2str(deblank(modelbase.rulenamesshort(modelbase.l,:)))}, num2cell(IRF_Non_Aux_Var(v,1:(modelbase.horizon+1),p))];
                            end;
                        end;
                    end;
                end;
            end;
            xlswrite(modelbase.savepath, result.allIRFs.(num2str(deblank(modelbase.innos(p,:)))), ['all IRFs ' num2str(deblank(modelbase.namesshocks(p,:)))]);
        end;
    end;
    try
        j=1;
        ListStates=modelbase.ModelStates(modelbase.models(j));
        result.AL = [{num2str(deblank(modelbase.names(modelbase.models(j),:)))},...
            {'Gain'},{num2str(modelbase.ModelGAIN(modelbase.models(j)))},...
            {'States'}, ListStates{:}];
        xlswrite(modelbase.savepath, result.AL, 'AL','A1');
    catch
    end
    
    if ~isempty(find(modelbase.info==0))
        model_name=num2str(deblank(modelbase.namesplot(modelbase.modelplottedIRF,:)));
        if modelbase.option(2)==1
            for p=1:size(modelbase.innos,1)
                if modelbase.option(4)==1
                    figure(modelbase.figHandle{p,1});
                    if  p==1
                        if modelbase.option(3)==0
                            set_figures(modelbase.figHandle{p,1},4,1,[model_name,': IRF to Mon. Pol. Shock']);
                        else
                            set_figures(modelbase.figHandle{p,1},4,1,[model_name,': IRF to selected shocks (contemporenously)']);
                        end
                    else
                        set_figures(modelbase.figHandle{p,1},4,1,[model_name,': IRF to ', num2str(deblank(modelbase.namesshocks(p,:)))]);
                        
                    end;
                elseif modelbase.option(4)==0
                    rest=number(p)-floor(number(p)/9)*9;q1=(floor(number(p)/9)>0);
                    for q=1:floor(number(p)/9)+(rest~=0)
                        n_var=9*(floor(number(p)/9)>=q)*(q>0)+rest*(floor(number(p)/9)<q);
                        figure(modelbase.figHandle{p,q});
                        if modelbase.option(3)==1
                            set_figures(modelbase.figHandle{p,q},n_var,2,[model_name,': IRF to selected shocks (contemporenously)']);
                        else
                            set_figures(modelbase.figHandle{p,q},n_var,2,[model_name,': IRF  to ',num2str(deblank(modelbase.namesshocks(p,:)))]);
                        end
                    end;
                end;
            end;
        end;
        %%
        
        
        warning off
        if modelbase.option(1)==1
            % plot autocorrelation function
            time = (0:modelbase.horizon)';
            for i=1:size(modelbase.rulenames,1)
                if (modelbase.rule(i)>0) % If the i-th rule has been chosen
                    modelbase.l=i;
                    if (i== min(find(modelbase.info==0)))
                        modelbase.figHandleACF=figure;
                        set(modelbase.figHandleACF, 'visible', 'off');
                        warning off
                        orient landscape
                    end
                    if modelbase.info(modelbase.l)==0
                        modelbase.rulelegend=[modelbase.rulelegend; modelbase.rulenamesshort(modelbase.l,:)];
                        modelbase.str = cellstr(modelbase.rulelegend);
                        figure(modelbase.figHandleACF);
                        set(modelbase.figHandleACF, 'visible', 'off');
                        for pp=1:4
                            if loc(modelbase.AUTendo_names.(num2str(deblank(modelbase.rulenamesshort1(modelbase.l,:)))),keyvariables(pp,:))~=0
                                subplot(2,2,pp)
                                plot(time,modelbase.AUTR.(num2str(deblank(modelbase.rulenamesshort1(modelbase.l,:))))(loc(modelbase.AUTendo_names.(num2str(deblank(modelbase.rulenamesshort1(modelbase.l,:)))),keyvariables(pp,:)),:), modelbase.myrulecolor(modelbase.l,:),'LineWidth',2,'MarkerSize',5); hold on
                                grid on
                                title(titlekeyvariables(pp,:),'FontUnits','normalized')
                                if pp==1
                                    legend(modelbase.str);
                                end
                            end
                        end
                        
                    end
                end
            end
            set_figures(modelbase.figHandleACF,4,1,[model_name,': Autocorrelation Functions']);
        end
    end
    try
        modelbase=rmfield(modelbase,'figHandle');
        modelbase=rmfield(modelbase,'figHandleACF');
    catch
    end
    save -append Modelbase modelbase
    modelbase.totaltime = cputime-modelbase.totaltime;
    disp(' '); disp(' ');
    disp(['Total elapsed cputime: ' ,num2str(modelbase.totaltime), ' seconds.']);
    statusbar(0, '');
    rmpath(modelbase.homepath);
end