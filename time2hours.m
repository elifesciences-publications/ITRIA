function [time_array]=time2hours(timeLabel)
%This function converts a label of time duration (a string cell in the 
%format of time duration) into the number of hours with the appropriate 
%sign, (-) for before the event and (+) for after.
d_str=regexprep(timeLabel,'d?\s?\-?(?:\d{1,2}[hms])?','');
H_str=regexprep(timeLabel,'h?\s?\-?(?:\d{1,2}[dms])?','');
MN_str=regexprep(timeLabel,'m?\s?\-?(?:\d{1,2}[dhs])?','');
sign=regexprep(timeLabel,'[^\-]','');
signInd=strcmp(sign,'-');
d_num=str2double(d_str);
d_num(isnan(d_num))=0;
H_num=str2double(H_str);
H_num(isnan(H_num))=0;
MN_num=str2double(MN_str);
MN_num(isnan(MN_num))=0;
H_num_total=H_num+(MN_num./60)+(24.*d_num);
H_num_total(signInd)=-H_num_total(signInd);
time_array=H_num_total;

end