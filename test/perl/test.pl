#!/usr/bin/env perl
use strict;
use warnings;

use mesh2cubes;

while (<>) {
	push(@vertices, sprintf('%g', $_));
}

$mesh2cubes::size = 3 * int(@vertices / 9);

for (my $i = 0; $i < $mesh2cubes::size; $i += 3) {
	push(@elements, $i);
	push(@elements, $i + 1);
	push(@elements, $i + 2);
}

translate;
triangles;

print $mesh2cubes::max[0] . "," . $mesh2cubes::max[1] . "," . $mesh2cubes::max[2] . "," . $mesh2cubes::t . "," . $mesh2cubes::c . "\n";
print $mesh2cubes::xr . "," . $mesh2cubes::yr . "," . $mesh2cubes::zr . "\n";

foreach my $cube (keys %grid) {
	print $cube . "\n";
}
