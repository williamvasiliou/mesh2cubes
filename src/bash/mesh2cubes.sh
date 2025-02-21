#!/usr/bin/env bash

declare -i size=0
declare -a vertices
declare -a elements
declare -A grid
declare -a min=(0 0 0)
declare -a max=(0 0 0)
declare -a mid=(0 0 0)
declare c='1.0'
declare t='1.0'
declare -i xr=0
declare -i yr=0
declare -i zr=0

length () {
	echo $(echo $(echo $(echo $(echo $2 $2 | awk '{ print $1 * $2 }') $(echo $3 $3 | awk '{ print $1 * $2 }') | awk '{ print $1 + $2 }') $(echo $1 $1 | awk '{ print $1 * $2 }') | awk '{ print $1 + $2 }') | awk '{ print sqrt($1) }')
}

translate () {
	if [ $size -gt 0 ]
	then
		min=(${vertices[0]} ${vertices[1]} ${vertices[2]})
		max=(${vertices[0]} ${vertices[1]} ${vertices[2]})

		for (( i=1 ; i < $size ; ++i ))
		do
			local x=${vertices[$((3 * $i))]}
			local y=${vertices[$((3 * $i + 1))]}
			local z=${vertices[$((3 * $i + 2))]}

			if [ $(echo $x ${min[0]} | awk '{ print($1 < $2) }') -gt 0 ]
			then
				min[0]=$x
			fi

			if [ $(echo $y ${min[1]} | awk '{ print($1 < $2) }') -gt 0 ]
			then
				min[1]=$y
			fi

			if [ $(echo $z ${min[2]} | awk '{ print($1 < $2) }') -gt 0 ]
			then
				min[2]=$z
			fi

			if [ $(echo $x ${max[0]} | awk '{ print($1 > $2) }') -gt 0 ]
			then
				max[0]=$x
			fi

			if [ $(echo $y ${max[1]} | awk '{ print($1 > $2) }') -gt 0 ]
			then
				max[1]=$y
			fi

			if [ $(echo $z ${max[2]} | awk '{ print($1 > $2) }') -gt 0 ]
			then
				max[2]=$z
			fi
		done
		mid=($(echo ${min[0]} ${max[0]} | awk '{ print $1 / 2 + $2 / 2 }') $(echo ${min[1]} ${max[1]} | awk '{ print $1 / 2 + $2 / 2 }') $(echo ${min[2]} ${max[2]} | awk '{ print $1 / 2 + $2 / 2 }'))

		for (( i=0 ; i < $size ; ++i ))
		do
			vertices[$((3 * $i))]=$(echo ${vertices[$((3 * $i))]} ${mid[0]} | awk '{ print $1 - $2 }')
			vertices[$((3 * $i + 1))]=$(echo ${vertices[$((3 * $i + 1))]} ${mid[1]} | awk '{ print $1 - $2 }')
			vertices[$((3 * $i + 2))]=$(echo ${vertices[$((3 * $i + 2))]} ${mid[2]} | awk '{ print $1 - $2 }')
		done
		max[0]=$(echo ${max[0]} ${mid[0]} | awk '{ print $1 - $2 }')
		max[1]=$(echo ${max[1]} ${mid[1]} | awk '{ print $1 - $2 }')
		max[2]=$(echo ${max[2]} ${mid[2]} | awk '{ print $1 - $2 }')
		c=$(echo $(length ${max[@]}) '25.0' | awk '{ print $1 / $2 }')
		t=$c
		xr=$(echo $(echo $(echo ${max[0]} $c | awk '{ print $1 / $2 }') '0.5' | awk '{ print $1 - $2 }') | awk '{ if ($1 > 0) { d = $1 % 1; if (d > 0) { print $1 - d + 1 } else { print $1 } } else { print 0 } }')
		yr=$(echo $(echo $(echo ${max[1]} $c | awk '{ print $1 / $2 }') '0.5' | awk '{ print $1 - $2 }') | awk '{ if ($1 > 0) { d = $1 % 1; if (d > 0) { print $1 - d + 1 } else { print $1 } } else { print 0 } }')
		zr=$(echo $(echo $(echo ${max[2]} $c | awk '{ print $1 / $2 }') '0.5' | awk '{ print $1 - $2 }') | awk '{ if ($1 > 0) { d = $1 % 1; if (d > 0) { print $1 - d + 1 } else { print $1 } } else { print 0 } }')
	fi
}

