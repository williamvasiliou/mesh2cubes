#!/usr/bin/env bash

cut () {
	local -r delim=${1:?}
	local -r str=${2:?}

	local -ir size=${#str}
	local -i offset=0

	local -a Result
	local field=

	while [ $offset -lt $size ]
	do
		substr=${str:$offset:1}

		if [ $substr = $delim ]
		then
			Result[${#Result[@]}]=$field
			field=
		else
			field+=$substr
		fi

		offset+=1
	done

	Result[${#Result[@]}]=$field

	echo ${Result[@]}
}

join () {
	local -r delim=${1:?}
	local -a parameter=(${@:2})

	local -ir size=${#parameter[@]}
	local -i offset=1
	local Result=

	if [ $size -gt 1 ]
	then
		Result=${parameter[0]}

		while [ $offset -lt $size ]
		do
			Result+=$delim
			Result+=${parameter[$offset]}

			offset+=1
		done

		echo $Result
	else
		echo ${parameter[@]}
	fi
}

walk () {
	local -a C
	local -a B
	local -a NR
	local -a RLENGTH
	local -a PARENTS
	local -a R

	for parameter in $@
	do
		C=($(cut ':' $parameter))
		B[${#B[@]}]=0
		NR[${#NR[@]}]=${C[0]}
		RLENGTH[${#RLENGTH[@]}]=${C[1]}
		PARENTS[${#PARENTS[@]}]=${C[2]}
		R[${#R[@]}]=$(join ':' ${C[@]:3})
	done

	local -a D
	local -i depth=0

	local walks=1
	while [ $walks -eq 1 ]
	do
		walks=0

		for N in ${NR[@]}
		do
			if [ $depth -eq ${RLENGTH[$N]} ]
			then
				B[$N]=${#D[@]}
				D[${#D[@]}]=$N
				walks=1
			fi
		done

		depth+=1
	done

	local -a ancestors=(0)
	for N in ${NR[@]}
	do
		depth=${RLENGTH[$N]}

		if [ $depth -gt 0 ]
		then
			ancestors[$depth]=$N
			PARENTS[$N]=${ancestors[$(($depth - 1))]}
		fi
	done

	local -a T
	local -a parent

	for N in ${NR[@]}
	do
		T[$N]=\'${R[${D[$N]}]}\'
		parent[$N]=${B[${PARENTS[${D[$N]}]}]}
	done

	echo 'local -ar T=('${T[@]}')'
	echo 'local -ar parent=('${parent[@]}')'
}

get_children () {
	local -ir R=${1:?}
	local -ir size=${#T[@]}
	local -i P=0

	local -a children=()

	local -i low=0
	local -i high=$size
	local -i index=0
	local -i found=0

	while [ $low -le $high ]
	do
		if [ $low -eq $high ]
		then
			index=$low

			if [[ $index -ge 0 &&
				$index -lt $size &&
				$R -eq ${parent[$index]} ]]
			then
				found=1
			fi

			break
		else
			index=$(($low / 2 + $high / 2))
			P=${parent[$index]}

			if [ $R -gt $P ]
			then
				low=$(($index + 1))
			elif [ $R -lt $P ]
			then
				high=$(($index - 1))
			else
				found=1
				break
			fi
		fi
	done

	if [ $found -eq 1 ]
	then
		while [[ $index -gt 0 && $R -eq ${parent[$(($index - 1))]} ]]
		do
			index=$(($index - 1))
		done

		while [[ $index -lt $size && $R -eq ${parent[$index]} ]]
		do
			children[${#children[@]}]=$index
			index+=1
		done
	fi

	echo ${children[@]}
}

octal () {
	local -r parameter=${1:?}
	local -ir size=${#parameter}
	local -i offset=0
	local Result=

	while [ $offset -lt $size ]
	do
		Result+=${od[${parameter:$offset:1}]}
		offset+=1
	done

	echo $Result
}

emit () {
	local -ir R=${1:-0}
	local -r context=${2:-'11'}

	local -r root=${T[$R]}
	local -ar children=($(get_children $R))

	local -a parameters
	local -a Result
	if [ $target -lt 1 ]
	then
		Result[0]=$(octal $root)'\n'

		for child in ${children[@]}
		do
			if [ $child -gt 0 ]
			then
				for built in $(emit $child $context)
				do
					Result[${#Result[@]}]='\t'$built
				done
			fi
		done
	else
		case $root in
			mesh2cubes)
				Result=($(emit_mesh2cubes ${children[@]}))

				;;
			addAssignDouble)
				Result=($(emit_addAssignDouble ${children[@]:0:2}))

				;;
			addAssignInt)
				Result=($(emit_addAssignInt ${children[@]:0:2}))

				;;
			addAssignVector3d)
				Result=($(emit_addAssignVector3d ${children[@]:0:2}))

				;;
			addDouble)
				Result=($(emit_addDouble ${children[@]:0:2}))

				;;
			and)
				Result=($(emit_and ${children[@]:0:2}))

				;;
			assignDouble)
				Result=($(emit_assignDouble ${children[@]:0:2}))

				;;
			assignGrid)
				Result=($(emit_assignGrid ${children[@]:0:3}))

				;;
			assignVector3d)
				Result=($(emit_assignVector3d ${children[@]:0:2}))

				;;
			averageVector3d)
				Result=($(emit_averageVector3d ${children[@]:0:2}))

				;;
			call:*)
				parameters=($(cut ':' $root))
				Result=($(emit_call ${parameters[1]} ${children[@]}))

				;;
			ceil)
				Result=($(emit_ceil ${children[0]}))

				;;
			compareDouble)
				Result=($(emit_compareDouble ${children[@]:0:3}))

				;;
			compareInt)
				Result=($(emit_compareInt ${children[@]:0:3}))

				;;
			constructor)
				Result=($(emit_constructor ${children[@]}))

				;;
			divideDouble)
				Result=($(emit_divideDouble ${children[@]:0:2}))

				;;
			dot)
				Result=($(emit_dot ${children[@]:0:2}))

				;;
			dotVertex)
				Result=($(emit_dotVertex ${children[@]:0:2}))

				;;
			double)
				Result=($(emit_double ${children[0]}))

				;;
			floor)
				Result=($(emit_floor ${children[0]}))

				;;
			for)
				Result=($(emit_for ${children[@]:0:4}))

				;;
			forDouble)
				Result=($(emit_forDouble ${children[@]:0:4}))

				;;
			function:*)
				parameters=($(cut ':' $root))
				parameters=($(cut ',' ${parameters[1]}))
				Result=($(emit_function ${parameters[@]}))

				;;
			glue)
				Result=($(emit_glue ${children[@]}))

				;;
			identifier)
				Result=($(emit_identifier ${children[0]}))

				;;
			identifierVector3d)
				Result=($(emit_identifierVector3d ${children[0]}))

				;;
			if)
				Result=($(emit_if ${children[@]}))

				;;
			increment)
				Result=($(emit_increment ${children[0]}))

				;;
			int)
				Result=($(emit_int ${children[0]}))

				;;
			min)
				Result=($(emit_min ${children[@]:0:2}))

				;;
			minusAssignVector3d)
				Result=($(emit_minusAssignVector3d ${children[@]:0:2}))

				;;
			minusAssignVertex)
				Result=($(emit_minusAssignVertex ${children[@]:0:2}))

				;;
			minusDouble)
				Result=($(emit_minusDouble ${children[@]:0:2}))

				;;
			minusVector3d)
				Result=($(emit_minusVector3d ${children[@]:0:2}))

				;;
			multiplyDouble)
				Result=($(emit_multiplyDouble ${children[@]:0:2}))

				;;
			newGrid)
				Result=($(emit_newGrid ${children[@]:0:3}))

				;;
			operator)
				Result=($(emit_operator ${children[0]}))

				;;
			positional)
				Result=($(emit_positional ${children[@]:0:2}))

				;;
			return)
				Result=($(emit_return ${children[0]}))

				;;
			scaleVector3d)
				Result=($(emit_scaleVector3d ${children[@]:0:2}))

				;;
			triangle)
				Result=($(emit_triangle ${children[0]}))

				;;
			type)
				Result=($(emit_type ${children[@]}))

				;;
			var)
				Result=($(emit_var 0 ${children[@]}))

				;;
			var:*)
				parameters=($(cut ':' $root))
				parameters=($(cut ',' ${parameters[1]}))
				Result=($(emit_var 1 ${parameters[@]}))

				;;
			vertex)
				Result=($(emit_vertex 0 ${children[0]}))

				;;
			vertex:*)
				parameters=($(cut ':' $root))
				Result=($(emit_vertex 1 ${parameters[1]}))

				;;
		esac
	fi

	echo ${Result[@]}
}

