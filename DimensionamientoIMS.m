clear
clc
%% Calculo del trafico de llamadas

%Datos
Erlang_usuario_h = 0.1;
ciudad1 = 100000;
ciudad2 = 100000;
t_llamada_s = 120;
%densidad_poblacion = 1; %habitantes/vivienda
densidad_poblacion = 2.43; %habitantes/vivienda

%Calculo llamadas totales
lineas_t = ceil(ciudad1/densidad_poblacion)+ceil(ciudad2/densidad_poblacion);
llamadas_t = Erlang_usuario_h*lineas_t/(t_llamada_s/3600);
llamadas_t_s = llamadas_t/3600;

%Llamadas por operador
ll_op1_op1 = llamadas_t_s*0.4/2;
ll_op1_op2 = llamadas_t_s*0.6*0.75;
ll_op1_op3 = llamadas_t_s*0.6*0.25;
llamadas_t_s_reales = ll_op1_op1+ll_op1_op2+ll_op1_op3;
llamadas_externas_s_reales = ll_op1_op2+ll_op1_op3;

%Llamadas simultaneas (Erlangs totales por operador)
ll_op1_op1_sim = ll_op1_op1*t_llamada_s;
ll_op1_op2_sim = ll_op1_op2*t_llamada_s;
ll_op1_op3_sim = ll_op1_op3*t_llamada_s;

%% Threshold asegurado de funcionalidad para Erlang C

fiabilidad = 99.99; %por ciento
thr = 100-fiabilidad;

%% MGW SGW
% SGW
trans_ISUP = 5;

% MGW

ll_op1_op2_sim
thr
TS_2_num_EB = input('Lines del calculador Erlang B'); % http://www.jungar.net/apps/erlangb/

E1_2_num = ceil(TS_2_num_EB/30); % 30 TS para datos TS0 para sincronización TS16 para señalización
MGW_2_num = max(ceil(E1_2_num/8),ceil(ll_op1_op2_sim/256));

ll_op1_op3_sim
thr
TS_3_num_EB = input('Lines del calculador Erlang B'); % http://www.jungar.net/apps/erlangb/

E1_3_num = ceil(TS_3_num_EB/30); % 30 TS para datos TS0 para sincronización TS16 para señalización
MGW_3_num = max(ceil(E1_3_num/8),ceil(ll_op1_op3_sim/256));

%MGCF
MGCF_2_num = ceil(MGW_2_num/100);
MGCF_3_num = ceil(MGW_3_num/100);

%% HSS

trans_LIA_LIR = 2;
trans_subscriber_data = 4; % Fetch de subscriber_data a el S/P-CSCF y AS
% https://www.sciencedirect.com/topics/engineering/subscriber-data
trans_HSS = trans_subscriber_data*ll_op1_op1+(trans_subscriber_data+trans_LIA_LIR)*llamadas_externas_s_reales;
T_DB = 10^-3; % https://gist.github.com/jboner/2841832


syms a m u pc i;
m_v_hss = 1:5;
pc_hss = double(subs((m*(a/u)^m)/(factorial(m)*(symsum(a^i/(u^i*factorial(i)), i, 0, m - 1) + (m*(a/u)^m)/(factorial(m)*(m - a/u)))*(m - a/u)),{a, u, m},{trans_HSS, 1/T_DB, m_v_hss}));
figure(5)
plot(m_v_hss,pc_hss) % calculo de redundancia del subsistema con Erlang C
title('Cálculo de la división de HSS por Erlang C')
ylabel('Probabilidad de espera en cola')
xlabel('Número de HSS')
axis([1 5 0 1])
xticks(m_v_hss)
HSS_num_EC = findFirst(pc_hss,thr);
x = [HSS_num_EC HSS_num_EC];
y = [0 1];
line(x,y,'Color','red')

capacidad_usuario = 10^6; %bytes
capacidad_HSS = capacidad_usuario*lineas_t/(10^9)/HSS_num_EC; %GBytes
capacidad_usuario_SLF = 2; %KB SIPURI+extras
capacidad_SLF = capacidad_usuario_SLF*lineas_t/(10^3); %MBytes

%% SBC (P-CSCF + Firewall + STUN/TURN)

trans_SBC_SIP = 28; % para una llamada VoIP
trans_SBC_SIP_t_s = trans_SBC_SIP*llamadas_t_s_reales;
trans_SBC = trans_SBC_SIP+trans_subscriber_data/3;
trans_SBC_t_s = trans_SBC*llamadas_t_s_reales;

%% S-CSCF

trans_SCSCF_SIP = 28;
trans_SCSCF = trans_SCSCF_SIP+trans_subscriber_data/3; % para una llamada VoIP
trans_SCSCF_SIP_t_s = trans_SCSCF_SIP*llamadas_t_s_reales;
trans_SCSCF_t_s = trans_SCSCF_SIP*llamadas_t_s_reales;

%% I-CSCF

trans_ICSCF_SIP = 8; % para una llamada VoIP (suponiendo caso peor todas las llamadas son desde los operadores externos)
trans_ICSCF_SIP_t_s = trans_ICSCF_SIP*llamadas_externas_s_reales;
trans_ICSCF = trans_ICSCF_SIP+trans_LIA_LIR;
trans_ICSCF_t_s = trans_ICSCF*llamadas_externas_s_reales;

%% BGCF

trans_BGCF_SIP = 10; % para una llamada VoIP (suponiendo caso peor todas las llamadas son hacia los operadores externos)
trans_BGCF1_SIP_t_s = trans_BGCF_SIP*ll_op1_op2;
trans_BGCF2_SIP_t_s = trans_BGCF_SIP*ll_op1_op3;

%% MGCF

trans_MGCF = 33; % para una llamada VoIP (suponiendo caso peor todas las llamadas son hacia los operadores externos)
trans_MGCF1_t_s = trans_MGCF*ll_op1_op2;
trans_MGCF2_t_s = trans_MGCF*ll_op1_op3;

%% MRF

Capacidad_MRF = 2*llamadas_t_s_reales*0.05*64*t_llamada_s/(10^3); %Mbit/s

%% VMS

t_VM_s = 30;
t_VM_in_Server = 8; %horas
Capacidad_VMS = llamadas_t_s_reales*0.05*64*t_VM_s*t_VM_in_Server*3600/(8*10^6); %GB