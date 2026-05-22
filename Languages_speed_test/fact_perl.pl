#!/usr/bin/env perl
use strict;
use warnings;
use Time::HiRes qw(time);
use Math::BigInt try => 'GMP';

my $n = shift @ARGV // 99999;

sub trailing_zeroes {
    my ($x) = @_;
    my $z = 0;
    while ($x > 0) { $x = int($x / 5); $z += $x; }
    return $z;
}

# Optimized for factorial-like products:
# 1) multiply as much as safely possible with native Perl integers
# 2) convert only those packed chunks to Math::BigInt
# 3) reduce the chunks with a balanced product tree
# This avoids tens of thousands of expensive BigInt object multiplications.
sub make_native_chunks {
    my ($limit) = @_;
    my @chunks;
    my $acc = 1;
    my $max = ~0;              # native unsigned max-ish
    $max = int($max / 4);      # conservative guard against signed/IV weirdness

    for (my $i = 1; $i <= $limit; ++$i) {
        if ($acc > int($max / $i)) {
            push @chunks, $acc;
            $acc = $i;
        } else {
            $acc *= $i;
        }
    }
    push @chunks, $acc if $acc != 1 || !@chunks;
    return \@chunks;
}

sub prod_tree_chunks {
    my ($chunks, $lo, $hi) = @_;
    return Math::BigInt->bone() if $lo >= $hi;
    return Math::BigInt->new($chunks->[$lo]) if $hi - $lo == 1;

    if ($hi - $lo <= 24) {
        my $r = Math::BigInt->bone();
        for (my $i = $lo; $i < $hi; ++$i) {
            $r->bmul($chunks->[$i]);
        }
        return $r;
    }

    my $mid = int($lo + ($hi - $lo) / 2);
    my $left  = prod_tree_chunks($chunks, $lo, $mid);
    my $right = prod_tree_chunks($chunks, $mid, $hi);
    return $left->bmul($right);
}

my $t0 = time();
my $chunks = make_native_chunks($n);
my $f = prod_tree_chunks($chunks, 0, scalar(@$chunks));
my $t1 = time();
my $lib = Math::BigInt->config()->{lib} // 'pure-perl';
printf "Perl|%.3f|%d|%d|packed native chunks + BigInt tree (%s, %d chunks)\n",
    ($t1-$t0)*1000.0, length($f->bstr()), trailing_zeroes($n), $lib, scalar(@$chunks);