cube () {
	local -ir x=$(echo $(echo $(echo $1 $c | awk '{ print $1 / $2 }') '0.5' | awk '{ print $1 + $2 }') | awk '{ if ($1 < 0) { d = $1 % 1; if (d < 0) { print $1 - d - 1 } else { print $1 } } else { print $1 - $1 % 1 } }')
	local -ir y=$(echo $(echo $(echo $2 $c | awk '{ print $1 / $2 }') '0.5' | awk '{ print $1 + $2 }') | awk '{ if ($1 < 0) { d = $1 % 1; if (d < 0) { print $1 - d - 1 } else { print $1 } } else { print $1 - $1 % 1 } }')
	local -ir z=$(echo $(echo $(echo $3 $c | awk '{ print $1 / $2 }') '0.5' | awk '{ print $1 + $2 }') | awk '{ if ($1 < 0) { d = $1 % 1; if (d < 0) { print $1 - d - 1 } else { print $1 } } else { print $1 - $1 % 1 } }')
	grid["$x,$y,$z"]=1
}

triangle () {
	local -ar A=(${vertices[$((3 * $1))]} ${vertices[$((3 * $1 + 1))]} ${vertices[$((3 * $1 + 2))]})
	local -ar B=(${vertices[$((3 * $2))]} ${vertices[$((3 * $2 + 1))]} ${vertices[$((3 * $2 + 2))]})
	local -ar C=(${vertices[$((3 * $3))]} ${vertices[$((3 * $3 + 1))]} ${vertices[$((3 * $3 + 2))]})
	local -a u=($(echo ${B[0]} ${A[0]} | awk '{ print $1 - $2 }') $(echo ${B[1]} ${A[1]} | awk '{ print $1 - $2 }') $(echo ${B[2]} ${A[2]} | awk '{ print $1 - $2 }'))
	local -a v=($(echo ${C[0]} ${A[0]} | awk '{ print $1 - $2 }') $(echo ${C[1]} ${A[1]} | awk '{ print $1 - $2 }') $(echo ${C[2]} ${A[2]} | awk '{ print $1 - $2 }'))
	local -r IIuII=$(length ${u[@]})
	local -r IIvII=$(length ${v[@]})

	if [[ $(echo $IIuII '0.0' | awk '{ print($1 > $2) }') -gt 0 && $(echo $IIvII '0.0' | awk '{ print($1 > $2) }') -gt 0 ]]
	then
		local -r dy1=$(echo '1.0' $(echo $t $IIuII | awk '{ print $1 / $2 }') | awk '{ if ($1 < $2) { print $1 } else { print $2 } }')
		local -r dy2=$(echo '1.0' $(echo $t $IIvII | awk '{ print $1 / $2 }') | awk '{ if ($1 < $2) { print $1 } else { print $2 } }')
		u[0]=$(echo ${u[0]} $dy1 | awk '{ print $1 * $2 }')
		u[1]=$(echo ${u[1]} $dy1 | awk '{ print $1 * $2 }')
		u[2]=$(echo ${u[2]} $dy1 | awk '{ print $1 * $2 }')
		v[0]=$(echo ${v[0]} $dy2 | awk '{ print $1 * $2 }')
		v[1]=$(echo ${v[1]} $dy2 | awk '{ print $1 * $2 }')
		v[2]=$(echo ${v[2]} $dy2 | awk '{ print $1 * $2 }')
		local -a U=(${A[@]})

		local y1='0.0'
		while [ $(echo $y1 '1.0' | awk '{ print($1 <= $2) }') -gt 0 ]
		do
			local -a V=(${U[@]})

			local y2='0.0'
			while [ $(echo $(echo $y1 $y2 | awk '{ print $1 + $2 }') '1.0' | awk '{ print($1 <= $2) }') -gt 0 ]
			do
				cube ${V[@]}
				V[0]=$(echo ${V[0]} ${v[0]} | awk '{ print $1 + $2 }')
				V[1]=$(echo ${V[1]} ${v[1]} | awk '{ print $1 + $2 }')
				V[2]=$(echo ${V[2]} ${v[2]} | awk '{ print $1 + $2 }')
				y2=$(echo $y2 $dy2 | awk '{ print $1 + $2 }')
			done
			U[0]=$(echo ${U[0]} ${u[0]} | awk '{ print $1 + $2 }')
			U[1]=$(echo ${U[1]} ${u[1]} | awk '{ print $1 + $2 }')
			U[2]=$(echo ${U[2]} ${u[2]} | awk '{ print $1 + $2 }')
			y1=$(echo $y1 $dy1 | awk '{ print $1 + $2 }')
		done
	fi
}

triangles () {
	for (( i=0 ; i < ${#elements[@]} ; i+=3 ))
	do
		triangle ${elements[$i]} ${elements[$(($i + 1))]} ${elements[$(($i + 2))]}
	done
}
