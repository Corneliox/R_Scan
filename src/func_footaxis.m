function [x_vc_ae,y_vc_ae,x_vc_be,y_vc_be]=func_footaxis (pick_data)
plot([5,55,55,5,5], [390,390,440,440,390],'y-', 'linewidth',3)
text(10,400,'high','FontSize', 12, 'color', [1,1,0] );

for e=1:2
    xy_pick_data=[pick_data(e*8-7:e*8,1),pick_data(e*8-7:e*8,2)];
    % %++++++++++++++++++++++++++++
    % %+++   load   left foot  1    2               ++
    % %+++                           3    4              ++
    % %++++++++++++++++++++++++++++++
    x_pick=xy_pick_data(1:4,1);
    y_pick=xy_pick_data(1:4,2);
    for i=1:4
        plot( x_pick(i,:), y_pick(i,:),'rx', 'linewidth',1);hold on;
    end
    % %++++++++++++++++++++++++++++
    % %+++   Pick   left foot  1    2            ++
    % %+++    SAVE  DATA     3    4           ++
    % %++++++++++++++++++++++++++++
    for i=1:4
        x_pick_1234(i,e)=x_pick(i,:);
        y_pick_1234(i,e)=y_pick(i,:);
        x_real_1234(i,e)=x_pick(i,:);
        y_real_1234(i,e)=y_pick(i,:);
    end
    % %____medial line xy _________
    medial_x=[x_pick(4),x_pick(3)];
    medial_y=[y_pick(4),y_pick(3)];
    later_x=[x_pick(2),x_pick(1)];
    later_y=[y_pick(2),y_pick(1)];
    %     medial_x=[x_pick(4),x_pick(2)];
