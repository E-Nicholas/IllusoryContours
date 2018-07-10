scenario = "MOBI Fixed SOI w/ GO/NOGO Gratings";

no_logfile = false;
scenario_type = trials;

#active_buttons = 1;
#button_codes = 255;  

default_background_color = 127, 127, 127;
default_text_color = 255, 0, 255;
default_font_size = 18;  

write_codes = false; 
pulse_width = 5;

########################################################################################
begin; #Begin SDL portion of code

$image_on = 100;
text { caption = "+"; font_size = 50; font_color = 255,255,0; transparent_color = 64,64,64;
} fixcross;

bitmap { filename = ""; preload = false;} grating1;
bitmap { filename = ""; preload = false;} grating2;

sound { wavefile { filename = "1000Hz_100ms.wav"; preload = true; }; } standard_tone;
sound { wavefile { filename = "1000Hz_180ms.wav"; preload = true; }; } deviant_tone;

picture { text fixcross; x = 0; y = 0;
} default;

picture { text fixcross; x = 0; y = 0; bitmap grating1; x = -300; y = 0; bitmap grating2; x = 300; y = 0;} gratings_pic;

trial {
	stimulus_event {
		sound standard_tone;  
		time = 0;     
		code = "standard";  
		port_code = 3;  
	} event_standard;
} standard_trial;
  
trial {
	stimulus_event {
		sound deviant_tone;   
		time = 0;     
		code = "deviant";  
		port_code = 5;  
	} event_deviant;
} deviant_trial;

trial {
	picture gratings_pic; time = 0; duration = $image_on;
	stimulus_event{ nothing{}; deltat = 5; port_code = 100; code = "gratingOn";} grating_evt;
} grating_trial;


########################################################################################
begin_pcl; #Begin PCL portion of code
###########################################
int SOI = 1800; 	  								# initially-550; This is the correct SOI. Meaning the ISI will be SOI-stimulus duration
int stim_dur = 100; 								# This represents the length of the standard stimulus, used to calculate ISI
int dev_dur = 180;  								# This is the length of the deviant stimulus
int ntrials = 100;  								# 
int nblocks = 12;   								# 
int minstimstagger = 200;						# This is the minimum time between the offset of the auditory stimulus to the onset of the gratings
array <int> gratingsjitter[2] = {0, 1400};# This sets the range over which the visual stimulus is jittered from the minstimstagger point
int gratingsOn = 100;							#
double fractionGo = 0.5;						#
###########################################
int ngotrials = int(round(ntrials*fractionGo,0));
double nstdtrials = round(ntrials*0.85,0);
int nstdtrials1 = int(nstdtrials);
int jitter = 0;
int draw1 = 1;
int draw2 = 1;
int staticangle = 45;
array <int> angles[] = {20};

loop
	int k = 1
until 
	k > angles.count()
begin
	angles[k] = angles[k]+staticangle;
	k = k + 1;
end;

vsg::gaussian_generator gauss = new vsg::gaussian_generator( 0.0, 65.0 );
vsg::gradient_generator gradient = new vsg::gradient_generator( 0.0, 45.0, 0, false );

vsg::graphic_generator generator = new vsg::graphic_generator( 512.0, 512.0 );
generator.add_transformation( gradient, vsg::combine_none );
generator.add_transformation( gauss.generate( 512.0, 512.0 ), vsg::combine_mask1 );
generator.set_colors( 127.0, 127.0, 127.0, 127.0, 127.0, 127.0 );

gradient.set_angle( staticangle );
graphic_surface image1 = generator.create();

loop
	int j = 1; #loop for blocks
until
	j > nblocks
begin
	int ISI = 0;

###############trial sequence generation
	array <double> toneseq[ntrials];
	array <int> gratingseq[ntrials];
	array <int> nogoseq[ntrials-ngotrials];
	#term.print_line(toneseq);

	toneseq.fill(1,nstdtrials1,1,0);
	toneseq.fill(nstdtrials1+1,ntrials,2,0);
	gratingseq.fill(1,ngotrials,1,0);
	gratingseq.fill(ngotrials+1,ntrials,2,0);
	gratingseq.shuffle();
	
	int stimreps = nogoseq.count()/angles.count();
	
	loop
		int p = 1;
	until
		p > angles.count()
	begin
		nogoseq.fill(1+(stimreps*(p-1)),stimreps*p,p,0);
		p = p + 1;
	end;
	
	nogoseq.shuffle();
	
	loop
		int valid_seq = 0;
	until
		valid_seq > 0 
	begin
		toneseq.shuffle();
		valid_seq = 1;
		loop
			int  i = 3;
		until
			i > toneseq.count()
		begin
			if toneseq[i] == 2 && (toneseq[i-1] == 2 || toneseq[i-2] == 2) then
				valid_seq = 0;
			end;
			if toneseq[1] == 2 || toneseq[2] == 2 then
				valid_seq = 0;
			end;
			i = i+1;
		end;
	end;
	#term.print_line(toneseq);
###############################
	default.present();
	wait_interval(1000);
	loop
		int i = 1
	until
		i > toneseq.count()
	begin #trial presentation loop
		if toneseq[i] == 1 then
			standard_trial.present();
			ISI = SOI - stim_dur;
		elseif  toneseq[i] == 2 then
			deviant_trial.present();
			ISI = SOI - dev_dur;
		end;
		
		wait_interval(minstimstagger);
		
		jitter = random(gratingsjitter[1],gratingsjitter[2]);
		wait_interval(jitter);
		
		if gratingseq[i] == 1 then
			
			gratings_pic.set_part(2,image1);
			gratings_pic.set_part(3,image1);
			
		elseif gratingseq[i] == 2 then
			
			gradient.set_angle( angles[nogoseq[i]] );
			graphic_surface image2 = generator.create();
			
			double flip = random();
			if flip < 0.5 then
				gratings_pic.set_part(2,image1);
				gratings_pic.set_part(3,image2);
			else
				gratings_pic.set_part(3,image1);
				gratings_pic.set_part(2,image2);
			end;
		end;
		
		grating_trial.present();
		
		wait_interval(ISI-minstimstagger-jitter-gratingsOn);
		
		i = i + 1;
	end;
	j = j+1;
end;
