#!c:/perl/bin/perl
'di';  #  Manual page instructions - didn`t work!
'ig00';
######################################################################
#
#File:     evalpplog - evaluate pplog-file(s)
#Author:   Markus Middendorf <markusm@writeme.com>, 
#          Lutz Prechelt <prechelt@computer.org>
#created:  May through August 1998
#changed:  1998-10-26
#RCS:      $Id: evalpplog,v 1.8 1999/10/15 13:25:56 exp Exp $
#
#TO DO:
# - manpage: change examples to use the new timestamp format
#
#
######################### customisation: #########################

## The following variables contain comments, that are inserted into
##  the output. There is one variable for each output mode:

# The defect classification aspects are numbered automatically, starting
#  with no. 1. You can choose names to replace this numeration!
# for example:
# $class_names{"std"}{"classification 1"} = "Defect reason";
# NOTE: The numeration will change, when you use the '-I' flag.
$class_names{"std"}{"classification 1"} = "";
$class_names{"tex"}{"classification 1"} = "";
$class_names{"html"}{"classification 1"} = "";
$class_names{"std"}{"classification 2"} = "";
$class_names{"tex"}{"classification 2"} = "";
$class_names{"html"}{"classification 2"} = "";
# and so on...

# You can add comments to the tables. Please use the suitable format, i.e. don't 
# write 'ä', but '&auml;' in html. Note, that some characters must be quoted to
# appear correctly. You have to write '{\\bf BOLD}' instead of '{\bf BOLD}'.
$comment{"std"}{"defect_statistics"}='This is a defect statistic.';
$comment{"tex"}{"defect_statistics"}='';
$comment{"html"}{"defect_statistics"}='';
$comment{"std"}{"phase_duration"}='';
$comment{"tex"}{"phase_duration"}='';
$comment{"html"}{"phase_duration"}='';
$comment{"std"}{"interrupts"}='';
$comment{"tex"}{"interrupts"}='';
$comment{"html"}{"interrupts"}='';
$comment{"std"}{"by category"}='';
$comment{"tex"}{"by category"}='';
$comment{"html"}{"by category"}='';
$comment{"std"}{"removal eff"}='';
$comment{"tex"}{"removal eff"}='';
$comment{"html"}{"removal eff"}='';
$comment{"std"}{"cross"}{"Total duration"}='';
$comment{"tex"}{"cross"}{"Total duration"}='';
$comment{"html"}{"cross"}{"Total duration"}='';
$comment{"std"}{"cross"}{"Average duration"}='';
$comment{"tex"}{"cross"}{"Average duration"}='';
$comment{"html"}{"cross"}{"Average duration"}='';
$comment{"std"}{"cross"}{"Percentage"}='';
$comment{"tex"}{"cross"}{"Percentage"}='';
$comment{"html"}{"cross"}{"Percentage"}='';
$comment{"std"}{"cross"}{"Number"}='';
$comment{"tex"}{"cross"}{"Number"}='';
$comment{"html"}{"cross"}{"Number"}='';


############### customization only for advanced users ###############

# tags - may be overloaded via input file
$comment_tag = "#";
$phase_start_tag = "b";
$phase_end_tag = "e";
$interrupt_tag = "*";
$defect_tag = "e";
$separator = "#";

# output formats
sub prepare_table {
    if ($output_mode eq "raw") {
	$tl_b = "";          # inserted at beginning of cells of the "total" line
	$tl_e = "";          # inserted at end of cells of the "total" line
        $h_cell_b = "";      # inserted at the beginning of all header cells
	$h_cell_e = "";      # inserted at the end of all header cells
	$table_begin = "";   # a table starts with ...
	$table_sep = "";     # a separator line inside a table is ...
	$table_end = "";     # a table ends with ...
    } elsif ( $output_mode eq "std" ) {
	$tl_b = "";
	$tl_e = "";
        $h_cell_b = "";
	$h_cell_e = "";
	$table_begin = "############ $table_name:\n" . join ('', @headings) . "\n" . "-" x $table_width . "\n";
	$table_sep = "-" x $table_width . "\n";
	$table_end = "-" x $table_width . "\n$table_comment\n";
    } elsif ( $output_mode eq "tex" ) {
	$tl_b = "{\\em ";
	$tl_e = "}";
        $h_cell_b = "{\\bf ";
	$h_cell_e = "}";
	$table_begin = "\\section{$table_name}\n\\begin{center}\\begin{tabular}{|" . "c|" x $column_nr . "}\n\\hline\n${h_cell_b}" . join ("${h_cell_e} & ${h_cell_b}", @headings) . "${h_cell_e}\\\\\n\\hline\n";
	$table_sep = "\\hline\n${tl_b}";
	$table_end = "\\hline\n\\end{tabular}\\\\\n$table_comment\\end{center}\n";
    } elsif ( $output_mode eq "html") {
	$tl_b = "<I>";
	$tl_e = "</I>";
        $h_cell_b = "<B>";
	$h_cell_e = "</B>";
	$table_begin = "<CENTER><TABLE BORDER BGCOLOR=#FFFFFF>\n<TR BGCOLOR=#0000FF><TD>${h_cell_b}" . join ("${h_cell_e}</TD>\n<TD>${h_cell_b}", @headings) . "${h_cell_e}</TD></TR>\n<TR><TD>";
	$table_sep = "</TD></TR>\n<TR BGCOLOR=#FF0000><TD>${tl_b}";
	$table_end = "</TD></TR><CAPTION><B>$table_name" . ($table_comment ? (": " . $table_comment) : "") . "</B></CAPTION>\n</TABLE></CENTER>\n";
    }
}

# 'constant' format information

$output_mode = "std";
$document_header =  "Evaluation of personal process logs:\n$0 @ARGV\n";
$document_ending = "";
$between_paragraphs = "\n\n";
$between_tables = "\n";
$csep = "";		# column separator - to be put between two columns
$lcsep = "#";		# separator for last column - to be put before the last column instead of $csep 
$rsep = "";		# row separator - to be put between two rows

# the 'constant' format information for html-mode, tex-mode and raw-mode must be adapted in the
# declaration of subprogram 'eval_option'

############################## no customisation behind this point ##############################

$cum_phases = 1;
$option_level = 1;
$debug = 0;
$tex_mode = 0;
$defect_count = 0;
$defect_end_count = 0;
$t_abs = 1;
$t_time = 1;
$t_perc = 1;
$injected_class = 1;
$classifications = 0;
$max_len = 8;

# what to print out...
$all = 1;
$s_1d = 0;
$s_2d = 0;
$s_3d = 0;
$s_3dt = 1;
$s_3dn = 1;
$s_dl = 1;

sub debug {
    print "### $.: @_\n" if $debug;
}

# decide, whether the given argument represents a leap year
sub is_leap_year {
    my $year = shift;
    ! ( $year % 4 ) && $year % 100 || ! ( $year % 400 );
}

# calculate the number of leap years between start_year and end_year
sub leap_days {
    my $start_year = shift;
    my $end_year = shift;
    my $leap_days = 0;
    while( $start_year < $end_year ) {
	$leap_days++ if( is_leap_year( $start_year ) );
	$start_year++;
    }
    $leap_days;
}

# calculate the number of days before the first day of the given month
# simplified!!! (10.05.98)
sub days_until_month {
    my %days_to_month = ( "Jan", 0, "Feb", 31, "Mar", 59, "Apr", 90, "May", 120, "Jun", 151,
			  "Jul", 181, "Aug", 212, "Sep", 243, "Oct", 273, "Nov", 304, "Dec", 334 );
    my $month = shift;
    my $until = $days_to_month{ $month };
    $until++ if( is_leap_year( shift ) && ( $month ne "Jan" ) && ( $month ne "Feb" ) );
    $until;
}


