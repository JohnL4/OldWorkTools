#!C:\perl\bin\perl.exe

# Clean Columus data

# cleans name and phone numbers

BEGIN { die "usage: ColClean2.pl <filename>" unless @ARGV==1; }

$infile = @ARGV[0];

open(inHANDLE, "<$infile") or die "Cannot open $infile | $!";

$infile =~ s/\..*/\.cln/;

while(<inHANDLE>) {
    /^\s*$/ && next;
    printf ".";
    chomp;
    s/[\r\n]//g;
	@buffer = split/[\n\r]+/;
	
	foreach $buffer (@buffer) {
		@cols = split/\t/,$buffer;
		push @lines, [ @cols ];
	}
}
printf "\n";

close(inHANDLE);

open(outHANDLE,">$infile");

foreach $line (@lines) {
	
	foreach $col (@$line) {
		
		$col = tidy($col);
                if ($col =~ m/[\r\n]/) {
                    printf "?";
                }
		print outHANDLE "$col \t";
	}
	print outHANDLE "\n";
}
close(outHANDLE);



sub tidy(){
    my $field = $_[0];
    # Remove single quote from middle of field
    $field =~ s/(.*?)\'(.*?)/$1$2/s;
    # Remove double quotes from ends of field
    $field =~ s/\"(.*?)\"/$1/s;
    chomp $field;
    return $field;
}
