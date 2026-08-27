clc; close all; clear all;
open_file='C:\b\rscop_apml\step_txt\';
% open_file='C:\c\';
% open_box='C:\b\rscop_box_pressure\txt_step\';
open_box='C:\c\';
open_level='C:\c\';
save_file ='C:\c\';

level_1=90;  level_2=70;  level_3=69;level_4=68;

% %===========================
% %===========================
% no_man1=[0:9];
% no_man2=[10:17,19:46,50:78];
% no_man3=[0:9];
% no_man4=[10:17,19:46,50:78];
% %===========================
% t00_1='_t00'; t00_2='_t0';
% LR='L';
% for i=1:length(no_man1)
%     no_group1(i,:)=[  LR ,t00_1, num2str(no_man1(i))   ] ;
% end
% for i=1:length(no_man2)
%     no_group2(i,:)=[  LR, t00_2, num2str(no_man2(i))   ] ;
% end
% % ++++++++++++++++++++++++++++++++++
% LR='R';
% for i=1:length(no_man3)
%     no_group3(i,:)=[ LR, t00_1, num2str(no_man3(i))   ] ;
% end
% for i=1:length(no_man4)
%     no_group4(i,:)=[ LR , t00_2, num2str(no_man4(i))   ] ;
% end
% %===========================
% no_man=[
%     no_group1;
%     no_group2;
%     no_group3;
%     no_group4
%     ];
no_man=[
'R_t063'
    ];

for i=1:length(no_man(:,1))
    for j=1:5
        no_man_step(i*5-5+j,:)=[   [num2str(no_man(i,:))] , '_', [num2str(j)]   ];
    end
end
%===========================
%===========================
%===========================
%===========================
% no_man_step=[
%     'R_t055_3'
%     ] ;

% for w=1:length(no_man_step(:,1))
for w= 1
        % w=1;
    close all
    clear i   j   k   map_raw   length_Fn_cm...
        length_Fp_ch  length_Fn_a  length_Fn_b  cop_roll
    clc
    w
    num2str(no_man_step(w,:))
    %===========================
%     map_raw          =load([  [num2str(open_file)], 'map_raw_',        [num2str(no_man_step(w,:))],'.txt']);
    map_level_max=load([  num2str(open_level), 'map_level_max_', num2str(no_man_step(w,:)),'.txt']);
    xy_cop_i100     =load([ num2str(open_file), 'xy_cop_i100_3_' ,    num2str(no_man_step(w,:)),'.txt']);
    xy_box             =load([ num2str(open_box), 'xy_box12_' ,           num2str(no_man_step(w,:)),'.txt']);
    level_raw         =load([ num2str(open_level), 'map_level_' ,          num2str(no_man_step(w,:)),'.mat']);
    matrix_level=level_raw.map_level;
    
    %===============================
    %==                                                       ==
    %==           Pressure Map                      ==
    %==                                                       ==
    %===============================
    %==  plot =presure value is square and multiply 10  ===
    %==  that will enhance the readability   ===
    subplot(1,2,1);