sub error_level_file {
    my $error_level = shift;
### ### ###
    $error_level = 5;
### ### ###
    if( $error_level + $option_level >= 2 ) {
	$FILE = $debug ? STDOUT : STDERR;
	$infilename && print $FILE "$infilename:$.: @_\n$_" || print $FILE "@_\n";
	if( ($error_level + $option_level >= 4) && (! $check_only) ) {
	    $data_only or print "####################### erroneous data #######################\n";
	    exit 1;
	}
    }
}


# round seconds to minutes
sub minutes {
    my( $seconds ) = @_;
    my $minutes = ( ( $seconds + 30 ) - ( ( $seconds + 30 ) % 60 ) ) / 60 ;
    $minutes ? $minutes : $seconds ? 1 : 0;
}


sub interrupt_split {
    my( @rest ) = @_;
    ( $interrupt ) = @rest;
}

sub interrupt_start {
    my( $start, @rest ) = @_;				# start time, rest of input line
    if( ! $interrupt ) {
	$interrupt = $phase_name ? "unnamed" : "unknown";
    }
    $depth++;
debug "start of interrupt", $interrupt, "depth", $depth, "phased", $phase_name;
    $interrupt_rest = "@rest";
    $start_time[ $depth ] = $start;
    $event_flags[ 1 ] = 1;
}

sub interrupt_end {
    my( @rest ) = @_;					# rest of input line
    if( ! scalar @rest ) {
	@rest = split /\s+/, $interrupt_rest;
	interrupt_split( @rest );
    }
    if( ! $interrupt ) {
	$interrupt = $phase_name ? "unnamed" : "unknown";
    }
    enter_interrupt( $interrupt );
    my $duration = $normal - $start_time[ $depth ];
    $duration += 86400 if $duration < 0; 		# working late, eh?
    $interrupt_duration{ $interrupt } += $duration;
    $interrupt_count{ $interrupt }++;
    $int_duration[ $depth ] += $duration;
    $event_flags[ 1 ] = 0;
debug "end of interrupt", $interrupt, "dur", minutes( $duration ), "cum", minutes( $int_duration[ $depth ] ), "depth", $depth;
    $depth--;
}


sub defect_start {
    my( $start, @rest ) = @_;			# start time, rest of input line
    $defect_count++;
    $depth++;
debug "start of defect", $defect_count, "depth", $depth;
    $defect_number[ $depth ] = $defect_count;
    $defect_rest[ $depth ] = "@rest";
    $start_time[ $depth ] = $start;
    $event_flags[ 2 ] = 1;
}


sub defect_end {
    my( @rest ) = @_;				# rest of input line
    my $zeile;
    my $s1;
    if( ! scalar @rest ) {
	$zeile = $defect_rest[ $depth ];
    } else {
	$zeile = "@rest";
    }
    if ($zeile =~ /([^$separator]*)$separator\s*(.*)/) {
       $comment = $2;
       @classes = split( /\s+/, $1 );
    } else {
       $comment = "";
       @classes = split( /\s+/, $zeile );
    }
debug "!!$zeile!!\n$separator\n-> @classes <-> $comment <-\n";
    my $duration = $normal - $start_time[ $depth ];
#    $duration += 86400 if $duration < 0; 		# working late, eh?
    print "TIME-ERROR!\n" if $duration < 0;
    $duration -= $int_duration[ $depth + 1 ] + $defect_duration[ $depth ];
    $defect_start_number{$defect_end_count} = $defect_number[ $depth ];
    $defect_inf{$defect_end_count}{0} = $last_phase;	# remove phase
    $s1=1;
    if ($injected_class) {
	$inject = shift( @classes );
	$defect_inf{$defect_end_count}{1} = ($cum_phases && $phasename{$inject}) || $inject;	# inject phase
	enter_phase( $inject );
	$s1=2;
    }
    while( @classes ) {
	$defect_inf{$defect_end_count}{$s1} = shift( @classes );
debug "$defect_end_count / $s1: $defect_inf{$defect_end_count}{$s1}\n";
	$s1++;
    }
    $defect_duration{$defect_end_count} = $duration;
    $defect_comment{$defect_end_count} = $comment;
###
    $classifications = $s1 if ($classifications < $s1);
    $defect_end_count++;

    $int_duration[ $depth ] += $int_duration[ $depth + 1 ];
    $int_duration[ $depth + 1 ] = 0;
debug "end of defect", $defect_number[ $depth ], "depth", $depth;
    $depth--;
    $event_flags[ 2 ] = 0 if $depth == 1;
    $defect_duration[ $depth ] += $duration + $defect_duration[ $depth + 1 ];
    $defect_duration[ $depth + 1 ] = 0;
    $defect_rest[ $depth + 1 ] = 0;
}

sub phase_start {
    my( $start, $phase, $flags ) = @_;
    enter_phase( $phase ) if $flags != 2;
    $depth++;
debug "start of phase", $phase, "depth", $depth;
    $start_time[ $depth ] = $start;
    $last_phase = $phase;
    $event_flags[ 3 ] = $flags ;
}

sub phase_end {
    my( $phase ) = @_;
    enter_phase( $phase );
    my $duration = $normal - $start_time[ $depth ];
    printf "TIME-ERROR !\n" if $duration < 0;
#    $duration += 86400 if $duration < 0; 		# working late, eh? // should NOT occur (mm) ??
    $phase_duration{ $phase } += $duration - $int_duration[ $depth + 1 ];
    $phase_intervals{ $phase }++;
    $phase_first{ $phase } = $sum_time if $phase_first{ $phase } < 0;
    $sum_time += $duration - $int_duration[ $depth + 1 ];
    $phase_last{ $phase } = $sum_time ;
debug "end of phase", $phase, "dur", minutes( $duration ), "count", $phase_intervals{ $phase }, "cum", minutes( $phase_duration{ $phase } ), "int", minutes( $int_duration[ $depth + 1 ] ), "depth", $depth, "\n";
    $int_duration[ $depth + 1 ] = 0;
    $event_flags[ 3 ] = 0;
    $depth--;
}



sub enter_interrupt {
    my( $interrupt ) = @_;
    if( ! $interrupt_number{ $interrupt } ) {
	$interrupt_count++;
	$interrupt_number{ $interrupt } = $interrupt_count;
	$interrupt_name{ $interrupt_count } = $interrupt;
    }
}

sub enter_phase {
    my( $phase ) = @_;
    if( $phase ) {
	add_phase( $phase );
	if( ! $phase_first{ $phase } ) {
	    $phase_first{ $phase } = -1;
	}
debug "phase *", $phase, "*", scalar( keys %phase_number ), "*", %number_number, "*";
    }
}

sub emulate_phase {
    if( ! defined $event_flags[ 3 ] ) {			# before any phase
	error_level_file( 0, "Interpolating begin of unnamed phase" );
	phase_start( $normal, "?", 2 ); 		# emulating phase
    } elsif( ! $event_flags[ 3 ] ) {			# not in phase
	error_level_file( 0, "Interpolating begin of unnamed phase" );
	phase_start( $normal, "?", 2 ); 		# emulating phase
    }
}

