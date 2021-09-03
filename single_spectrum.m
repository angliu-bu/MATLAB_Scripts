clear,clc,instrreset;

spectrum_analyzer = SpectrumAnalyzer;

res_BW = 1;
f0 = 15168000
span = 20;
n_points = 1001;
n_aver = 10;

f_start = f0+384-span/2;
f_stop = f0+384+span/2;



spectrum_analyzer.open;
spectrum_analyzer.set_start_frequency(f_start);
spectrum_analyzer.set_stop_frequency(f_stop);
spectrum_analyzer.set_res_BW(res_BW);
spectrum_analyzer.set_n_points(n_points);
spectrum_analyzer.set_n_aver(n_aver);
spectrum_analyzer.set_ref_level(10);
spectrum_analyzer.set_y_scale('LIN');

spectrum_analyzer.close;
%%

filename = 'test_data.txt';

spectrum_analyzer.open;

spectrum_analyzer.display_data;
spectrum_analyzer.save_data(filename);

spectrum_analyzer.close;
