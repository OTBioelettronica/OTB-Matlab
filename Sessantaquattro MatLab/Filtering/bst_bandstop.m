

%% ===== EXTERNAL CALL =====
% USAGE: x = process_bandstop('Compute', x, sfreq, FreqList, FreqWidth=1.5, method='fieldtrip_butter')
function [x, FiltSpec, Messages] = bst_bandstop(x, sfreq, FreqList, FreqWidth, method)
    % Define a default method and width
    if (nargin < 4) || isempty(FreqWidth) || isempty(method)
        method = 'fieldtrip_butter';
        FreqWidth = 1.5;
    end
    % Check list of freq to remove
    if isempty(FreqList) || isequal(FreqList, 0)
        return;
    end
    % Nyqist frequency
    Fnyq = sfreq/2;
    % Remove the mean of the data before filtering
    if ~isempty(x)
        xmean = mean(x,2);
        x = bsxfun(@minus, x, xmean);
    end
    
    % Remove all the frequencies sequencially
    for ifreq = 1 :length(FreqList)
        % Frequency band to remove
        FreqBand = [FreqList(ifreq) - FreqWidth/2, FreqList(ifreq) + FreqWidth/2];
        % Filtering using the selected method
        switch (method)
            % Source: FieldTrip toolbox
            % Equivalent to: x = ft_preproc_bandstopfilter(x, sfreq, FreqBand, [], 'but');
            case 'fieldtrip_butter'
                % Filter order
                N = 4;
                % Butterworth filter
                if exist('fir2', 'file')
                    [B,A] = butter(N, FreqBand ./ Fnyq, 'stop');
                else
                    [B,A] = oc_butter(N, FreqBand ./ Fnyq, 'stop');
                end
                FiltSpec.b(ifreq,:) = B;
                FiltSpec.a(ifreq,:) = A;
                % Filter signal
                if ~isempty(x)
                    x = filtfilt(B, A, x')';
                end

            % Source: FieldTrip toolbox
            % Bandstop filter: Onepass-zerophase, hamming-windowed sinc FIR
            % Equivalent to: x = ft_preproc_bandstopfilter(x, sfreq, FreqBand, [], 'firws');
            case 'fieldtrip_firws'
                % Constants
                TRANSWIDTHRATIO = 0.25;
                % Max possible transition band width
                maxTBWArray = [FreqBand * 2, (Fnyq - FreqBand) * 2, diff(FreqBand)];
                maxDf = min(maxTBWArray);
                % Default filter order heuristic
                df = min([max([FreqBand(1) * TRANSWIDTHRATIO, 2]) maxDf]);
                if (df > maxDf)
                    error('Transition band too wide. Maximum transition width is %.2f Hz.', maxDf)
                end
                % Compute filter order from transition width
                N = firwsord('hamming', sfreq, df, []);
                % Window
                win = bst_window('hamming', N+1);
                % Impulse response
                B = firws(N, FreqBand / Fnyq, 'stop', win);
                % Padding
                x = x';
                groupDelay = (length(B) - 1) / 2;
                startPad = repmat(x(1,:), [groupDelay 1]);
                endPad = repmat(x(end,:), [groupDelay 1]);
                % Filter data
                x = filter(B, 1, [startPad; x; endPad]);
                % Remove padded data
                x = x(2 * groupDelay + 1:end, :);
                x = x';
        end
    end
    
    % Restore the mean of the signal
    if ~isempty(x)
        x = bsxfun(@plus, x, xmean);
    end
    
    % Find the general transfer function
    switch (method)
        case 'fieldtrip_butter'
            FiltSpec.NumT = FiltSpec.b(1,:) ; 
            FiltSpec.DenT = FiltSpec.a(1,:) ; 
%             if length(FreqList)>1
%                 for ifreq = 2:length(FreqList)
%                     FiltSpec.NumT = conv(FiltSpec.NumT,FiltSpec.b(ifreq,:)) ; 
%                     FiltSpec.DenT = conv(FiltSpec.DenT,FiltSpec.a(ifreq,:)) ; 
%                 end
%             end
            FiltSpec.order = length(FiltSpec.DenT)-1 ;
%             FiltSpec.cutoffBand = FreqBand ; 
            % Compute the cumulative energy of the impulse response
            [h,t] = impz(FiltSpec.NumT,FiltSpec.DenT,[],sfreq);
            E = h(1:end) .^ 2 ;
            E = cumsum(E) ;
            E = E ./ max(E) ;
            % Compute the effective transient: Number of samples necessary for having 99% of the impulse response energy
            [tmp, iE99] = min(abs(E - 0.99)) ;
            FiltSpec.transient      = iE99 / sfreq ;
    end
    Messages = [] ;

function F = bst_window( Method, L, R )
% BST_WINDOW: Generate a window of length L, ot the given type: hann, hamming, blackman, parzen, tukey
% 
% USAGE:  F = bst_window( Method, L, R )
% 
% References:
%    Formulas documented on Wikipedia: http://en.wikipedia.org/wiki/Window_function

% @=============================================================================
% This function is part of the Brainstorm software:
% https://neuroimage.usc.edu/brainstorm
% 
% Copyright (c)2000-2019 University of Southern California & McGill University
% This software is distributed under the terms of the GNU General Public License
% as published by the Free Software Foundation. Further details on the GPLv3
% license can be found at http://www.gnu.org/copyleft/gpl.html.
% 
% FOR RESEARCH PURPOSES ONLY. THE SOFTWARE IS PROVIDED "AS IS," AND THE
% UNIVERSITY OF SOUTHERN CALIFORNIA AND ITS COLLABORATORS DO NOT MAKE ANY
% WARRANTY, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO WARRANTIES OF
% MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE, NOR DO THEY ASSUME ANY
% LIABILITY OR RESPONSIBILITY FOR THE USE OF THIS SOFTWARE.
%
% For more information type "brainstorm license" at command prompt.
% =============================================================================@
%
% Authors: Francois Tadel, 2013-2014

% Parse inputs
if (nargin < 3) || isempty(R)
    R = [];
end
if (nargin < 2) || isempty(L)
    L = 64;
end
if (nargin < 1) || isempty(Method)
    Method = 'hann';
end
% Calculate normalized time vector
t = (0:L-1)' ./ (L-1);
% Switch according to windowing method 
switch (lower(Method))
    case 'hann'
        F = 0.5 - 0.5 * cos(2*pi*t);
    case 'hamming'
        F = 0.54 - 0.46 * cos(2*pi*t);
    case 'blackman'
        F = 0.42 - 0.5 * cos(2*pi*t) + 0.08 * cos(4*pi*t);
    case 'tukey'
        % Tukey window = tapered cosine window, cosine lobe of width aL/2 
        if isempty(R)
            R = 0.5;
        end
        a = R;
        % If a=0: square function
        if (a <= 0)
            F = ones(L,1);
        % If a=1: Hann window
        elseif (a >= 1)
            F = bst_window('hann', L);
        % Else: Function in three blocks
        else
            % Define three blocks
            len = floor(a*(L-1)/2) + 1;
            t1 = t(1:len);
            t3 = t(L-len+1:end);
            % Window is defined in three sections: taper, constant, taper
            F = [ 0.5 * (1 + cos(pi * (2*t1/a - 1)));  ...
                  ones(L-2*len,1); ...
                  0.5 * (1 + cos(pi * (2*t3/a - 2/a*(L-1) - 1)))];
        end
    case 'parzen'
        % Reference:
        % Harris FJ, On the Use of Windows for Harmonic Analysis with the Discrete Fourier Transform, 
        % Proceedings of IEEE, Vol. 66, No. 1, January 1978   [Equation 37]
        
        % Time indices
        t = -(L-1)/2 : (L-1)/2;
        i1 = find(abs(t) <= (L-1)/4);  %   0 <= |n| <= N/4
        i2 = find(abs(t) >  (L-1)/4);  % N/4 <  |n| <  N/2
        
        % Definition of the Parzen window: 2 parts
        F = zeros(length(t), 1);
        F(i1) = 1 - 6 .* (t(i1)/L*2).^2 .* (1 - abs(t(i1))/L*2);
        F(i2) = 2 .* (1 - abs(t(i2))/L*2) .^3;
        
    otherwise
        error(['Unsupported windowing method: "' Method '".']);
end



% firwsord() - Estimate windowed sinc FIR filter order depending on
%              window type and requested transition band width
%
% Usage:
%   >> [m, dev] = firwsord(wtype, fs, df);
%   >> m = firwsord('kaiser', fs, df, dev);
%
% Inputs:
%   wtype - char array window type. 'rectangular', 'bartlett', 'hann',
%           'hamming', 'blackman', or 'kaiser'
%   fs    - scalar sampling frequency
%   df    - scalar requested transition band width
%   dev   - scalar maximum passband deviation/ripple (Kaiser window
%           only)
%
% Output:
%   m     - scalar estimated filter order
%   dev   - scalar maximum passband deviation/ripple
%
% References:
%   [1] Smith, S. W. (1999). The scientist and engineer's guide to
%       digital signal processing (2nd ed.). San Diego, CA: California
%       Technical Publishing.
%   [2] Proakis, J. G., & Manolakis, D. G. (1996). Digital Signal
%       Processing: Principles, Algorithms, and Applications (3rd ed.).
%       Englewood Cliffs, NJ: Prentice-Hall
%   [3] Ifeachor E. C., & Jervis B. W. (1993). Digital Signal
%       Processing: A Practical Approach. Wokingham, UK: Addison-Wesley
%
% Author: Andreas Widmann, University of Leipzig, 2005
%
% See also:
%   firws, invfirwsord

%123456789012345678901234567890123456789012345678901234567890123456789012

% Copyright (C) 2005-2014 Andreas Widmann, University of Leipzig, widmann@uni-leipzig.de
%
% This program is free software; you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation; either version 2 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program; if not, write to the Free Software
% Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
%
% $Id$

function [ m, dev ] = firwsord(wintype, fs, df, dev)

winTypeArray = {'rectangular', 'bartlett', 'hann', 'hamming', 'blackman', 'kaiser'};
winDfArray = [0.9 2.9 3.1 3.3 5.5];
winDevArray = [0.089 0.056 0.0063 0.0022 0.0002];

% Check arguments
if nargin < 3 || isempty(fs) || isempty(df) || isempty(wintype)
    ft_error('Not enough input arguments.')
end

% Window type
wintype = find(strcmp(wintype, winTypeArray));
if isempty(wintype)
    ft_error('Unknown window type.')
end

df = df / fs; % Normalize transition band width

if wintype == 6 % Kaiser window
    if nargin < 4 || isempty(dev)
        ft_error('Not enough input arguments.')
    end
    devdb = -20 * log10(dev);
    m = 1 + (devdb - 8) / (2.285 * 2 * pi * df);
else
    m = winDfArray(wintype) / df;
    dev = winDevArray(wintype);
end

m = ceil(m / 2) * 2; % Make filter order even (FIR type I)



%firws() - Designs windowed sinc type I linear phase FIR filter
%
% Usage:
%   >> b = firws(m, f);
%   >> b = firws(m, f, w);
%   >> b = firws(m, f, t);
%   >> b = firws(m, f, t, w);
%
% Inputs:
%   m - filter order (mandatory even)
%   f - vector or scalar of cutoff frequency/ies (-6 dB;
%       pi rad / sample)
%
% Optional inputs:
%   w - vector of length m + 1 defining window {default blackman}
%   t - 'high' for highpass, 'stop' for bandstop filter {default low-/
%       bandpass}
%
% Output:
%   b - filter coefficients
%
% Example:
%   fs = 500; cutoff = 0.5; df = 1;
%   m  = firwsord('hamming', fs, df);
%   b  = firws(m, cutoff / (fs / 2), 'high', windows('hamming', m + 1)); 
%
% References:
%   Smith, S. W. (1999). The scientist and engineer's guide to digital
%   signal processing (2nd ed.). San Diego, CA: California Technical
%   Publishing.
%
% Author: Andreas Widmann, University of Leipzig, 2005
%
% See also:
%   firwsord, invfirwsord, kaiserbeta, windows

%123456789012345678901234567890123456789012345678901234567890123456789012

% Copyright (C) 2005 Andreas Widmann, University of Leipzig, widmann@uni-leipzig.de
%
% This program is free software; you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation; either version 2 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program; if not, write to the Free Software
% Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
%
% $Id$

function [b, a] = firws(m, f, t, w)

    a = 1;

    if nargin < 2
        ft_error('Not enough input arguments');
    end
    if length(m) > 1 || ~isnumeric(m) || ~isreal(m) || mod(m, 2) ~= 0 || m < 2
        ft_error('Filter order must be a real, even, positive integer.');
    end
    f = f / 2;
    if any(f <= 0) || any(f >= 0.5)
        ft_error('Frequencies must fall in range between 0 and 1.');
    end
    if nargin < 3 || isempty(t)
        t = '';
    end
    if nargin < 4 || isempty(w)
        if ~isempty(t) && ~ischar(t)
            w = t;
            t = '';
        else
            w = windows('blackman', (m + 1));
        end
    end
    w = w(:)'; % Make window row vector

    b = fkernel(m, f(1), w);

    if length(f) == 1 && strcmpi(t, 'high')
        b = fspecinv(b);
    end

    if length(f) == 2
        b = b + fspecinv(fkernel(m, f(2), w));
        if isempty(t) || ~strcmpi(t, 'stop')
            b = fspecinv(b);
        end
    end

% Compute filter kernel
function b = fkernel(m, f, w)
    m = -m / 2 : m / 2;
    b(m == 0) = 2 * pi * f; % No division by zero
    b(m ~= 0) = sin(2 * pi * f * m(m ~= 0)) ./ m(m ~= 0); % Sinc
    b = b .* w; % Window
    b = b / sum(b); % Normalization to unity gain at DC

% Spectral inversion
function b = fspecinv(b)
    b = -b;
    b(1, (length(b) - 1) / 2 + 1) = b(1, (length(b) - 1) / 2 + 1) + 1;