sub process {
    my ($inputstream) = @_;
    my $opened;
    my( @tags, $tag );
    my( $month, $day, $time, $year, $event, @rest );
    my( $hour, $minute, $second );
    my( $phase_tag );
    my $newformat;
    my $helpstring;
    my( $shortname, $longname );

debug "tags: ", print_tags();
#    clear_options();
#    eval_options( $all_options );
debug "options: ", print_options();
    while( <$inputstream> ) {
# if line starts with comment_tag (default '#', followed by '!')
# --> interpretate line as 'definition line'
	if( /^\Q$comment_tag!\E/ ) {		   # change default tag chars
# remove newline at the and of the line
	    @tags = split;
# guess, whether new or old definition format is used:
            $newformat=0;
# first: try all new definitions:
	    if( /\bbegin=([^\n\r\t\f ;]+)/ ) {
		$newformat=1;
                $phase_start_tag = $1;
debug "New begin tag $phase_start_tag\n";
	    }
	    if( /\bend=([^\n\r\t\f ;]+)/ ) {
		$newformat=1;
                $phase_end_tag = $1;
debug "New end tag $phase_end_tag\n";
	    }	
	    if( /\bdefect=([^\n\r\t\f ;]+)/ ) {
		$newformat=1;
                $defect_tag = $1;
debug "New defect tag $defect_tag\n";
	    }	
	    if( /\binterrupt=([^\n\r\t\f ;]+)/ ){
		$newformat=1;
                $interrupt_tag = $1;
debug "New interrupt tag $interrupt_tag\n";
	    }
 	    while( /\bphase\s*=([^\n\r;]*;?)/ ) {
		$newformat=1;
debug "$&\n";
		s/$&//;
                $helpstring = $&;
		$helpstring =~ /\bphase\s*=([^\n\r;]*);?/ ;
debug "$1\n";
		( $longname, @shortnames ) = split (/=/,$1);
		$longname =~ s/\"//g;
		$phasename{$longname} = $longname;
		foreach (@shortnames) {
		    $shortname = $_;
		    $shortname =~ s/\"//g;
		    $phasename{$shortname} = $longname;
		}
	    }
	    if ( ! $newformat ) {
		while( $tag = shift @tags ) {
		    if( $tag =~ /^-(.*)/ ) {
#			eval_options( $1 );
debug "options: ", print_options();
		    }
		}
	    }
	    next;
	}
	next if /^$/ || /^[\Q$comment_tag\E \t\s]/;	# skip empty lines, comments and lines starting with spaces
# start line splitting
# CHECK HERE: NEW TIMESTAMP-FORMAT !!!
# old	( $month, $day, $time, $year, $event, @rest ) = split;
# old	( $hour, $minute, $second ) = split /:/, $time;
        ($date, $time, $event, @rest) = split;
        ($year, $month, $day) = $date =~ /(....).(..).(..)/;
        ($hour, $minute, $second) = $time =~ /(..).(..).(..)/;
# CHECK HERE: Does not work for "1998 08/17 15:16:17"        
#        print "$year\/$month\/$day  $hour, $minute, $second\n" ;

	if( length $event == 1 ) {
	    $phase_tag = $event;
	    $phase_name = shift @rest;
	    if( $phase_name =~ /\./ ) {
		( $phase_name ) = $phase_name =~ /\.([^.]*)/;
	    }
	} elsif( $event eq "end" ) {
	    $phase_tag = $phase_end_tag;
	    $phase_name = $last_phase;
	} else {
	    if( $exchange_positions ) {
		( $phase_name, $phase_tag ) = $event =~ /(.*)(.)/;
	    } else {
		( $phase_tag, $phase_name ) = $event =~ /(.)(.*)/;
	    }
	}
	interrupt_split( @rest );				# look there, too!
# end of line splitting.
	$last_event = $normal;
#	$normal = 3600 * $hour + 60 * $minute + $second;	# normalized time
	$normal = ( $year - 1995 ) * 365 + leap_days( 1995, $year ) + days_until_month( $month, $year  );
	$normal = ( ( ( $normal + $day ) * 24 + $hour ) * 60 + $minute ) * 60 + $second;
# FALSCH!!! phase_start_tag muss der ERSTE Buchstabe sein!!!!
	if( $phase_tag =~ /\Q$phase_start_tag\E/ ) {		# start of phase
	    if( ! $phase_name || $phase_name eq $interrupt_tag ) {	# start of interrupt phase
		emulate_phase();
		if( $event_flags[ 1 ] ) {			# missing end of last interrupt?
		    error_level_file( 0, "Interpolating end of interrupt" );
		    interrupt_end( @rest );
		}
		interrupt_start( $normal, @rest );
	    } elsif( $phase_name eq $defect_tag ) {	# start of defect phase
		emulate_phase();
		if( $event_flags[ 1 ] ) {
		    error_level_file( 0, "Interpolating end of interrupt" );
		    interrupt_end( @rest );
		}
		defect_start( $normal, @rest );
	    } else {						# start of normal psp phase
		if( $event_flags[ 1 ] ) {
		    error_level_file( 0, "Interpolating end of interrupt" );
		    interrupt_end( @rest );
		}
		while( $depth > 1 ) {
		    error_level_file( 0, "Interpolating end of defect" );
		    defect_end( @rest );
		}
		if( $event_flags[ 3 ] == 1 ) {
		    error_level_file( 0, "Interpolating end of phase $last_phase" );
		    phase_end( $last_phase );
		} elsif( $event_flags[ 3 ] == 2 ) {
		    error_level_file( 1, "End of unnamed phase detected" );
		    phase_end( "?" );
		}
####### LOOK HERE !!
		phase_start( $normal, ($cum_phases && $phasename{$phase_name}) || $phase_name, 1 );
#######
	    }
	} elsif( $phase_tag =~ /\Q$phase_end_tag\E/ ) {		# end of phase
	    if( ! $phase_name || $phase_name eq $interrupt_tag ) {	# end of interrupt phase
		if( $event_flags[ 1 ] ) {			# normal end of interrupt
		    interrupt_end( @rest );
		} elsif( defined $event_flags[ 3 ] ) {
		    error_level_file( 1, "Interpolating begin for unmatched end of interrupt" );
		    emulate_phase();
		    interrupt_start( $normal, @rest );
		    interrupt_end( @rest );
		} else {					# before any phase
		    error_level_file( 1, "Unmatched end of interrupt detected" );
		}
	    } elsif( $phase_name eq $defect_tag ) {	# end of defect phase
		if( $event_flags[ 1 ] ) {
		    error_level_file( 0, "Interpolating end of interrupt" );
		    interrupt_end( @rest );
		}
		if( $depth > 1 ) {				# normal end of defect
		    defect_end( @rest );
		} elsif( defined $event_flags[ 3 ] ) {
		    error_level_file( 1, "Interpolating begin for unmatched end of defect" );
		    emulate_phase();
		    defect_start( $last_event, @rest );
		    defect_end( @rest );
		} else {					# before any phase
		    error_level_file( 1, "Unmatched end of defect detected" );
		}
	    } else {						# end of normal psp phase
		$phase_name = $phasename{$phase_name} if defined($phasename{$phase_name}); ### NEW ! ! !
		if( $event_flags[ 1 ] ) {
		    error_level_file( 0, "Interpolating end of interrupt" );
		    interrupt_end( @rest );
		}
		while( $depth > 1 ) {
		    error_level_file( 0, "Interpolating end of defect" );
		    defect_end( @rest );
		}
		if( ! defined $event_flags[ 3 ] ) {
		    error_level_file( 1, "Unmatched end of phase $phase_name" );
		} elsif( $event_flags[ 3 ] == 1 ) {
debug $event_flags[ 3 ], $phase_name, $last_phase;
		    if( $phase_name eq $last_phase ) {
			phase_end( $last_phase );
		    } else {
			error_level_file( 1, "End of phase $phase_name does not match begin of phase $last_phase" );
		    }
		} elsif( $event_flags[ 3 ] == 2 ) {
		    error_level_file( 0, "Previously unnamed phase now has name $phase_name" );
		    phase_end( $phase_name );
		} else {
		    error_level_file( 1, "Interpolating begin of phase $phase_name" );
		    phase_start( $last_event, $phase_name, 2 );
		    phase_end( $phase_name );
		}
	    }
	} else {
	    error_level_file( 0, "Unknown Phase Tag $phase_tag" );
	}
    }
## TEST !!!
    debug print_tags() . "\n";
    foreach $item ( keys %special_phases_short ) {
	debug "$item :: $special_phases_short{$item} // $special_phases_long{$item}\n";
    }
##
    if( $event_flags[ 1 ] ) {
	error_level_file( 1, "Unmatched begin of interrupt" );
    }
    if( $event_flags[ 2 ] ) {
	error_level_file( 1, "Unmatched begin of defect" );
    }
    if( $event_flags[ 3 ] ) {
	error_level_file( 1, "Unmatched begin of phase $last_phase" );
    }
    $precise_flag or round_times();
}

