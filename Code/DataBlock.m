function r = DataBlock()
%TRIALCB Summary of this function goes here
%   Detailed explanation goes here
   data = struct;
   indx = 1;

   function Callback( msec, deg )
      data(indx).msec = msec;
      data(indx).deg = deg;
      indx = indx + 1;
   end

   function Plot()
      hold on
      xlabel( 'Degrees of XY Rotation' );
      ylabel( 'RT in ms' );
      axis( [0 360 0 Inf] );
      plot( [data.deg], [data.msec], 'o' );
      p = polyfit( [data.deg], [data.msec], 1 );
      plot( 1:360, polyval(p, 1:360) );
      hold off
   end

   function ret = Data()
      ret = data;
   end

   r.Callback = @Callback;
   r.Plot = @Plot;
   r.Data = @Data;
end
