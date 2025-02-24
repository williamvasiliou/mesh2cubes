#!/usr/bin/env bash

. ../../src/bash/mesh2cubes.sh

read () {
	vertices=($(cat))
	size=$((3 * $((${#vertices[@]} / 9))))

	for (( i=0 ; i < $size ; i += 3 ))
	do
		elements+=($i $(($i + 1)) $(($i + 2)))
	done
}

print () {
	echo ${max[0]},${max[1]},${max[2]},$t,$c
	echo $xr,$yr,$zr

	for cube in ${!grid[@]}
	do
		echo $cube
	done
}

read
translate
triangles
print