sub round_times {
    local $loop1;
    for( $loop1 = 1; $loop1 <= scalar( keys %phase_number ); $loop1++ ) {
	$item1 = $phase_name{ $loop1 };
	$phase_duration{ $item1 } = minutes( $phase_duration{ $item1 } ) * 60;
    }
    for( $loop1 = 1; $loop1 <= scalar( keys %interrupt_number ); $loop1++ ) {
	$item1 = $interrupt_name{ $loop1 };
	$interrupt_duration{ $item1 } = minutes( $interrupt_duration{ $item1 } ) * 60;
    }
}


sub print_defect_statistics {
    local( $loop1, $loop2 );
    local( $d_nr, $d_class, $d_inject, $d_last_phase, $d_reason, $d_fix_defect, $d_comment );

# print header:
    print "$between_tables";
    $table_name = "Defects";
    $table_comment = $comment{$output_mode}{"defect_statistics"};
    $column_nr = $injected_class ? $classifications + 3 : $classifications + 4;
    $table_width = $classifications * $max_len + 40;
    @headings = $injected_class ? ("no. ","dur  ",sprintf( "%-${max_len}.${max_len}s ", "inj"),sprintf( "%-${max_len}.${max_len}s ", "rem")) : ("no. ","dur  ",sprintf( "%-${max_len}.${max_len}s ", "rem"));
    for $i ( 3 .. $classifications ) {
	push( @headings , " " x ($max_len+1) );
    }
    push( @headings , "comment");
    prepare_table();
    print "$table_begin";
# print data:
    my $first_class = $injected_class ? 2 : 1;
    for ( $loop1 = 0; $loop1 < $defect_end_count; $loop1++) {
	printf( "%3d$csep %4d", $defect_start_number{$loop1}, minutes( $defect_duration{$loop1} ));
	if ($injected_class) {
	    printf( "$csep %-${max_len}.${max_len}s", $defect_inf{$loop1}{1} );	# phase, where defect was injected
	}
	printf( "$csep %-${max_len}.${max_len}s", $defect_inf{$loop1}{0} );		# phase, where defect was removed
	for ( $loop2 = $first_class; $loop2 < $classifications; $loop2++) {
	    printf( "$csep %-${max_len}.${max_len}s", $defect_inf{$loop1}{$loop2} );
	}
	printf( " $csep  $defect_comment{$loop1} $rsep\n" );
    }
    print "$table_end";
}

sub print_phase_duration {
    local( $loop1, $item1, $sum1, $sum2, $sum3 );
    print "$between_tables";
debug scalar( keys %phase_number ), %phase_number;
    $sum1 = 0;
    for( $loop1 = 1; $loop1 <= scalar( keys %phase_number ); $loop1++ ) {
	$item1 = $phase_name{ $loop1 };
#	print "$loop1: $item1 -- $phase_duration{ $item1 }\n";
### ### ###
	$sum1 += minutes( $phase_duration{ $item1 } );
    }
    $table_name = "Duration of phases";
    $table_comment = $comment{$output_mode}{"phase_duration"};
    $column_nr = 7;
    $table_width = 54 + $max_len;
    @headings = ( sprintf( "%-${max_len}.${max_len}s ", "phase"),"interv. ","first   ","last    ","tot.dur.  ","avg.dur.  ","percent");
    prepare_table();
    print "$table_begin";
    $sum2 = 0;
    for( $loop1 = 1; $loop1 <= scalar( keys %phase_number ); $loop1++ ) {
	$item1 = $phase_name{ $loop1 };
	if( $phase_intervals{ $item1 } ) {
#	    printf( "%-8.8s$csep %4d  ", $phasename{$item1} || $item1 , $phase_intervals{ $item1 } );
	    printf( "%-${max_len}.${max_len}s$csep %4d  ", $item1 , $phase_intervals{ $item1 } );
	    $sum2 += $phase_intervals{ $item1 };
	    printf( "$csep  %4d  ",      minutes( $phase_first{ $item1 } ) );
	    printf( "$csep %4d  ",       minutes( $phase_last{ $item1 } ) );
	    printf( "$csep    %4d  ",    minutes( $phase_duration{ $item1 } ) );
	    printf( "$csep    %6.2f  ",  
                    &sdiv($phase_duration{ $item1 } / 60, $phase_intervals{ $item1 }) );
	    printf( "$csep %6.2f$rsep\n", 
                    &sdiv(100.0 * $phase_duration{ $item1 } / 60, $sum1 ) );
	}
    }
    if ( ! $data_only ) {
	print "$table_sep";
	printf ( "%-${max_len}.${max_len}s ", "total");
	printf( "${tl_e}$csep${tl_b}%4d ${tl_e}$csep $csep $csep" . " " x 18 . "${tl_b}%4d ${tl_e}$csep${tl_b}     ", $sum2, $sum1 );
	printf( "%6.2f ", &sdiv(1.0*$sum1, $sum2) );
	printf( "${tl_e}$csep${tl_b}  %6.2f${tl_e}$rsep\n", 100.0 );
	print "$table_end";
    }
}

sub print_interrupts {
    local( $loop1, $item1, $sum1, $sum2 );
    print "$between_tables";
    $table_name = "Interrupts";
    $table_comment = $comment{$output_mode}{"interrupts"};
    $column_nr = 5;
    $table_width = 38 + $max_len;
    @headings = ( sprintf ( "%-${max_len}.${max_len}s ", "name" ),"count   ","tot.dur.  ","avg.dur.  ","percent " );
    prepare_table();
    print "$table_begin";
    $sum1 = 0;
    for( $loop1 = 1; $loop1 <= scalar( keys %interrupt_number ); $loop1++ ) {
	$item1 = $interrupt_name{ $loop1 };
	$sum1 += minutes( $interrupt_duration{ $item1 } );
    }
    $sum2 = 0;
    for( $loop1 = 1; $loop1 <= scalar( keys %interrupt_number ); $loop1++ ) {
	$item1 = $interrupt_name{ $loop1 };
	printf( "%-${max_len}.${max_len}s $csep%4d  ", $item1, $interrupt_count{ $item1 } );
	$sum2 += $interrupt_count{ $item1 };
	printf( "$csep   %4d  ", minutes( $interrupt_duration{ $item1 } ) );
	printf( "$csep   %6.1f  ", 
                &sdiv($interrupt_duration{ $item1 } / 60, $interrupt_count{ $item1 }) );
	printf( "$csep   %6.2f$rsep\n", 
                &sdiv(100.0 * $interrupt_duration{ $item1 } / 60, $sum1 ) );
    }
    if ( ! $data_only ) {
	print "$table_sep";
	printf ( "%-${max_len}.${max_len}s ", "total");
	printf( "${tl_e}$csep${tl_b}%4d ${tl_e}$csep${tl_b}    %4d ${tl_e}$csep${tl_b}    %6.1f ${tl_e}$csep${tl_b}    100.00 ${tl_e}$rsep\n", $sum2, $sum1,
               &sdiv(1.0 * $sum1, $sum2) );
    }
    print "$table_end";
}