%     medial_y=[y_pick(4),y_pick(2)];
%     later_x=[x_pick(3),x_pick(1)];
%     later_y=[y_pick(3),y_pick(1)];
    x_a=medial_x;
    y_a=medial_y;
    x_b=later_x;
    y_b=later_y;
    %+++++++++++++++++++++++++++++
    %+++          Foox axis                     +++
    %+++++++++++++++++++++++++++++
    %==  x_cm= (x axis)(center line)(middle line segmen) ==

    x_cm=[ (x_a(1)+x_b(1))/2,...
        (x_a(2)+x_b(2))/2,   ];
    y_cm=[ (y_a(1)+y_b(1))/2,...
        (y_a(2)+y_b(2))/2   ];
    ploy_a=polyfit(x_a,y_a,1);
    ploy_b=polyfit(x_b,y_b,1);
    ploy_cm=polyfit(x_cm,y_cm,1);

    plot(x_a,y_a,'yo-','linewidth',1);hold on;
    plot(x_b,y_b,'yo-','linewidth',1);hold on;

    heel_end10=-70;
    toe_head=-130;
    y_ch_ps=round(y_cm(1)) - heel_end10;
    x_ch_ps=(y_ch_ps - ploy_cm(2) )/ploy_cm(1);

    y_ct_ps=round(y_cm(2)) + toe_head;
    x_ct_ps=(y_ct_ps - ploy_cm(2) )/ploy_cm(1);
    plot([x_ch_ps,x_ct_ps],[y_ch_ps,y_ct_ps],'w-','linewidth',1);hold on;
    % %++++++++++++++++++++++++++++
    % %+++   Pick   left foot    toe   1           ++
    % %+++                             MT   2          ++
    % %+++                             heel 3           ++
    % %++++++++++++++++++++++++++++++
    clear x_pick;clear y_pick
    x_pick=xy_pick_data(5:7,1);
    y_pick=xy_pick_data(5:7,2);

    for i=1:3
        plot( x_pick(i,:), y_pick(i,:),'rx', 'linewidth',1);hold on;
    end
    y_ct_p=y_pick(1);
    x_ct_p=(y_ct_p - ploy_cm(2) )/ploy_cm(1);
    plot(x_ct_p,y_ct_p,'go','linewidth',1);hold on;

    y_cd1_p=y_pick(2);
    x_cd1_p=(y_cd1_p - ploy_cm(2) )/ploy_cm(1);
    plot(x_cd1_p,y_cd1_p,'go','linewidth',1);hold on;

    y_ch_p=y_pick(3);
    x_ch_p=(y_ch_p - ploy_cm(2) )/ploy_cm(1);
    plot(x_ch_p,y_ch_p,'go','linewidth',1);hold on;
    % %++++++++++++++++++++++++++++
    % %+++           SAVE  DATA                ++
    % %+++   Pick   left foot  1    2            ++
    % %+++                           3    4           ++
    % %++++++++++++++++++++++++++++
    for i=1:3
        x_pick_567(i,e)=x_pick(i,:);
        y_pick_567(i,e)=y_pick(i,:);
    end
    x_real_567(:,e)=[x_ct_p;x_cd1_p;x_ch_p];
    y_real_567(:,e)=[y_ct_p;y_cd1_p;y_ch_p];
    % %++++++++++++++++++++++++++++
    % %+++  Quarter mid foot                 ++
    % %+++    x_c2_p=center line 1/2      ++
    % %++++++++++++++++++++++++++++
    x_c2_p=(x_cd1_p+x_ch_p)/2;
    y_c2_p=(y_cd1_p+y_ch_p)/2;
    plot(x_c2_p,y_c2_p,'yo','linewidth',1);hold on;
    plot(x_c2_p,y_c2_p,'bo','linewidth',1);hold on;
    %++++++++++++++++++++++++++++++
    %++     % foot 1/3 ( except toe)     ++++
    %++++++++++++++++++++++++++++++
    %===  (a-b)/(x-b)=3/1 ; x=(a-b)/3 +b
    x_cd2_p=(x_ch_p- x_cd1_p)/3 + x_cd1_p;
    y_cd2_p=(y_ch_p- y_cd1_p)/3 + y_cd1_p;

    x_cd3_p=(x_ch_p- x_cd1_p)/3*2 + x_cd1_p;
    y_cd3_p=(y_ch_p- y_cd1_p)/3*2 + y_cd1_p;
    % text(x_cd3_p,y_cd3_p,'\leftarrow cd3_p');

    x_ch_cd=[x_cd1_p, x_cd2_p, x_cd3_p,x_cm(1), x_cm(2)];
    y_ch_cd=[y_cd1_p, y_cd2_p, y_cd3_p,y_cm(1), y_cm(2)];
    for i=1:length(x_ch_cd)
        length_ch_cd(i)=sqrt( (x_ch_cd(i) - x_ch_p )^2+...
            (y_ch_cd(i) - y_ch_p )^2  );
    end
    %+++++++++++++++++++++++++++++++++++
    %+++                                            ++++++++++
    %+++   Foox axis perpendicular   ++++++++++
    %+++      heel point & toe-point    ++++++++++
    %+++                                            ++++++++++
    %+++++++++++++++++++++++++++++++++++
    x_c=[x_ch_p,x_ct_p, x_cd3_p,x_cd2_p,x_cd1_p, x_cm(1), x_cm(2),x_c2_p];
    y_c=[y_ch_p ,y_ct_p, y_cd3_p,y_cd2_p, y_cd1_p, y_cm(1), y_cm(2),y_c2_p];
    %=============================
    %==  draw 2 times in foot and intersect
    %==      (COP Fn & cm(footaxis)) ====
    %=============================
    for i=1: length(x_c);
        %== (1) x2= (a) x1 + (b), perpendicular  (a) x2 = (-1) x1 +c
        %==  x2= (-1) x1/ (a)   +  constant_vc
        %==   U.V=x1x2 + y1y2  = a + (-1)a
        %==   x2= (a) x1 + constant_vc

        %===== for i end  key is under here   ====
        constant_vc=ploy_cm(1)*y_c(i)   + x_c(i);
        ploy_vc=[-1/ploy_cm(1),  constant_vc/ploy_cm(1)];
        %==  vc & a  intersect    ==
        function_vc_a  = [-ploy_a(1),1 ;...
            -ploy_vc(1),1];
        constant_vc_a = [ ploy_a(2); ...
            ploy_vc(2)];
        vc_a=inv( function_vc_a )* constant_vc_a ;
        %==  vc & b  intersect    ==
        function_vc_b  = [-ploy_b(1),1 ;...
            -ploy_vc(1),1];
        constant_vc_b = [ ploy_b(2); ...
            ploy_vc(2)];
        vc_b=inv( function_vc_b )* constant_vc_b ;
        x_vc_a(i)=vc_a(1);
        x_vc_b(i)=vc_b(1);
        y_vc_a(i)=vc_a(2);
        y_vc_b(i)=vc_b(2);
    end
    %=============================
    %==  draw 2 times in foot and intersect
    %==      (medial and lateral line)====
    %==        (foot axis)              ====
    %=============================
    plot([x_vc_a],[y_vc_a],'w-','linewidth',1);hold on;
    plot([x_vc_b],[y_vc_b],'w-','linewidth',1);hold on;
    plot([x_ch_p,x_ct_p],[y_ch_p,y_ct_p],'k-o','linewidth',1);hold on;
    for i=1:length(x_vc_a)-2
        plot([x_vc_a(i),x_vc_b(i)],[y_vc_a(i),y_vc_b(i)],'c-^','linewidth',1);hold on;
    end
    % for i=length(x_vc_a)-1:length(x_vc_a)
    %     plot([x_vc_a(i),x_vc_b(i)],[y_vc_a(i),y_vc_b(i)],'k-^','linewidth',1);hold on;
    % end
    % %++++++++++++++++++++++++++++
    % %+++  Quarter mid foot                 ++
    %%++                                                ++
    % %+++  x_c2_p=center line 1/2      ++
    %%+++   length(x_vc_a) = 8         ++
    %%+++   (x_vc_a) , a is mieial         ++
    %%+++   (x_vc_b) , a is lateral         ++
    % %++++++++++++++++++++++++++++
    plot( [x_vc_a(8),x_vc_b(8)],[y_vc_a(8),y_vc_b(8)],'y-o','linewidth',1);hold on;
    plot( [x_vc_a(8),x_vc_b(8)],[y_vc_a(8),y_vc_b(8)],'b-x','linewidth',1);hold on;
    for i=1:3
        x_vc_q=  (x_vc_a(8)- x_vc_b(8) )/4*i+x_vc_b(8);
        y_vc_q=  (y_vc_a(8)- y_vc_b(8) )/4*i+y_vc_b(8) ;
        plot( x_vc_q, y_vc_q,'y-x','linewidth',1);hold on;
        plot( x_vc_q, y_vc_q,'b-x','linewidth',1);hold on;
    end
    % %+++++++++++++++++++++++++++++++
    % %+++   Pick   midline point                   ++
    % %+++   c2 =center line 1/2                    ++
    % %+++   c2p =center line 1/2, pick point ++
    % %+++++++++++++++++++++++++++++++
    ploy_c2=polyfit([x_vc_a(8),x_vc_b(8)],[y_vc_a(8), y_vc_b(8)],1);

    clear x_pick;clear y_pick
    x_pick=xy_pick_data(8,1);
    y_pick=xy_pick_data(8,2);
    plot( x_pick, y_pick,'rx', 'linewidth',1);hold on;
    x_c2p_p=x_pick(1);
    if (x_pick>5) & (x_pick<55) & (y_pick>390) & (y_pick<440)
        y_c2p_p=y_pick(1);
        c2p_ratio(e,:)=   0;
    else
        y_c2p_p= x_c2p_p *ploy_c2(1) + ploy_c2(2) ;
        c2_length=sqrt(  (  x_vc_a(8)-x_vc_b(8) )^2 + ( y_vc_a(8)-y_vc_b(8) )^2 );
        c2p_length=sqrt(  (  x_c2p_p-x_vc_b(8) )^2 + ( y_c2p_p -y_vc_b(8) )^2 );
        c2p_ratio(e,:)=   c2p_length/ c2_length*100;
    end
    plot(x_c2p_p,y_c2p_p,'go','linewidth',1);hold on;
      text(50*e^3,470,  [ 'Mid-Line_r_a_t_i_o =  ', num2str(c2p_ratio(e,:),3),'%'] , 'FontSize', 10, 'color', [1,0,0]  );

    % %+++++++++++++++++++++++
    % %+++ SAVE  DATA                ++
    % %+++   Pick     8                     ++
    % %++++++++++++++++++++++++
    x_pick_8(:,e)=x_pick;
    y_pick_8(:,e)=y_pick;
    x_real_8(:,e)=x_c2p_p;
    y_real_8(:,e)=y_c2p_p;
    x_vc_ae(:,e)=x_vc_a';
    y_vc_ae(:,e)=y_vc_a';
    x_vc_be(:,e)=x_vc_b';
    y_vc_be(:,e)=y_vc_b';
    % %++++++++++++++++++++++++
    % %+++           SAVE                 ++
    % %++++++++++++++++++++++++
    x_pick_e(e*8-7:e*8,:)=[x_pick_1234(:,e);x_pick_567(:,e);x_pick_8(:,e)];
    y_pick_e(e*8-7:e*8,:)=[y_pick_1234(:,e);y_pick_567(:,e);y_pick_8(:,e)];
    x_real_e(e*8-7:e*8,:)=[x_real_1234(:,e);x_real_567(:,e);x_real_8(:,e)];
    y_real_e(e*8-7:e*8,:)=[y_real_1234(:,e);y_real_567(:,e);y_real_8(:,e)];
    for i=1:8
        text( x_pick_e(e*8-8+i,:)+10, y_pick_e(e*8-8+i,:),[num2str(i)],'color', [1,1,1],'FontSize',14);
        text( x_pick_e(e*8-8+i,:)+11, y_pick_e(e*8-8+i,:),[num2str(i)],'color', [.3,.3,.3],'FontSize',11);
    end
end
% save_pick_data=[ x_pick_e, y_pick_e];
% save_real_data=[ x_real_e, y_real_e];
% save_ratio_data=[ c2p_ratio];
