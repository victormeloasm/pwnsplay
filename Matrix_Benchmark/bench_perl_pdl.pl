use strict;
use warnings;
use Time::HiRes qw(time);

eval {
    require PDL;
    PDL->import();
    require PDL::Primitive;
};
if ($@) {
    print "language Perl PDL ecosystem\n";
    print "missing PDL. Install with: sudo apt install libpdl-perl\n";
    exit 0;
}

my $N = 1000;
my $i = sequence($N)->dummy(1, $N);
my $j = sequence($N)->dummy(0, $N);
my $A = (($i * 131 + $j * 17 + 13) % 1000) * 0.001 - 0.5;
my $B = (($i * 19 + $j * 137 + 7) % 1000) * 0.001 - 0.5;

my $t0 = time();
my $C = $B x $A;
my $t1 = time();

my $chk = 0.0;
for (my $idx = 0; $idx < $N*$N; $idx += 97) {
    my $row = int($idx / $N);
    my $col = $idx % $N;
    $chk += $C->at($row, $col);
}

print "language Perl PDL ecosystem\n";
printf "time_ms %.6f\n", ($t1 - $t0) * 1000.0;
printf "checksum %.17g\n", $chk;