sub print_defects_by_category {
    local( $column ) = @_;
    local( $item1, $sum1 , $title );

# prepare data:
    foreach $item1 ( keys %defect_category_count ) {		# unnötig???	
	delete $defect_category_count{ $item1 };
    }
    foreach $item1 ( keys %defect_category_duration ) {		# unnötig???
	delete $defect_category_duration{ $item1 };
    }
# $defect_category_count = ();					# schneller???
    for ( $loop1 = 0; $loop1 < $defect_end_count; $loop1++) {
	$item1 = $defect_inf{$loop1}{$column};
	$defect_category_count{ $item1 } ++;
	$defect_category_duration{ $item1 } += $defect_duration{$loop1};
    }
##
    if ($injected_class) {
	$title = sprintf ("Defects (classification %d)", $column - 1);
	$title =~ s/classification -1/removal phase/;
	$title =~ s/classification 0/inject. phase/;
    } else {
	$title = sprintf ("Defects (classification %d)", $column );
	$title =~ s/classification 0/removal phase/;
    }
    for $i (1 .. $classifications) {
	$j = "classification $i";
	$title =~ s/$j/$class_names{$output_mode}{$j}/ if ($class_names{$output_mode}{$j});
    }
##

# print data:
    print "$between_tables";
    $table_name = $title;
    $table_comment = $comment{$output_mode}{"by category"};
    $column_nr = 5;
    $table_width = 35 + $max_len;
    @headings = ( sprintf ("%-${max_len}.${max_len}s ", "class"),"defects ","percent ","tot.dur.  ","avg.dur." );
    prepare_table();
    print "$table_begin";
    $sum1 = 0;
    foreach $item1 ( sort keys %defect_category_count ) {
	printf( "%-${max_len}.${max_len}s$csep %4d  ", $item1, $defect_category_count{ $item1 } );
	printf( "$csep  %6.2f", 
               &sdiv(100.0 * $defect_category_count{ $item1 }, $defect_end_count) );
	printf( "$csep   %6.2f", $defect_category_duration{ $item1 } / 60 );
	printf( "$csep   %6.2f$rsep\n", 
                &sdiv($defect_category_duration{ $item1 } / 60, $defect_category_count{ $item1 }) );
	$sum1 += $defect_category_duration{ $item1 };
    }
    $sum1 /= 60;
    if ( ! $data_only ) {
	print "$table_sep";
	printf ( "%-${max_len}.${max_len}s ", "total");
	printf( "${tl_e}$csep${tl_b}%4d  ${tl_e}$csep${tl_b}  100.00${tl_e}$csep${tl_b}   %6.2f${tl_e}$csep${tl_b}   %6.2f ${tl_e}$rsep\n", $defect_end_count, $sum1, &sdiv($sum1, $defect_end_count) );
    }
    print "$table_end";
}

sub print_defect_removal_ef {
    local( $loop1, $item1, $sum1, $sum2, $sum3, $sum4 );
    $injected_class || die "Insufficient data for removal efficiency!\n"; 
# prepare data:
    foreach $item1 (keys %defect_inject_count ) {
	delete $defect_inject_count{ $item1 };
#	print "Deleting...\n";
    }
    foreach $item1 (keys %defect_remove_count ) {
	delete $defect_remove_count{ $item1 };
#	print "Deleting...\n";
    }
    foreach $item1 (keys %defect_remove_duration ) {
	delete $defect_remove_duration{ $item1 };
#	print "Deleting...\n";
    }
    for ( $loop1 = 0; $loop1 < $defect_end_count; $loop1++) {
	$defect_inject_count{ $defect_inf{$loop1}{1} } ++;
	$defect_remove_count{ $defect_inf{$loop1}{0} } ++;
	$defect_remove_duration{ $defect_inf{$loop1}{0} } += $defect_duration{ $loop1 };
    }
    
# print data:
    print "$between_tables";
    $table_name = "Defect removal efficiency";
    $table_comment = $comment{$output_mode}{"removal eff"};
    $column_nr = 7;
    $table_width = 50 + $max_len;
    @headings = ( sprintf ( "%-${max_len}.${max_len}s ", "phase"),"inject  ","present  ","remove  ","escape   ","yield  ","def./h" );
    prepare_table();
    print "$table_begin";
    $sum1 = 0;
    $sum2 = 0;
    for( $loop1 = 1; $loop1 <= scalar( keys %phase_number ); $loop1++ ) {
	$item1 = $phase_name{ $loop1 };
        # only, if phase has not lenght 0
	if( $phase_intervals{ $item1 } ) {
	    printf( "%-${max_len}.${max_len}s$csep %4d", $item1, $defect_inject_count{ $item1 } );  # phase, inject
	    $sum2 += $defect_inject_count{ $item1 };
	    printf( "  $csep   %4d", $sum2 );						# present
	    printf( "  $csep  %4d", $defect_remove_count{ $item1 } );			# remove
	    printf( "  $csep  %4d", $sum2 - $defect_remove_count{ $item1 } );		# escape
	    printf( "$csep    %6.2f ", 
               &sdiv(100.0 * $defect_remove_count{ $item1 }, $sum2) );# yield
	    $sum2 -= $defect_remove_count{ $item1 };
	    printf( "$csep %6.2f $rsep\n", 
               &sdiv(3600.0 * $defect_remove_count{ $item1 },
                     $phase_duration{ $item1 }) );		# defects/hour
	    $sum1 += $phase_duration{ $item1 };
	    if ( $sum2 < 0 ) {
### critical: sometimes, there will be no filename available!!!
		print "Error in '$infilename': Defect removed before injected or wrong phase name given\n";
###
	    }
	}
    }
    $sum3 = 0;
    $sum4 = 0;
    if ( ! $data_only ) {
	print "$table_sep";
	printf ( "%-${max_len}.${max_len}s ", "total");
	printf( "${tl_e}$csep${tl_b}%4d  ${tl_e}$csep${tl_b}   %4d  ",
               $defect_count, $sum2 );	# inject, present
	printf( "${tl_e}$csep${tl_b}  %4d  ${tl_e}$csep${tl_b}  %4d",
               $defect_count, 0 );	# remove, escape
	printf( "${tl_e}$csep           $csep${tl_b} %6.2f${tl_e}$rsep\n", 
               &sdiv(3600.0 * $defect_count, $sum1) );	# defects/hour
	print "$table_end";
    }
}


#################################################################################################### BIS HIER ##########

sub prepare_cross_relation {
    local ( $col1, $col2 ) = @_;
    local ( $item1, $item2, $duration1 );
# clear all arrays
    foreach $item1 ( keys %cross_count ) {
	delete $cross_count{$item1};
    }
    foreach $item1 ( keys %cross_duration ) {
	delete $cross_duration{$item1};
    }
    foreach $item1 ( keys %column_name ) {
	delete $column_name{$item1};
    }
    foreach $item1 ( keys %row_name ) {
	delete $row_name{$item1};
    }
    delete $sum_count{"row"};
    delete $sum_count{"column"};
    delete $sum_duration{"row"};
    delete $sum_duration{"column"};
    $total_duration = 0;
# calculate new values
    for ( $loop1 = 0; $loop1 < $defect_end_count; $loop1++) {
	$item1 = $defect_inf{$loop1}{$col1};
	$item2 = $defect_inf{$loop1}{$col2};
	$column_name{ $item1 } = 1;
	$row_name{ $item2 } = 1;
	$duration1 = $defect_duration{ $loop1 } / 60;
	$cross_count{$item1}{$item2} ++;
	$cross_duration{$item1}{$item2} += $duration1;
	$sum_count{"column"}{$item1}++;
	$sum_count{"row"}{$item2}++;
	$sum_duration{"column"}{$item1} += $duration1;
	$sum_duration{"row"}{$item2} += $duration1;
# a little slow ...
 	$cross_avg_duration{$item1}{$item2} = 
          &sdiv($cross_duration{$item1}{$item2}, $cross_count{$item1}{$item2});
	$sum_avg_duration{"column"}{$item1} = 
          &sdiv($sum_duration{"column"}{$item1}, $sum_count{"column"}{$item1});
	$sum_avg_duration{"row"}{$item2} = 
          &sdiv($sum_duration{"row"}{$item2}, $sum_count{"row"}{$item2});
	$total_duration += $duration1;
    }
    $total{"Total duration"} = $total_duration;
    $total{"Average duration"} = &sdiv($total_duration, $defect_end_count);
    $total{"Percentage"} = 100.00;
    $total{"Number"} = $defect_end_count;
 
    if ($injected_class) {
	$title = sprintf ("classification %d and classification %d", $col1 - 1, $col2 - 1);
	$title =~ s/classification -1/removal phase/;
	$title =~ s/classification 0/inject. phase/;
    } else {
	$title = sprintf ("classification %d and classification %d", $col1 , $col2 );
	$title =~ s/classification 0/removal phase/;
    }
    for $i (1 .. $classifications) {
	$j = "classification $i";
	$title =~ s/$j/$class_names{$output_mode}{$j}/ if ($class_names{$output_mode}{$j});
    }
    ( $col_title, $prt ) = split(/ and /, $title);
    @lists = split(/\s+/, $prt);
    $row_title1 = shift(@lists);
    $row_title2 = join(" ",@lists);
}