target () {
	local -Ar targets=('awk' 1 'bash' 2 'java' 3)
	echo ${targets[$1]:?}
}

build () {
	local -ir index=$((${1:?} - 1))
	local -ar subdirs=('awk' 'bash' 'java')
	local -r mesh2cubes='mesh2cubes'
	local -ar extensions=('awk' 'sh' 'java')

	local -r subdir=${subdirs[$index]}
	local -r extension=${extensions[$index]}
	local -r path="$subdir/$mesh2cubes.$extension"

	if [[ -d $subdir && ! -a $path ]]
	then
		for built in $(emit)
		do
			printf $built >> $path
		done
	fi
}

main () {
	local -ir target=${1:?}

	local -ar T=('mesh2cubes' 'constructor' 'function:length,Vector3d,v1' 'function:translate' 'function:cube,Vector3d,v1' 'function:triangle,int,a,int,b,int,c' 'function:triangles' 'var:int,size,0' 'var:double[],vertices' 'var:int[],elements' 'var:Grid,grid' 'var:Vector3d,min' 'var:Vector3d,max' 'var:Vector3d,mid' 'var:double,c,1.0' 'var:double,t,1.0' 'var:int,xr,0' 'var:int,yr,0' 'var:int,zr,0' 'return' 'if' 'var' 'var' 'var' 'assignGrid' 'var' 'var' 'var' 'var' 'var' 'var' 'var' 'if' 'for' 'call:sqrt' 'compareInt' 'glue' 'type' 'identifier' 'floor' 'type' 'identifier' 'floor' 'type' 'identifier' 'floor' 'identifier' 'identifier' 'identifier' 'type' 'identifier' 'vertex' 'type' 'identifier' 'vertex' 'type' 'identifier' 'vertex' 'type' 'identifier' 'minusVector3d' 'type' 'identifier' 'minusVector3d' 'type' 'identifier' 'call:length' 'type' 'identifier' 'call:length' 'and' 'glue' 'var' 'compareInt' 'addAssignInt' 'glue' 'addDouble' 'identifier' 'operator' 'int' 'assignVector3d' 'assignVector3d' 'for' 'assignVector3d' 'for' 'minusAssignVector3d' 'assignDouble' 'assignDouble' 'assignDouble' 'assignDouble' 'assignDouble' 'newGrid' 'const' 'int' 'x' 'addDouble' 'const' 'int' 'y' 'addDouble' 'const' 'int' 'z' 'addDouble' 'x' 'y' 'z' 'const' 'Vector3d' 'A' 'positional' 'const' 'Vector3d' 'B' 'positional' 'const' 'Vector3d' 'C' 'positional' 'Vector3d' 'u' 'identifier' 'identifier' 'Vector3d' 'v' 'identifier' 'identifier' 'const' 'double' 'IIuII' 'identifier' 'const' 'double' 'IIvII' 'identifier' 'compareDouble' 'compareDouble' 'var' 'var' 'scaleVector3d' 'scaleVector3d' 'var' 'forDouble' 'type' 'identifier' 'int' 'identifier' 'operator' 'dot' 'identifier' 'int' 'call:triangle' 'addDouble' 'multiplyDouble' 'size' 'gt' '0' 'identifier' 'vertex:0' 'identifier' 'vertex:0' 'var' 'compareInt' 'increment' 'glue' 'identifier' 'averageVector3d' 'var' 'compareInt' 'increment' 'glue' 'identifier' 'identifier' 'identifier' 'divideDouble' 'identifier' 'identifier' 'identifier' 'ceil' 'identifier' 'ceil' 'identifier' 'ceil' 'identifier' 'identifier' 'identifier' 'divideDouble' 'double' 'divideDouble' 'double' 'divideDouble' 'double' 'identifier' 'identifier' 'identifier' 'identifier' 'identifier' 'identifier' 'B' 'A' 'C' 'A' 'u' 'v' 'identifier' 'operator' 'double' 'identifier' 'operator' 'double' 'type' 'identifier' 'min' 'type' 'identifier' 'min' 'identifier' 'identifier' 'identifier' 'identifier' 'type' 'identifier' 'identifierVector3d' 'var' 'compareDouble' 'addAssignDouble' 'glue' 'int' 'i' '0' 'i' 'lt' 'triangles' 'size' 'i' '3' 'triangle' 'multiplyDouble' 'multiplyDouble' 'dot' 'dot' 'min' 'max' 'type' 'identifier' 'int' 'identifier' 'operator' 'identifier' 'identifier' 'var' 'var' 'var' 'if' 'if' 'if' 'if' 'if' 'if' 'mid' 'identifier' 'identifier' 'type' 'identifier' 'int' 'identifier' 'operator' 'identifier' 'identifier' 'minusAssignVertex' 'max' 'mid' 'c' 'call:length' 'double' 't' 'c' 'xr' 'minusDouble' 'yr' 'minusDouble' 'zr' 'minusDouble' 'xr' 'yr' 'zr' 'dot' 'identifier' '0.5' 'dot' 'identifier' '0.5' 'dot' 'identifier' '0.5' '1' 'a' '2' 'b' '3' 'c' 'IIuII' 'gt' '0.0' 'IIvII' 'gt' '0.0' 'const' 'double' 'dy1' 'double' 'divideDouble' 'const' 'double' 'dy2' 'double' 'divideDouble' 'u' 'dy1' 'v' 'dy2' 'Vector3d' 'U' 'A' 'type' 'identifier' 'double' 'identifier' 'operator' 'double' 'identifier' 'identifier' 'var' 'forDouble' 'addAssignVector3d' 'identifier' 'dot' 'dot' 'dot' 'dot' 'v1' 'x' 'v1' 'x' 'int' 'i' '1' 'i' 'lt' 'size' 'i' 'type' 'identifier' 'dotVertex' 'type' 'identifier' 'dotVertex' 'type' 'identifier' 'dotVertex' 'compareDouble' 'glue' 'compareDouble' 'glue' 'compareDouble' 'glue' 'compareDouble' 'glue' 'compareDouble' 'glue' 'compareDouble' 'glue' 'min' 'max' 'int' 'i' '0' 'i' 'lt' 'size' 'i' 'identifier' 'identifier' 'identifier' '25.0' 'divideDouble' 'double' 'divideDouble' 'double' 'divideDouble' 'double' 'v1' 'x' 'c' 'v1' 'y' 'c' 'v1' 'z' 'c' '1.0' 'identifier' 'identifier' '1.0' 'identifier' 'identifier' 'double' 'y1' '0.0' 'y1' 'le' '1.0' 'y1' 'dy1' 'type' 'identifier' 'identifierVector3d' 'var' 'compareDouble' 'addAssignDouble' 'glue' 'identifier' 'identifier' 'i' 'v1' 'y' 'v1' 'y' 'v1' 'z' 'v1' 'z' 'double' 'x' 'identifier' 'x' 'double' 'y' 'identifier' 'y' 'double' 'z' 'identifier' 'z' 'identifier' 'operator' 'dot' 'assignDouble' 'identifier' 'operator' 'dot' 'assignDouble' 'identifier' 'operator' 'dot' 'assignDouble' 'identifier' 'operator' 'dot' 'assignDouble' 'identifier' 'operator' 'dot' 'assignDouble' 'identifier' 'operator' 'dot' 'assignDouble' 'i' 'mid' 'max' 'dot' 'identifier' '0.5' 'dot' 'identifier' '0.5' 'dot' 'identifier' '0.5' 't' 'IIuII' 't' 'IIvII' 'Vector3d' 'V' 'U' 'type' 'identifier' 'double' 'addDouble' 'operator' 'double' 'identifier' 'identifier' 'call:cube' 'addAssignVector3d' 'U' 'u' 'i' 'i' 'i' 'x' 'lt' 'min' 'x' 'dot' 'identifier' 'y' 'lt' 'min' 'y' 'dot' 'identifier' 'z' 'lt' 'min' 'z' 'dot' 'identifier' 'x' 'gt' 'max' 'x' 'dot' 'identifier' 'y' 'gt' 'max' 'y' 'dot' 'identifier' 'z' 'gt' 'max' 'z' 'dot' 'identifier' 'max' 'x' 'c' 'max' 'y' 'c' 'max' 'z' 'c' 'double' 'y2' '0.0' 'identifier' 'identifier' 'le' '1.0' 'y2' 'dy2' 'identifier' 'identifier' 'identifier' 'min' 'x' 'x' 'min' 'y' 'y' 'min' 'z' 'z' 'max' 'x' 'x' 'max' 'y' 'y' 'max' 'z' 'z' 'y1' 'y2' 'V' 'V' 'v')
	local -ar parent=(0 0 0 0 0 0 0 1 1 1 1 1 1 1 1 1 1 1 1 2 3 4 4 4 4 5 5 5 5 5 5 5 5 6 19 20 20 21 21 21 22 22 22 23 23 23 24 24 24 25 25 25 26 26 26 27 27 27 28 28 28 29 29 29 30 30 30 31 31 31 32 32 33 33 33 33 34 35 35 35 36 36 36 36 36 36 36 36 36 36 36 36 37 37 38 39 40 40 41 42 43 43 44 45 46 47 48 49 49 50 51 52 52 53 54 55 55 56 57 58 59 60 60 61 62 63 63 64 64 65 66 67 67 68 69 70 70 71 71 71 71 71 71 72 72 72 73 73 73 74 74 75 76 76 77 78 79 80 80 81 81 82 82 82 82 83 83 84 84 84 84 85 85 86 86 87 87 88 88 89 89 90 90 91 91 91 95 95 99 99 103 103 110 110 114 114 118 118 121 122 125 126 130 134 135 135 135 136 136 136 137 137 137 138 138 138 139 139 140 140 141 141 141 142 142 142 142 143 144 145 146 147 148 148 149 150 151 152 152 153 153 157 159 161 161 161 162 162 162 163 164 164 164 164 164 164 164 164 164 165 166 166 167 167 167 168 168 168 169 170 171 172 173 174 174 175 176 177 178 179 180 181 182 183 184 185 186 186 187 188 188 189 190 190 191 192 193 194 195 196 197 204 205 206 207 208 209 210 210 211 212 212 213 213 214 215 215 216 217 218 219 220 221 222 223 223 223 224 224 224 225 225 226 226 226 236 237 237 238 238 239 239 240 240 243 244 245 246 247 248 249 250 250 250 251 251 251 252 252 252 253 253 254 254 255 255 256 256 257 257 258 258 260 261 262 263 264 265 266 267 268 269 269 273 274 278 278 280 280 282 282 286 286 287 289 289 290 292 292 293 310 311 311 315 316 316 324 325 326 327 328 329 330 331 332 332 332 333 333 333 333 334 334 335 336 336 337 337 338 338 339 339 351 352 353 353 354 355 356 356 357 358 359 359 360 360 360 361 362 362 362 363 364 364 364 365 366 366 366 367 368 368 368 369 370 370 370 371 381 382 383 385 385 386 387 387 388 389 389 390 401 402 404 405 414 415 416 417 417 417 418 418 418 419 419 420 420 421 422 434 438 442 444 445 446 446 447 447 448 449 450 450 451 451 452 453 454 454 455 455 456 457 458 458 459 459 460 461 462 462 463 463 464 465 466 466 467 467 471 471 472 474 474 475 477 477 478 487 488 489 490 490 491 492 493 494 495 496 496 506 506 507 512 512 513 518 518 519 524 524 525 530 530 531 536 536 537 550 551 556 557 558)

	local -Ar od=(' ' '\040' '!' '\041' '"' '\042' '#' '\043' '$' '\044' '%' '\045' '&' '\046' \' '\047' '(' '\050' ')' '\051' '*' '\052' '+' '\053' ',' '\054' '-' '\055' '.' '\056' '/' '\057' '0' '\060' '1' '\061' '2' '\062' '3' '\063' '4' '\064' '5' '\065' '6' '\066' '7' '\067' '8' '\070' '9' '\071' ':' '\072' ';' '\073' '<' '\074' '=' '\075' '>' '\076' '?' '\077' '@' '\100' 'A' '\101' 'B' '\102' 'C' '\103' 'D' '\104' 'E' '\105' 'F' '\106' 'G' '\107' 'H' '\110' 'I' '\111' 'J' '\112' 'K' '\113' 'L' '\114' 'M' '\115' 'N' '\116' 'O' '\117' 'P' '\120' 'Q' '\121' 'R' '\122' 'S' '\123' 'T' '\124' 'U' '\125' 'V' '\126' 'W' '\127' 'X' '\130' 'Y' '\131' 'Z' '\132' '[' '\133' '\' '\134' ']' '\135' '^' '\136' '_' '\137' '`' '\140' 'a' '\141' 'b' '\142' 'c' '\143' 'd' '\144' 'e' '\145' 'f' '\146' 'g' '\147' 'h' '\150' 'i' '\151' 'j' '\152' 'k' '\153' 'l' '\154' 'm' '\155' 'n' '\156' 'o' '\157' 'p' '\160' 'q' '\161' 'r' '\162' 's' '\163' 't' '\164' 'u' '\165' 'v' '\166' 'w' '\167' 'x' '\170' 'y' '\171' 'z' '\172' '{' '\173' '|' '\174' '}' '\175' '~' '\176')

	if [ $target -gt 0 ]
	then
		build $target
	else
		for built in $(emit)
		do
			printf $built
		done
	fi
}

if [ $# -eq 1 ]
then
	if [ -f "$1" ]
	then
		walk $(awk '{ match($0, /^\t+/); gsub(/^\t+/, ""); print (NR - 1) ":" (RLENGTH > 0 ? RLENGTH : 0) ":0:" $0 }' "$1")
	else
		main $(target "$1")
	fi
elif [ $# -eq 0 ]
then
	main 0
fi
