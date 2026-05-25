use strict;
use warnings;
use Time::HiRes qw(time);

use constant N => 1000;
use constant BS => 32;

sub aval {
    my ($i, $j) = @_;
    return (($i * 131 + $j * 17 + 13) % 1000) * 0.001 - 0.5;
}

sub bval {
    my ($i, $j) = @_;
    return (($i * 19 + $j * 137 + 7) % 1000) * 0.001 - 0.5;
}

my @A = (0.0) x (N*N);
my @BT = (0.0) x (N*N);
my @C = (0.0) x (N*N);

for my $i (0..N-1) {
    for my $j (0..N-1) {
        $A[$i*N+$j] = aval($i,$j);
        $BT[$j*N+$i] = bval($i,$j);
    }
}

my $t0 = time();

for (my $ii = 0; $ii < N; $ii += BS) {
    my $iimax = $ii + BS < N ? $ii + BS : N;
    for (my $jj = 0; $jj < N; $jj += BS) {
        my $jjmax = $jj + BS < N ? $jj + BS : N;
        for (my $i = $ii; $i < $iimax; $i++) {
            my $abase = $i*N;
            for (my $j = $jj; $j < $jjmax; $j++) {
                my $bbase = $j*N;
                my $s = 0.0;
                for (my $k = 0; $k < N; $k++) {
                    $s += $A[$abase+$k] * $BT[$bbase+$k];
                }
                $C[$abase+$j] = $s;
            }
        }
    }
}

my $t1 = time();

my $chk = 0.0;
for (my $idx = 0; $idx < N*N; $idx += 97) {
    $chk += $C[$idx];
}

print "language Perl pure\n";
printf "time_ms %.6f\n", ($t1 - $t0) * 1000.0;
printf "checksum %.17g\n", $chk;