sub print_cross_relation {
    local( $type ) = @_; # "Total duration", "Average duration" "Percentage", "Number" are allowed
    local( $loop1, $loop2, $item1, $item2 );

    print "$between_tables";
#    my $column_nr = scalar( keys %column_name );
    my $format = ($type eq "Number") ? " %" . ($max_len - 3) ."d  " : "%" . $max_len . ".1f";
    my $factor = ($type eq "Percentage") ? &sdiv(100.0, $defect_end_count) : 1;
    if ($type =~ "Average") {
	%cross_data = %cross_avg_duration;
	%sum_data   = %sum_avg_duration;
    } elsif ($type =~ "Total") {
	%cross_data = %cross_duration;
	%sum_data   = %sum_duration;
    } else {
	%cross_data = %cross_count;
	%sum_data   = %sum_count;
    }
    print( "\n" );
    $table_name = "$type of defects by $title";
    $table_comment = $comment{$output_mode}{"cross"}{$type};
    $column_nr = scalar( keys %column_name ) + 2;
    $table_width = $column_nr * ($max_len+1) + 1;
    @headings = ( sprintf ( "%-${max_len}.${max_len}s ", " ") );
    foreach $item1 ( keys %column_name ) {
	push (@headings, sprintf( "%-${max_len}.${max_len}s ", $item1 ));
    }
    push (@headings, "   total");
    prepare_table();
    print "$table_begin";
    foreach $item2 ( keys %row_name ) {
	printf( "%-${max_len}.${max_len}s", $item2 );
	foreach $item1 ( keys %column_name ) {
	    if( $cross_count{ $item1 }{ $item2 } ) {
		printf( "$csep$format ", $cross_data{ $item1 }{ $item2 } * $factor);
	    } else {
		printf( "$csep$format ", 0 );
	    }
	}
	$data_only or printf( "$lcsep$format ", $sum_data{"row"}{ $item2 } * $factor);
	print( "$rsep\n" );
    }
    if ( ! $data_only ) {
	print "$table_sep";
	printf ( "%-${max_len}.${max_len}s", "total");
	foreach $item2 ( keys %column_name ) {
	    if( defined $sum_count{"column"}{ $item2 } ) {
		printf( "${tl_e}$csep${tl_b}$format ", $sum_data{"column"}{ $item2 } * $factor);
	    } else {
		printf( "${tl_e}$csep${tl_b}$format ", 0 );
	    }
	}
	printf( "${tl_e}$lcsep${tl_b}$format ${tl_e}$rsep\n", $total{$type});
    }
    print "$table_end";
}

sub cross_relation {
    local ( $param1 , $param2 ) = @_;
    ($s_3dt || $s_3dn) && print "$between_paragraphs";
    prepare_cross_relation( $param1 , $param2 );
    $s_3dn && print_cross_relation("Percentage");
    $s_3dn && print_cross_relation("Number");
    $s_3dt && print_cross_relation("Total duration");
    $s_3dt && print_cross_relation("Average duration");
}    

sub print_out {
    my $loop1;
    print "$document_header";
    $precise_flag || round_times();
    ($all || $s_1d) && %phase_duration && print_phase_duration();
    if (($all || $s_1d) && %interrupt_duration) {
	print "$between_paragraphs";
	print_interrupts();
    }
    if ($all || $s_2d) {
	print "$between_paragraphs";
	for( $loop1=0 ; $loop1 < $classifications ; $loop1++ ) {
	    print_defects_by_category( $loop1 );
	}
	if ($injected_class) {
	    print "$between_paragraphs";
	    print_defect_removal_ef();
	}
    }
    if ($all || $s_3d) {
	if ( $injected_class ) {
	    cross_relation ( 0 , 1 );
	    for $i ( 2 .. ($classifications - 1 )) {
		cross_relation ( 0 , $i );
		cross_relation ( 1 , $i );
	    }
	} else {
	    for $i ( 1 .. ($classifications - 2 )) {
		cross_relation ( 0 , $i );
	    }
	}
    }
    $s_dl && print_defect_statistics();
    print "$document_ending";
}

sub clear_data {
    my $item;
    $header = 0;
    $sum_time = 0;
    $depth = 0;
    $interrupt_count = 0;
    $phase_count = 0;

    foreach $item ( keys %start_time ) {
	delete $start_time{ $item };
    }
    foreach $item ( keys %event_flags ) {
	delete $event_flags{ $item };
    }
    foreach $item ( keys %int_duration ) {
	delete $int_duration{ $item };
    }
    foreach $item ( keys %interrupt_number ) {
	delete $interrupt_number{ $item };
    }
    foreach $item ( keys %interrupt_name ) {
	delete $interrupt_name{ $item };
    }
    foreach $item ( keys %interrupt_duration ) {
	delete $interrupt_duration{ $item };
    }
    foreach $item ( keys %interrupt_count ) {
	delete $interrupt_count{ $item };
    }
    foreach $item ( keys %defect_number ) {
	delete $defect_number{ $item };
    }
    foreach $item ( keys %defect_duration ) {
	delete $defect_duration{ $item };
    }
    foreach $item ( keys %defect_rest ) {
	delete $defect_rest{ $item };
    }
    foreach $item ( keys %phase_number ) {
	delete $phase_number{ $item };
    }
    foreach $item ( keys %phase_name ) {
	delete $phase_name{ $item };
    }
    foreach $item ( keys %phase_duration ) {
	delete $phase_duration{ $item };
    }
    foreach $item ( keys %phase_intervals ) {
	delete $phase_intervals{ $item };
    }
    foreach $item ( keys %phase_first ) {
	delete $phase_first{ $item };
    }
    foreach $item ( keys %phase_last ) {
	delete $phase_last{ $item };
    }
    foreach $item ( keys %defect_inject_count ) {
	delete $defect_inject_count{ $item };
    }
    foreach $item ( keys %defect_remove_count ) {
	delete $defect_remove_count{ $item };
    }
    foreach $item ( keys %defect_inject_duration ) {
	delete $defect_inject_duration{ $item };
    }
    foreach $item ( keys %defect_remove_duration ) {
	delete $defect_remove_duration{ $item };
    }
}


sub add_phase {
    my $phase = shift;
    if ( ! $phase_number{ $phase } ) {
	$phase_count++;
debug "Adding phase $phase as #$phase_count\n";
	$phase_number{ $phase } = $phase_count;
	$phase_name{ $phase_count } = $phase;
    }
}

sub print_tags {
    my $result;
    $result = "c$comment_tag s$phase_start_tag e$phase_end_tag i$interrupt_tag x$defect_tag:" . 
	     join( '', @order );
    return $result;
}