%     map=sqrt(map_raw).*10;
%    surf(map_raw);hold on;
    surf(map_level_max);hold on;
    x_copi=xy_cop_i100(:,1);
    y_copi=xy_cop_i100(:,2);
    cop_zi=x_copi(:,1).*0+level_1;
    plot3(x_copi, y_copi,cop_zi,'w','linewidth',3 );hold on;
    plot3(x_copi, y_copi,cop_zi,'r.-','linewidth',1 );hold on;
    view(0,90);grid on;  axis equal;hold on;
    %///////////////////////////////////////////////////////////////
    %///////////////////////////////////////////////////////////////
    %///////////////////////////////////////////////////////////////
    %///////////////////////////////////////////////////////////////
    %///////////////////////////////////////////////////////////////
    %///////////////////////////////////////////////////////////////
    %=================================
    %==                                                         ==
    %==            Box define                            ==
    %==        heel point & toe-point               ==
    %==                                                         ==
    %=================================
    %     ratio_c=[35,15,15];
    %     ratio_cc=[ratio_c(1),ratio_c(1)+ratio_c(2),ratio_c(1)+ratio_c(2)+ratio_c(3)];
    ratio_c=[30,20,20];
    ratio_cc=[ratio_c(1),ratio_c(1)+ratio_c(2),ratio_c(1)+ratio_c(2)+ratio_c(3)];
    % ratio_c=[30,25];
    % ratio_cc=[ratio_c(1),ratio_c(1)+ratio_c(2)];
    %=================================
    box_color=[
        0.6       0.6        1         %1      toe1
        0       0.7     0         % 2     toe2
        1       0.5     0         % 3==  toe3
        1       1      0      % 4==  toe4-5
        1       0        0         % 5     MT1
        1       0        1         % 6     MT2
        0.5    0.5     0.5      % 7     MT3
        0       0.9     0.9      % 8      MT4-5
        0.5    0        0         %  9== mid_M
        0       1        0         % 10   mid_L
        0.7    0        0.7      % 11    heel_M
        0       0        0.9   ]; % 12   heel_L
    %    plot([x(i),x(i)] ,[y1(i),y2(i)],'color',box_color(i,:),'linewidth',10);hold on;

    x_text=-13;
    y_text=35;
    y_space=-3;
    text_list=[
        ' 1:Toe 1   ';
        ' 2:Toe 2   ';
        ' 3:Toe 3   ';
        ' 4:Toe 4-5 ';
        ' 5:MT 1    ';
        ' 6:MT 2    ';
        ' 7:MT 3    ';
        ' 8:MT 4-5  ';
        ' 9:Mid med ';
        '10:Mid lat ';
        '11:Heel med';
        '12:Heel lat'];
    box=xy_box;
    box_level_1=[box(1,1:2:8), box(1,1)]*0+level_1;
    for i=1:length(box(:,1))
        text(x_text, y_text+i*y_space, text_list(i,:),'BackgroundColor',box_color(i,:),'fontsize',8);
        plot3([box(i,1:2:8), box(i,1)],  [box(i,2:2:8), box(i,2)], box_level_1,   'c-','linewidth',2);hold on;
        plot3([box(i,1:2:8), box(i,1)],  [box(i,2:2:8), box(i,2)], box_level_1,   'k-','linewidth',1);hold on;
    end


    %================================
    %================================
    %==            Box check A B C D              ==
    %==         (repeat need pick point)          ==
    %==                 clockwise                        ==
    %==    left up    :A        right up    :B       ==
    %==    left down:D       right down:C       ==
    %================================

    abcd_list=['a','b','c','d'];
    for i=1:length(box(:,1))
        text( (box(i,1)+box(i,3))/2+1, (box(i,4)+box(i,6))/2, level_1,text_list(i,1:2),'BackgroundColor',[0,0,0], 'fontsize',13,'HorizontalAlignment','center');
        text( (box(i,1)+box(i,3))/2+1, (box(i,4)+box(i,6))/2, level_1,text_list(i,1:2),'BackgroundColor',box_color(i,:), 'fontsize',11,'HorizontalAlignment','center');
        text( (box(i,1)+box(i,3))/2+1, (box(i,4)+box(i,6))/2, level_1,text_list(i,1:2),'BackgroundColor',[1,1,1], 'fontsize',7, 'HorizontalAlignment','center');
        %             for j=1:4
        %                 text(box(i,j*2-1),box(i,j*2), level_1, abcd_list(j),'BackgroundColor',...
        %                     [0+(0.1*i), 0.5+(0.05*i), 1-(0.1*i)], 'fontsize',12);
        %             end
        %             [x_i, y_i]=ginput(1);
    end
    %///////////////////////////////////////////////////////////////
    %///////////////////////////////////////////////////////////////
    %///////////////////////////////////////////////////////////////
    %///////////////////////////////////////////////////////////////
    %///////////////////////////////////////////////////////////////
    %///////////////////////////////////////////////////////////////
    %================================
    %==                                                       ==
    %==           Box pressure                       ==
    %==                                                       ==
    %================================
    
    clear value_inbox1 value_inbox2 value_inbox3 value_inbox4 value_inbox5...
        value_inbox6     value_inbox7 value_inbox8 value_inbox9 value_inbox10...
        value_inbox11 value_inbox12 

    
    matrix_level=matrix_level;
    [matrix_i,matrix_j]=size(matrix_level(:,:,1));
    for i=1:matrix_i
        for j=1:matrix_j
            matrix_list(i*matrix_j-matrix_j+j,:)=[j,i];
        end
    end

    box=xy_box;
    abcd_list=['a','b','c','d'];
    %///////////////////////////////////////////////////////////////
    %///////////////////////////////////////////////////////////////
    %///////////////////////////////////////////////////////////////
    %///////////////////////////////////////////////////////////////
    %///////////////////////////////////////////////////////////////
    %///////////////////////////////////////////////////////////////
    %================================
    %==                                                       ==
    %==           Box pressure  Loop             ==
    %==                                                       ==
    %================================
    for e= 1:length(matrix_level(1,1,:))
        matrix_one=matrix_level(:,:,e);
        %     subplot(2,3,e)
        for i=1:length(box(:,1))
            a=box(i,1:2);b=box(i,3:4); c=box(i,5:6);d=box(i,7:8);
            %         plot([box(i,1:2:8), box(i,1)],  [box(i,2:2:8), box(i,2)],   'b^-');hold on;
            %         text ( a(1),a(2)-0.25 ,  ['Frame ',num2str(i)], 'fontsize',8,'BackgroundColor',[.7 .9 .7] ); hold on;
            %         for j=1:4
            %             text(box(i,j*2-1),box(i,j*2), abcd_list(j),'BackgroundColor',...
            %                 [0+(0.05*i), 0.5+(0.05*i), 1-(0.05*i)], 'fontsize',12);
            %         end
            %      //////////////////////////////////////////////////////////////////
            % #############################
            % #############################
            %===============================
            [aaaa,abcd_in]=func_abcd_in(matrix_one,matrix_list, a,b,c,d);
             %===============================
            % #############################
            % #############################
            if i==1
                value_inbox1(e,:)=abcd_in;
            elseif i==2
                value_inbox2(e,:)=abcd_in;
            elseif i==3
                value_inbox3(e,:)=abcd_in;
            elseif i==4
                value_inbox4(e,:)=abcd_in;
            elseif i==5
                value_inbox5(e,:)=abcd_in;
            elseif i==6
                value_inbox6(e,:)=abcd_in;
            elseif i==7
                value_inbox7(e,:)=abcd_in;
            elseif i==8
                value_inbox8(e,:)=abcd_in;
            elseif i==9
                value_inbox9(e,:)=abcd_in;
            elseif i==10
                value_inbox10(e,:)=abcd_in;
            elseif i==11
                value_inbox11(e,:)=abcd_in;
            elseif i==12
                value_inbox12(e,:)=abcd_in;
            end
            %===================
            if e==1
                if i==1
                    xy_inbox1=aaaa;
                elseif i==2
                    xy_inbox2=aaaa;
                elseif i==3
                    xy_inbox3=aaaa;
                elseif i==4
                    xy_inbox4=aaaa;
                elseif i==5
                    xy_inbox5=aaaa;
                elseif i==6
                    xy_inbox6=aaaa;
                elseif i==7
                    xy_inbox7=aaaa;
                elseif i==8
                    xy_inbox8=aaaa;
                elseif i==9
                    xy_inbox9=aaaa;
                elseif i==10
                    xy_inbox10=aaaa;
                elseif i==11
                    xy_inbox11=aaaa;
                elseif i==12
                    xy_inbox12=aaaa;
                end
                %             plot(aaaa(:,1),aaaa(:,2) ,'mv', 'linewidth',1);hold on;
            end
            %===================
            clear abcd_in aaaa
        end
    end
    %///////////////////////////////////////////////////////////////
    %///////////////////////////////////////////////////////////////
    %///////////////////////////////////////////////////////////////
    %///////////////////////////////////////////////////////////////
    %///////////////////////////////////////////////////////////////
    %///////////////////////////////////////////////////////////////
    %
    % subplot(1,2,1)
    % plot(xy_inbox9(:,1),xy_in_box11(:,2) ,'rv', 'linewidth',1);hold on;
    % plot(xy_inbox2(:,1),xy_in_box12(:,2) ,'gv', 'linewidth',1);hold on;
    % plot(xy_inbox3(:,1),xy_in_box5(:,2) ,'bv', 'linewidth',1);hold on;
    %================================
    %==                                                       ==
    %==            Plot                                    ==
    %==                                                       ==
    %================================
    clear data_f unit_no data_p data_matrix data_f_sum
    subplot(3,2,2)
    for i=1:length(box(:,1))
        data_f(:,i)=eval ( ['sum(value_inbox',num2str(i),  ',2)' ]  );
        plot(data_f(:,i),'color',box_color(i,:),'linewidth',2); hold on
    end
    data_f_sum=sum(data_f,2);

    % title('total peak presure');axis([0 340 0 40]);grid on;
    xlabel('frame');
    ylabel('force (N) ');


    subplot(3,2,4)
    clear unit_no
    for i=1:length(box(:,1))
        unit_no(i)=eval( [ 'length(xy_inbox' , num2str(i),  '(:,1))' ]);
        data_p(:,i)=eval ( ['sum(value_inbox',num2str(i),  ',2)/ (unit_no(i)*0.53*0.75)'   ]  );
        plot(data_p(:,i),'color',box_color(i,:),'linewidth',2); hold on
    end

    % title('total peak presure');axis([0 340 0 40]);grid on;
    ylabel('pressure (N/cm^2) ');

    subplot(3,2,6)
    data_matrix_i=sum(sum(matrix_level));
    for i=1:length(matrix_level(1,1,:))
        data_matrix(i,:)=data_matrix_i(1,1,i);
    end
    plot(data_matrix, 'c-', 'linewidth',3);hold on;
    plot(data_f_sum, 'b-', 'linewidth',1);hold on;

    % title('total peak presure');axis([0 340 0 40]);grid on;
    xlabel('frame');
    ylabel('force (N) ');

    %================================
    %==                                                       ==
    %==      save as 101                              ==
    %==                                                       ==
    %================================
    data_all=[data_f,data_p,data_matrix, data_f_sum];
    xi_divide=100;
    x=(0:(100/(length(data_matrix)-1)):100)';
    y=data_all;
    xi=0:(100/xi_divide):100;
    yi=interp1(x,y,xi,'linear');
    data_101_f12_p12_matrix1_fsum1=yi;
    %================================
    %================================
    for i=1:length(box(:,1))
        save([save_file,'box12_xy_inbox', num2str(i),'_',num2str(no_man_step(w,:)),'.txt'],      ['xy_inbox',num2str(i)]  ,'-ascii')
        save([save_file,'box12_value_inbox', num2str(i),'_',num2str(no_man_step(w,:)),'.txt'],  ['value_inbox',num2str(i)]  ,'-ascii')
    end

    save([save_file,'box12_data_f_',                                          num2str(no_man_step(w,:)),'.txt'],  'data_f'                                             ,'-ascii')
    save([save_file,'box12_data_p_',                                          num2str(no_man_step(w,:)),'.txt'],  'data_p'                                           ,'-ascii')
    save([save_file,'box12_data_matrix_',                                  num2str(no_man_step(w,:)),'.txt'],  'data_matrix'                                    ,'-ascii')
    save([save_file,'box12_data_f_sum_',                                  num2str(no_man_step(w,:)),'.txt'],  'data_f_sum'                                    ,'-ascii')
    save([save_file,'box12_data_101_f12_p12_m1_s1_',num2str(no_man_step(w,:)),'.txt'],  'data_101_f12_p12_matrix1_fsum1'  ,'-ascii')

    subplot(1,2,1);
    title([num2str(no_man_step(w,:)), '  [',num2str(w), ']   region value'] );
    currFig1 = get(0,'CurrentFigure');
    saveas (currFig1,[save_file,   'box_value_',              num2str(no_man_step(w,:)) ],'jpg' )
end

