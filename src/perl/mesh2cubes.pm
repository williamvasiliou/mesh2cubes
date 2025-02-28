package mesh2cubes;

use strict;
use warnings;

use POSIX qw(ceil floor fmin);

use Exporter 5.57 'import';
our @EXPORT = qw(@elements %grid translate triangles @vertices);

our $size = 0;
our @vertices = ();
our @elements = ();
our %grid = ();
our @min = (0.0, 0.0, 0.0);
our @max = (0.0, 0.0, 0.0);
our @mid = (0.0, 0.0, 0.0);
our $c = 1.0;
our $t = 1.0;
our $xr = 0;
our $yr = 0;
our $zr = 0;

sub length {
	return sqrt($_[0] * $_[0] + $_[1] * $_[1] + $_[2] * $_[2]);
}

sub translate {
	if ($size > 0) {
		@min = @vertices[0..2];
		@max = @vertices[0..2];

		for (my $i = 1; $i < $size; ++$i) {
			my $x = $vertices[3 * $i];
			my $y = $vertices[3 * $i + 1];
			my $z = $vertices[3 * $i + 2];

			if ($x < $min[0]) {
				$min[0] = $x;
			}

			if ($y < $min[1]) {
				$min[1] = $y;
			}

			if ($z < $min[2]) {
				$min[2] = $z;
			}

			if ($x > $max[0]) {
				$max[0] = $x;
			}

			if ($y > $max[1]) {
				$max[1] = $y;
			}

			if ($z > $max[2]) {
				$max[2] = $z;
			}
		}
		@mid = ($min[0] / 2 + $max[0] / 2, $min[1] / 2 + $max[1] / 2, $min[2] / 2 + $max[2] / 2);

		for (my $i = 0; $i < $size; ++$i) {
			$vertices[3 * $i] -= $mid[0];
			$vertices[3 * $i + 1] -= $mid[1];
			$vertices[3 * $i + 2] -= $mid[2];
		}
		$max[0] -= $mid[0];
		$max[1] -= $mid[1];
		$max[2] -= $mid[2];
		$c = &length(@max) / 25.0;
		$t = $c;
		$xr = ceil($max[0] / $c - 0.5);
		$yr = ceil($max[1] / $c - 0.5);
		$zr = ceil($max[2] / $c - 0.5);
	}
}

sub cube {
	my $x = floor($_[0] / $c + 0.5);
	my $y = floor($_[1] / $c + 0.5);
	my $z = floor($_[2] / $c + 0.5);
	$grid{"$x,$y,$z"} = 1;
}

sub triangle {
	my ($a, $b, $c) = @_;
	$a *= 3;
	$b *= 3;
	$c *= 3;

	my @A = @vertices[$a..$a + 2];
	my @B = @vertices[$b..$b + 2];
	my @C = @vertices[$c..$c + 2];
	my @u = ($B[0] - $A[0], $B[1] - $A[1], $B[2] - $A[2]);
	my @v = ($C[0] - $A[0], $C[1] - $A[1], $C[2] - $A[2]);
	my $IIuII = &length(@u);
	my $IIvII = &length(@v);

	if ($IIuII > 0.0 && $IIvII > 0.0) {
		my $dy1 = fmin(1.0, $t / $IIuII);
		my $dy2 = fmin(1.0, $t / $IIvII);
		$u[0] *= $dy1;
		$u[1] *= $dy1;
		$u[2] *= $dy1;
		$v[0] *= $dy2;
		$v[1] *= $dy2;
		$v[2] *= $dy2;
		my @U = @A[0..2];

		for (my $y1 = 0.0; $y1 <= 1.0; $y1 += $dy1) {
			my @V = @U[0..2];

			for (my $y2 = 0.0; $y1 + $y2 <= 1.0; $y2 += $dy2) {
				cube(@V);
				$V[0] += $v[0];
				$V[1] += $v[1];
				$V[2] += $v[2];
			}
			$U[0] += $u[0];
			$U[1] += $u[1];
			$U[2] += $u[2];
		}
	}
}

sub triangles {
	for (my $i = 0; $i < @elements; $i += 3) {
		triangle($elements[$i], $elements[$i + 1], $elements[$i + 2]);
	}
}

1;