sub eval_option {
    my( $options ) = @_;

    $old_level = $option_level;
    while( $options ) {
	if( $options =~ /^f (.*)$/ ) {
# only variables that do not change are initialised here
# all other variables are set by "prepare table", which must be called 
# after setting the status variables
	    if ($1 eq "raw") {
		$output_mode = "raw";
		$document_header = "";
		$document_ending = "";
		$between_paragraphs = "\n\n";
		$between_tables = "\n";
		$csep = "";
		$lcsep = "";
		$rsep = "\n";
	    } elsif ( $1 eq "std" ) {
		# do nothing
	    } elsif ( $1 eq "tex" ) {
		$output_mode = "tex";
		$document_header = <<"EndOfHeader";
\\documentclass[11pt,oneside]{report}

\\begin{document}

\\title{Analysis of pplog-files.}

EndOfHeader
		$document_ending = "\\end{document}\n";
		$between_paragraphs = "\n\n";
		$between_tables = "\n";
		$csep = " &";
		$lcsep = " &";
		$rsep = "\\\\\n";
	    } elsif ( $1 eq "html") {
		$output_mode = "html";
		$document_header = <<"EndOfHeader";
<HTML>
<HEAD>
<META NAME="Author" CONTENT="evalpplog">
<META NAME="Description" CONTENT="Tables resulting from an analysis of pplog-files">
<TITLE>evalpplog output</TITLE>
</HEAD>
<BODY>
EndOfHeader
		$document_ending = "</BODY>\n</HTML>\n";
		$between_paragraphs = "\n<P>\n<HR WIDTH=\"100%\">\n<P>";
		$between_tables = "\n<P>\n";
                # column separator - to be put between two columns
		$csep = "</CENTER></TD><TD><CENTER>";
                # separator for last column - instead of $csep 
		$lcsep = "</CENTER></TD><TD><CENTER>";
                # row separator - to be put between two rows
		$rsep = "</CENTER></TD></TR>\n<TR><TD>";
	    } else {
		print "Unknown mode: $1\n";
		exit(1);
	    }
	    $options =~ s/^f \Q$1\E//;
	    next;
	}
	if( $options =~ /^m ([0-9]+)/ ) {
	    $max_len = $1 if ($1);
	    $options =~ s/^m \Q$1\E//;
	    next;
	}
	if( $options =~ /-$/ ){
	    $all_options .= "-";
	    chop $options;
	    next;
	}
	if ($options =~ /[h\?]$/) {
	    print "Usage: evalpplog [options] <files...>\n";
	    print "Options are:\n";
	    print "--   read filenames only from STDIN\n";
	    print "-?   print this info page and exit\n";
	    print "-a   print only advanced statistics\n";
	    print "-b   print only basic statistics\n";
	    print "-c   check for erroneous data only, no output\n";
	    print "-d   print defect data only, no statistics\n";
#	    print "-g   print debugging info (implies -2)\n";
	    print "-h   print this info page and exit\n";
	    print "-i   DON'T interpretate first defect class as injection phase\n";
	    print "-m # set maximum width of phase names and classes to # (default: 8)\n";
	    print "-n   DON'T print advanced statistics about number and percentage of defects\n";
	    print "-p   do precise calculations (based on seconds)\n";
	    print "-s   print statistics only, no defect data\n";
	    print "-t   DON'T print advanced statistics about defect duration\n";
	    print "-0   print no warnings (results may be incorrect)\n";
	    print "-1   print warnings on severe errors (default)\n";
	    print "-2   print all warnings\n";
	    print "-3   print all warnings, die if severe errors encountered\n";
	    print "-4   die if any errors encountered\n";
	    print "-f raw|std|tex|html   format of output data\n";
	    exit;
	}
	if( $options =~ /([0-4])$/ ) {
	    $option_level = $1;
	    chop $options;
	    next;
	}
	if( $options =~ /(p)$/ ) {
	    $precise_flag = $1;
	    chop $options;
	    next;
	}
	if( $options =~ /(s)$/ ) {
	    $stats_only = $1;
	    chop $options;
	    next;
	}
	if( $options =~ /([abcd])$/ ) {
	    $all = 0;
	}
	if( $options =~ /([abc])$/ ) {	
	    $s_dl = 0;
	}
	if( $options =~ /([cs])$/ ) {
	    $s_dl = 0;
	    chop $options;
	    next;
	}
	if( $options =~ /(d)$/ ) {
#	    $s_1d = 1;
	    chop $options;
	    next;
	}
	if( $options =~ /(b)$/ ) {
	    $s_2d = 1;
	    chop $options;
	    next;
	}
	if( $options =~ /(a)$/ ) {
	    $s_3d = 1;
	    chop $options;
	    next;
	}
	if( $options =~ /(t)$/ ) {
	    $s_3dt = 0;
	    chop $options;
	    next;
	}
	if( $options =~ /(n)$/ ) {
	    $s_3dn = 0;
	    chop $options;
	    next;
	}
	if( $options =~ /(i)$/ ) {
	    $injected_class = 0;
	    chop $options;
	    next;
	}
	if( $options =~ /(.)$/ ) {
	    print "Unknown option \'$1\'. Type \"evalpplog -h\" for help.\n";
	    exit (2);
	    chop $options;
	}
    }
}

sub clear_options {
    $precise_flag = 0;
    $merge_flag = 0;
    $check_only = 0;
    $defects_only = 0;
    $stats_only = 0;
    $option_level = 0;
    $data_only = 0;
    $interrupt_flag = 0;
    $exchange_positions = 0;
    $option_level = $old_level;
    $debug &= ~ 2;
}

sub print_options {
    my $result;
    $result .= $option_level;
    $result .= "p" if $precise_flag;
    $result .= "c" if $check_only;
    $result .= "e" if $defects_only;
    $result .= "s" if $stats_only;
    $result .= "d" if $data_only;
    $result .= "g" if $debug & 2;
    $result .= "i" if $interrupt_flag;
    $result .= "l" if $tex_mode;
    return $result;
}

sub sdiv {
   # &sdiv(a,b)  safe division, returns 0 if b==0
   return ($_[1] == 0 ? 0 : $_[0]/$_[1]);
}

################################# MAIN ##############################

clear_options();
while( $#ARGV >= 0 and $ARGV[ 0 ] =~ /^-/ ) {
    $options = shift;
    ( $tags ) = $options =~ /^-(.*)/;
    if (($tags =~ /m/) || ($tags =~ /f/)) {
	eval_option( $tags . " " . shift );
    } else {
	eval_option( $tags );
    }
}

if( $all_options =~ /-/ ) {
    while( <> ) {
	@filenames = split /\s+/, $_;
	while( $infilename = shift @filenames ) {
	    print "Directory \'$infilename\' cannot be processed!\n" and exit(1) if ( -d $infilename );
	    open (INFILE, "<$infilename") or error_level_file( 1, "Can't open input file $infilename" );
	    process( INFILE );
	    close INFILE;
	}
    }
} elsif( $#ARGV >= 0 ) {
    while( $#ARGV >= 0 ) {
	$infilename = shift;
	print "Directory \'$infilename\' cannot be processed!\n" and exit(1) if ( -d $infilename );
	open (INFILE, "<$infilename") or error_level_file( 1, "Can't open input file $infilename" );
	process( INFILE );
	close INFILE;
    }
} else {
    process( STDIN );
}
$check_only or $defects_only or print_out();


# global vars
#     local( $class, $inject );		# defect class, inject phase
#     local( $reason, $fix_defect );	# defect reason, fix defect
#     local( $last_event, $normal );	# timestamp of last event found, timestamp of this event
#     local $header;			# true if defect header printed
#     local $sum_time;			# sum of time spent in psp phases
#     local %start_time;		# time of event start per nesting level
#     local %event_flags;		# flags for unfinished events
#     local $depth;			# defect/interrupt nesting depth
#     local %int_duration;		# cumulative duration of interrupts per nesting level
#     local $interrupt_count;		# number of different interrupts encountered so far
#     local %interrupt_number;		# number of interrupt by name
#     local %interrupt_name;		# name of interrupt by number
#     local %interrupt_duration;	# cumulative duration of named interrupts
#     local $interrupt_rest;		# rest of input line after interrupt tag
#     local %interrupt_count;		# repetitions of named interrupts
#     local $defect_count;		# number of defects encountered so far
#     local %defect_number;		# numbers of nested defects
#     local %defect_duration;		# cumulative duration of defects per nesting level
#     local %defect_rest;		# rest of input line after defect tag per nesting level
#     local $phase_count;		# number of phases encountered so far
#     local %phase_number;		# number of phase by name
#     local %phase_name;		# name of phase by number
#     local %phase_duration;		# cumulative duration of pplog phases
#     local %phase_intervals;		# number of intervals per phase
#     local %phase_first;		# first beginning of phase
#     local %phase_last;		# last end of phase
#     local %defect_inject_count;	# number of defects injected in phase
#     local %defect_remove_count;	# number of defects removed in phase
#     local %defect_inject_duration;	# cumulative duration of defects injected in phase
#     local %defect_remove_duration;	# cumulative duration of defects removed in phase



