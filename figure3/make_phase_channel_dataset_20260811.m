function [uRaw,uEncoded,target,received,meta] = ...
    make_phase_channel_dataset_20260811(numSamples,seedOffset)
%MAKE_PHASE_CHANNEL_DATASET_20260811 Synthetic coherent BPSK phase stream.

arguments
    numSamples (1,1) double {mustBeInteger,mustBePositive}
    seedOffset (1,1) double {mustBeInteger,mustBeNonnegative}
end
rng(5081 + 7919*seedOffset,'twister');
symbols = 2*(rand(numSamples,1) >= 0.5) - 1;
h = [1.00; 0.58*exp(1i*0.72); 0.34*exp(-1i*1.05); ...
    0.21*exp(1i*1.41); 0.12*exp(-1i*0.38)];
h = h/norm(h);
linearField = filter(h,1,symbols);
gamma = 0.42;
noiseless = linearField.*exp(1i*gamma*abs(linearField).^2);
snrDb = 24;
noisePower = mean(abs(noiseless).^2)/10^(snrDb/10);
noise = sqrt(noisePower/2)*(randn(numSamples,1)+1i*randn(numSamples,1));
received = noiseless + noise;
uRaw = angle(received)/pi;
uEncoded = uRaw;
decisionDelay = 2;
target = zeros(numSamples,1);
target(decisionDelay+1:end) = symbols(1:end-decisionDelay);

meta.seed_offset = seedOffset;
meta.channel_taps = h;
meta.gamma = gamma;
meta.snr_db = snrDb;
meta.decision_delay = decisionDelay;
meta.symbols = symbols;
end
