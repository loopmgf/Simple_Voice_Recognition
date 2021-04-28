%% Reconocimiento de voz - Distinción entre dos comandos básicos.
%-----------------------------
clc
clear all
close all
%-----------------------------
% Generación y guardado de muestras de audio
%-----------------------------
Fs = 44100; % Frecuencia de sampleo típica para una señal de audio.
nBits = 16; % Se trabaja con una resolución de 16 bits.
nChannel = 1; % Se grabará solo un canal.
duracion = 2; % Tiempo total de grabación.
load flag.mat flag % Se carga la variable flag de base de datos. Si es 1 entonces el sistema se encuentra encendido. Si es 0 se encuentra apagado.
error = zeros(1,2); % Vector que contendrá los errores provenientes de la diferencia entre las DEE.
%-----------------------------
% Grabado de la muestra y presentación de instrucciones. 
%-----------------------------
sample = audiorecorder(Fs,nBits,nChannel);
disp('Instrucciones: se procederá a grabar una muestra de su voz. Los comandos disponibles para interactuar con el sistema son "prender" y "apagar".')
%-----------------------------  
if(flag)
    disp('El sistema se encuentra: ENCENDIDO.');
else                                                    % Se le informa al usuario el estado del sistema que fue cargado desde la base de datos.
    disp('El sistema se encuentra: APAGADO.');
end
%------------------------------
disp('A continuación se grabará el comando que desee ejecutar.')
disp('Presione una tecla para continuar.')
pause;
disp('Grabando...')
recordblocking(sample, duracion);
disp('Grabación finalizada.')
disp('Procesando...')
recorded_sample = getaudiodata(sample);
audiowrite('muestra.wav', recorded_sample, Fs); % Se guarda la muestra en el directorio de trabajo.
%------------------------------
% Tratamiento de la muestra y de los audios de referencia.
%------------------------------
[y,Fs] = audioread('muestra.wav');
y = y/max(abs(y)); % Se normaliza la amplitud (volumen) de la señal en el tiempo.
T = 1/Fs;
N = length(y);
t = (0:N-1)*T;
NFFT = 2^nextpow2(N);
Y = fft(y, NFFT); % Se calcula la transformada de Fourier.
Y = Y(1:NFFT/2); % Como se va a trabajar con señales reales, se recorta el espectro y se trabaja con el espectro unilateral.
Yabs = abs(Y); % Se calcula el módulo de la transformada.
DEEs = Yabs.^2; % Densidad espectral de energía de la muestra.
f = (0:NFFT/2-1)*Fs/NFFT; % Vector de frecuencia en Hz.
%------------------------------
[v,Fs] = audioread('prender.wav');
v = v/max(abs(v));
V = fft(v, NFFT);
V = V(1:NFFT/2);
Vabs = abs(V);
DEEa = Vabs.^2; % Densidad espectral de energía del comando "abrir".
%------------------------------
[x,Fs] = audioread('apagar.wav');
x = x/max(abs(x));
X = fft(x, NFFT);
X = X(1:NFFT/2);
Xabs = abs(X);
DEEc = Xabs.^2; % Densidad espectral de energía del comando "cerrar".
%------------------------------
%Condidión de decisión: mínimo valor medio entre la resta de Densidades.
%------------------------------
error(1) = mean(abs(DEEs(1:Fs/2)-DEEa(1:Fs/2))); % Se calculan los errores en base al módulo de la diferencia entre las densidades espectrales de energía.
error(2) = mean(abs(DEEs(1:Fs/2)-DEEc(1:Fs/2))); % Se tienen en cuenta los valores que llegan hasta la frecuencia de Nyquist (fmax = fs/2).
%------------------------------
%------------------------------
%Condicón de decisión: máximo valor de la correlación cruzada de las
%densidades
%------------------------------
[c1,lag1] = xcorr(Yabs,Vabs);
[c2,lag2] = xcorr(Yabs,Xabs);
c1_max = max(c1);
c2_max = max(c2);
%------------------------------
disp('Utilizando correlación cruzada del módulo del espectro de la FFT:')
switch (c1_max > c2_max)
    case 1
        disp('El comando mencionado fue: PRENDER.')
    case 0
        disp('El comando mencionado fue: APAGAR.')
end
%------------------------------
disp('Utilizando el valor promedio del módulo de la resta de las DEE:')
switch min(error)
   case error(1)
       disp('El comando mencionado fue: PRENDER.')
   case error(2)
       disp('El comando mencionado fue: APAGAR.')
end
%------------------------------
coincidencia = (min(error)== error(1)) && (c1_max > c2_max) || (min(error)== error(2)) && (c1_max < c2_max);

if (coincidencia)
    if(flag)
        if((min(error)== error(1)))
            disp('El sistema ya se encuentra en funcionamiento')
        else
            disp('El sistema fue apagado')
            flag = 0;
        end
    else
        if((min(error)== error(1)))
            disp('El sistema fue encendido.')
            flag = 1;
        else
            disp('El sistema ya se encuentra apagado.')
        end
    end
else
    disp('No se tomará acción por falta de coincidencia')
end            
%------------------------------
save flag.mat flag % Se guarda la variable flag modificada en base de datos.
%------------------------------
%Graficos
%------------------------------
figure;
subplot(2,4,1);
plot(t,y);
xlabel('Tiempo [s]');
ylabel('Amplitud normalizada');
title('Audio señal muestreada');
grid on;
axis tight;
%------------------------------
subplot(2,4,2);
plot(t,v);
xlabel('Tiempo [s]');
ylabel('Amplitud normalizada');
title('Audio base de datos: Prender');
grid on;
axis tight;
%------------------------------
subplot(2,4,3);
plot(t,x);
xlabel('Tiempo [s]');
ylabel('Amplitud normalizada');
title('Audio base de datos: Apagar');
grid on;
axis tight;
%------------------------------
subplot(2,4,5);
plot(f(1:Fs/4),DEEs(1:Fs/4));
xlabel('Frecuencia [Hz]');
ylabel('|Y(f)|²');
title('Densidad espectral de energía muestra');
grid on;
axis tight;
%------------------------------
subplot(2,4,6);
plot(f(1:Fs/4),DEEa(1:Fs/4));
xlabel('Frecuencia [Hz]');
ylabel('|V(f)|²');
title('Densidad espectral de energía: Prender');
grid on;
axis tight;
%------------------------------
subplot(2,4,7);
plot(f(1:Fs/4),DEEc(1:Fs/4));
xlabel('Frecuencia [Hz]');
ylabel('|X(f)|²');
title('Densidad espectral de energía: Apagar');
grid on;
axis tight;
%------------------------------
subplot(2,4,4);
plot(lag1/Fs,c1);
xlabel('Tiempo [s]');
ylabel('Amplitud');
title('Correlación cruzada muestra-prender');
grid on;
axis tight;
%------------------------------
subplot(2,4,8);
plot(lag2/Fs,c2);
xlabel('Tiempo [s]');
ylabel('Amplitud');
title('Correlación cruzada muestra-apagar');
grid on;
axis tight;
%------------------------------