#$all = 1;
#$s_1d = 0;
#$s_2d = 0;
#$s_3d = 0;
#$s_3dt = 1;
#$s_3dn = 1;
#$s_dl = 1;

######################################################################
.00;			# finish .ig

'di			\" finish diversion--previous line must be blank
.nr nl 0-1		\" fake up transition to first page again
.nr % 0			\" start at page 1
'; __END__ ############# From here on it's a standard manual page ####
.de XX
.ds XX \\$4\ (v\\$3)
..
.XX $Id: evalpplog,v 1.8 1999/10/15 13:25:56 exp Exp $
.TH EVALPPLOG 1 \*(XX
.SH NAME
evalpplog \- evaluate personal process logs (time and defect logs)
.SH SYNOPSIS
.nr ww \w'\fBevalpplog\fP\ '
.in +\n(wwu
.ta \n(wwu
.ti -\n(wwu
\fBevalpplog\fP	\c
[-\fB01234\fP] [-\fB?\fP] [-\fBh\fP] [-\fBabcds\fP] [-\fBp\fP] [-\fBi\fP] [-\fBnt\fP]
[-\fBm\fP \fIwidth\fP] [-\fBf\fP {\fBraw\fP|\fBstd\fP|\fBtex\fP|\fBhtml\fP}]
[-- | \fIfile\fP ...]
.SH DESCRIPTION
.I evalpplog
reads log files and outputs defect and interrupt listings
and some statistics. If more than one file is given, the input
data is treated as if all files were concatenated.
.PP
The lines in the log files may be \fIevent entries\fP, \fIextended entries\fP
or \fIcomments\fP.
The exact format of \fIevent entries\fP is described in the following section.
Empty lines and lines that start with whitespaces (tabs or spaces) are considered
\fIextended entries\fP. These lines are ignored during evaluation.
Lines with a special tag ('#' as default) as the first characters on a line,
are recognised as \fIcomments\fP.
Lines with any other format are invalid.

.SH ENTRY FORMAT
\fIEvent entries\fP consist of a timestamp followed by tags describing the event. Tags are separated from each other by
whitespaces, i.e. by blanks or tabs. The format of the timestamps has to match
that of the timestamps in the examples below. The \fIfirst tag\fP following the
timestamp describes the type of event. The first character of this tag specifies
whether the event starts ('b') or ends ('e'). The remaining characters may be the
defect tag ('e'), the interruption tag ('i') or any other sequence of non-whitespace
characters, which will be interpreted as a phase name. Unlike in older versions of
evalpplog (called evalpsp) there are no default phase names, because all phases are treated the same.

The interpretation of subsequent tags - \fIthe classification tags\fP - depends
on the type of event.
.IP
Phase entries: All classification tags will be ignored.
.nf

Jan 25 11:29:10 1998 bds This text will be ignored.
Jan 25 12:12:52 1998 eds Ignored, too.

.fi
.IP
Interrupt entries: Interrupts may be divided into classes using the first
classification tag. All other classification tags will be ignored. If there
are different tags at the begin entry and the end entry, the tags of the end
entry will be used.
.nf

Jan 25 11:35:10 1996 bi phone_call (Peter)
Jan 25 11:38:10 1996 ei

.fi
This entry will be interpreted as an interrupt of type 'phone_call'. '(Peter)' is
ignored.
.nf

Jan 25 11:35:10 1996 bi phone call (Peter)
Jan 25 11:38:10 1996 ei

.fi
This entry will be interpreted as an interrupt of type 'phone'. 
The subsequent 'call (Peter)' is ignored.

.IP
Defects entries: Defects may be divided into classes using any number of classification
tags. A comment that is not to be interpreted may be added behind a separator char, '#'
being the default. During evaluation, all tags at the same position are considered to
belong to the same classification category. By default, the first classification category
represents the defect injection phase.
.nf

Jan 25 13:00:00 1995 be
Jan 25 13:02:00 1995 ee pl 30 - Com1
Jan 25 13:03:00 1995 be
Jan 25 13:08:00 1995 ee cd 20 - Com2
Jan 25 13:09:00 1995 be
Jan 25 13:14:00 1995 ee pl 20 - Com3

.fi
This example shows 3 defect entries with 2 classification categories. The classification
tags 'pl' and 'cd' belong to category I, '20' and '30' to category II.
You may choose classification categories and their individual entries in 
whichever way suits you, just use them consistently. You must not vary
the number of classification categories within one input file.

.PP
All events that are started must be ended. Interruptions must end before any other
entry. New phases can only start when all previous phases, defects and interruptions
are ended. Phases may not overlap; missing start or end entries are interpolated
whenever unambiguously possible. Only defect entries may be nested.
.PP

.SH OPTIONS
.IP "\-h, \-?"
Display about one screenfull of options, then exit.
.IP "\-0, \-1, \-2, \-3, \-4"
This sets the "error sensitivity level" of \fIevalpplog\fP.
Errors are missing or unrecognized tags, for example.
.br
   -0  Print no warnings or errors at all. The results may be incorrect!
.br
   -1  Print warnings on severe errors only. This is the default.
.br
   -2  Print all errors and warnings.
.br
   -3  Print all errors and warnings, die if severe errors are encountered.
       Use this option to safe-check your data.
.br
   -4  Die if any errors are encountered.
.IP \-a
Print only advanced statistics, i.e. statistics showing relations
between different defect classification categogies.
.IP \-b
Print only basic statistics, i.e. statistics showing data for one
single classification category.
.IP \-c
Check for erroneous data only, don\'t output anything. Useful only 
in combination with -[2-4].
.IP \-d
Print defect data only, no statistics.
.IP \-s
Print statistics only, no defect data.
.IP \-p
Do precise calculations (based on seconds).
.IP \-i
DON\'T interpretate first defect classification tag as injection phase.
By default, the first defect classification category is considered to describe
the phase where the defect was injected.
.IP \-n
DON\'T print advanced statistics about number and percentage of defects.
.IP \-t
DON\'T print advanced statistics about defect duration.
.IP \-m width
Truncate phase names and classes to \'width\' characters when printing (default: 8).
.IP \-f raw|std|tex|html
Select output format: RAW data, STanDard text format, laTEX format or HTML.
.IP \-\-
Read a list of whitespace-delimited input filenames from STDIN and
open these files for input. This may be helpful if you want to keep a
list of files in order to evaluate them all at once.

.SH CUSTOMISATION
\fIevalpplog\fP offers the possibility to add comments to any output table
and to replace the automatically assigned classification category names by
useful names. Just have a look on the first source code lines.

.SH RELATED COMMANDS
There is an \fIemacs\fP major-mode named \fIpplog-mode\fP which 
configures \fIemacs\fP to enter timestamps into a special 
log buffer upon pressing a specified key. These timestamps 
may then be decorated with phase tags and later on evaluated 
by \fIevalpplog\fP.

.SH AUTHORS
Oliver Gramberg <gramberg@ira.uka.de> (first version: evalpsp)
Markus Middendorf <markusm@writeme.com> (this version)
Lutz Prechelt <prechelt@computer.org> (corrections)
.br
Softwarelabor Karlsruhe
.SH "SEE ALSO"
perl(1), emacs(1), pplog-mode.el, http://wwwipd.ira.uka.de/PSP/
.SH BUGS
Because \fIevalpplog\fP interpolates ends of interrupt or defect removal
phases, at the time being you cannot decide to stop working on a
defect, end the enclosing phase, and restart both on Monday next
week. This is not very convenient, but can be worked around
by introducing a (possibly named?) interrupt instead.
.PP
Missing data may result in a "division by zero" error
when calculating averages.
.PP
Some characters have a special meaning in TEX or HTML and must be suitably
quoted to appear correctly. Better avoid these characters altogether.
.ex
