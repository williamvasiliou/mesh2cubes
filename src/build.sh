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

interface () {
	local -r name="$(basename $0)"
	local -ar methods=('mesh2cubes' 'addAssignDouble' 'addAssignInt' 'addAssignVector3d' 'addDouble' 'addInt' 'addLow' 'and' 'assignDouble' 'assignGrid' 'assignInt' 'assignVector3d' 'averageVector3d' 'call' 'ceil' 'compareDouble' 'compareInt' 'compareLow' 'constructor' 'declarations' 'declarationsBody' 'divideDouble' 'dot' 'dotCount' 'dotVertex' 'double' 'floor' 'for' 'forDouble' 'function' 'glue' 'identifier' 'identifierThis' 'identifierVector3d' 'if' 'ifAssignGrid' 'increment' 'int' 'min' 'minusAssignVector3d' 'minusAssignVertex' 'minusDouble' 'minusVector3d' 'multiplyDouble' 'multiplyInt' 'newGrid' 'operator' 'parameter' 'parameters' 'positional' 'return' 'scaleVector3d' 'triangle' 'type' 'var' 'vertex')
	local -i Result=1

	for method in ${methods[@]}
	do
		if [ "$(type -t emit_$method)" != 'function' ]
		then
			echo "$name: emit_$method: No such method" >&2
			Result=0
		fi
	done

	if [ "$(type -t build_files)" != 'function' ]
	then
		echo "$name: build_files: No such method" >&2
		Result=0
	fi

	echo $Result
}

emit () {
	local -ir R=${1:-0}
	local -r context=${2:-'11'}

	local -r root=${T[$R]}
	local -ar children=($(get_children $R))

	local -a parameters
	local -a Result
	if [ $target -ne 1 ]
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
			addInt)
				Result=($(emit_addInt ${children[@]:0:2}))

				;;
			addLow)
				Result=($(emit_addLow ${children[@]:0:2}))

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
			assignInt)
				Result=($(emit_assignInt ${children[@]:0:2}))

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
			compareLow)
				Result=($(emit_compareLow ${children[@]:0:3}))

				;;
			constructor)
				Result=($(emit_constructor ${children[@]}))

				;;
			declarations)
				Result=($(emit_declarations ${children[@]}))

				;;
			declarationsBody)
				Result=($(emit_declarationsBody ${children[@]}))

				;;
			divideDouble)
				Result=($(emit_divideDouble ${children[@]:0:2}))

				;;
			dot)
				Result=($(emit_dot ${children[@]:0:2}))

				;;
			dotCount)
				Result=($(emit_dotCount))

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
				Result=($(emit_function ${parameters[1]} ${children[@]}))

				;;
			glue)
				Result=($(emit_glue ${children[@]}))

				;;
			identifier)
				Result=($(emit_identifier ${children[0]}))

				;;
			identifierThis)
				Result=($(emit_identifierThis ${children[0]}))

				;;
			identifierVector3d)
				Result=($(emit_identifierVector3d ${children[0]}))

				;;
			if)
				Result=($(emit_if ${children[@]}))

				;;
			ifAssignGrid)
				Result=($(emit_ifAssignGrid ${children[@]}))

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
			multiplyInt)
				Result=($(emit_multiplyInt ${children[@]:0:2}))

				;;
			newGrid)
				Result=($(emit_newGrid ${children[@]:0:6}))

				;;
			operator)
				Result=($(emit_operator ${children[0]}))

				;;
			parameter)
				Result=($(emit_parameter ${children[@]:0:2}))

				;;
			parameters)
				Result=($(emit_parameters ${children[@]}))

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
			var:*)
				parameters=($(cut ':' $root))
				Result=($(emit_var ${parameters[1]} ${children[@]}))

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
	local -Ar targets=('ada' 1 'awk' 1 'bash' 1 'c' 1 'cxx' 1 'd' 1 'fortran' 1 'go' 1 'java' 1 'perl' 1)
	echo ${targets[${1:?}]:-0}
}

build_file () {
	local -r subdir=${1:?}
	local -r mesh2cubes=${2:?}
	local -r extension=${3:?}
	local -r path="$subdir/$mesh2cubes.$extension"

	if [ -d "$subdir" ]
	then
		if [ -a "$path" ]
		then
			echo "$(basename $0): cannot create \`$path': File exists" >&2
		elif [ $# -eq 4 ]
		then
			for built in $(emit 0 "${4:?}")
			do
				printf "$built" >> "$path"
			done
		else
			for built in $(emit)
			do
				printf "$built" >> "$path"
			done
		fi
	else
		echo "$(basename $0): cannot create \`$path': No such directory" >&2
	fi
}

build () {
	local -ir target=${1:?}

	if [ $# -eq 2 ]
	then
		if [ $target -ne 1 ]
		then
			echo "$(basename $0): cannot make \`${2:?}': No such target" >&2
		elif [ $(interface) -eq 1 ]
		then
			build_files "${2:?}" 'mesh2cubes'
		fi
	elif [ $target -eq 0 ]
	then
		for built in $(emit)
		do
			printf $built
		done
	fi
}

main () {
	local -ar T=('mesh2cubes' 'constructor' 'function:length' 'function:translate' 'function:cube' 'function:triangle' 'function:triangles' 'var:size' 'var:vertices' 'var:count' 'var:elements' 'var:grid' 'var:min' 'var:max' 'var:mid' 'var:c' 'var:t' 'var:xr' 'var:yr' 'var:zr' 'var:xl' 'var:yl' 'var:zl' 'type' 'parameters' 'declarations' 'return' 'type' 'parameters' 'declarations' 'if' 'type' 'parameters' 'declarationsBody' 'ifAssignGrid' 'type' 'parameters' 'declarationsBody' 'if' 'type' 'parameters' 'declarations' 'for' 'type' 'int' 'type' 'type' 'int' 'type' 'type' 'type' 'type' 'type' 'type' 'double' 'type' 'double' 'type' 'int' 'type' 'int' 'type' 'int' 'type' 'int' 'type' 'int' 'type' 'int' 'static' 'double' 'parameter' 'call:sqrt' 'void' 'var:i' 'var:x' 'var:y' 'var:z' 'compareInt' 'glue' 'void' 'parameter' 'var:x' 'var:y' 'var:z' 'and' 'glue' 'void' 'parameter' 'parameter' 'parameter' 'var:A' 'var:B' 'var:C' 'var:u' 'var:v' 'var:IIuII' 'var:IIvII' 'declarations' 'and' 'glue' 'void' 'var:i' 'var:count' 'var:i' 'compareInt' 'addAssignInt' 'glue' 'size.vertices' '0' 'double[]' 'size.elements' '0' 'index[]' 'Grid' 'Vector3d' 'Vector3d' 'Vector3d' 'double' '1.0' 'double' '1.0' 'index' '0' 'index' '0' 'index' '0' 'size.grid' '0' 'size.grid' '0' 'size.grid' '0' 'type' 'identifier' 'addDouble' 'type' 'int' 'type' 'double' 'type' 'double' 'type' 'double' 'identifierThis' 'operator' 'int' 'assignVector3d' 'assignVector3d' 'for' 'assignVector3d' 'for' 'minusAssignVector3d' 'assignDouble' 'assignDouble' 'assignInt' 'assignInt' 'assignInt' 'newGrid' 'type' 'identifier' 'type' 'addLow' 'type' 'addLow' 'type' 'addLow' 'and' 'compareInt' 'assignGrid' 'type' 'identifier' 'type' 'identifier' 'type' 'identifier' 'type' 'vertex' 'type' 'vertex' 'type' 'vertex' 'type' 'minusVector3d' 'type' 'minusVector3d' 'type' 'call:length' 'type' 'call:length' 'var:dy1' 'var:dy2' 'var:U' 'var:y1' 'var:V' 'var:y2' 'compareDouble' 'compareDouble' 'var:dy1' 'var:dy2' 'scaleVector3d' 'scaleVector3d' 'var:U' 'forDouble' 'type' 'int' 'type' 'dot' 'type' 'int' 'identifier' 'operator' 'dotCount' 'identifier' 'int' 'call:triangle' 'Vector3d' 'v1' 'addDouble' 'multiplyDouble' 'index' '0' 'double' '0.0' 'double' '0.0' 'double' '0.0' 'size' 'gt' '0' 'identifierThis' 'vertex:0' 'identifierThis' 'vertex:0' 'var:i' 'compareInt' 'increment' 'glue' 'identifierThis' 'averageVector3d' 'var:i' 'compareInt' 'increment' 'glue' 'identifierThis' 'identifierThis' 'identifierThis' 'divideDouble' 'identifierThis' 'identifierThis' 'identifierThis' 'ceil' 'identifierThis' 'ceil' 'identifierThis' 'ceil' 'assignInt' 'assignInt' 'assignInt' 'identifierThis' 'identifierThis' 'identifierThis' 'Vector3d' 'v1' 'const' 'index.grid' 'floor' 'identifierThis' 'const' 'index.grid' 'floor' 'identifierThis' 'const' 'index.grid' 'floor' 'identifierThis' 'and' 'compareLow' 'identifier' 'operator' 'identifierThis' 'identifier' 'identifier' 'identifier' 'index' 'a' 'index' 'b' 'index' 'c' 'const' 'Vector3d' 'positional' 'const' 'Vector3d' 'positional' 'const' 'Vector3d' 'positional' 'Vector3d' 'identifier' 'identifier' 'Vector3d' 'identifier' 'identifier' 'const' 'double' 'identifier' 'const' 'double' 'identifier' 'type' 'double' 'type' 'double' 'type' 'type' 'double' 'type' 'type' 'double' 'identifier' 'operator' 'double' 'identifier' 'operator' 'double' 'type' 'min' 'type' 'min' 'identifier' 'identifier' 'identifier' 'identifier' 'type' 'identifierVector3d' 'var:y1' 'compareDouble' 'addAssignDouble' 'glue' 'index' '0' 'const' 'index' 'triangles' 'size' 'index' '0' 'i' 'lt' 'i' '3' 'triangle' 'multiplyDouble' 'multiplyDouble' 'dot' 'dot' 'min' 'max' 'type' 'int' 'identifier' 'operator' 'identifierThis' 'identifier' 'var:x' 'var:y' 'var:z' 'if' 'if' 'if' 'if' 'if' 'if' 'mid' 'identifierThis' 'identifierThis' 'type' 'int' 'identifier' 'operator' 'identifierThis' 'identifier' 'minusAssignVertex' 'max' 'mid' 'c' 'call:length' 'double' 't' 'c' 'xr' 'minusDouble' 'yr' 'minusDouble' 'zr' 'minusDouble' 'identifierThis' 'addInt' 'identifierThis' 'addInt' 'identifierThis' 'addInt' 'xl' 'yl' 'zl' 'addDouble' 'xr' 'addDouble' 'yr' 'addDouble' 'zr' 'and' 'compareInt' 'identifier' 'operator' 'int' 'z' 'lt' 'zl' 'x' 'y' 'z' 'identifier' 'identifier' 'identifier' 'identifier' 'identifier' 'identifier' 'B' 'A' 'C' 'A' 'u' 'v' 'double' '0.0' 'double' '0.0' 'Vector3d' 'double' '0.0' 'Vector3d' 'double' '0.0' 'IIuII' 'gt' '0.0' 'IIvII' 'gt' '0.0' 'const' 'double' 'double' 'divideDouble' 'const' 'double' 'double' 'divideDouble' 'u' 'dy1' 'v' 'dy2' 'Vector3d' 'A' 'type' 'double' 'identifier' 'operator' 'double' 'identifier' 'identifier' 'var:V' 'forDouble' 'addAssignVector3d' 'identifier' 'dot' 'dot' 'dot' 'dot' 'v1' 'z' 'v1' 'z' 'index' '1' 'i' 'lt' 'size' 'i' 'positional' 'dotVertex' 'positional' 'dotVertex' 'positional' 'dotVertex' 'compareDouble' 'glue' 'compareDouble' 'glue' 'compareDouble' 'glue' 'compareDouble' 'glue' 'compareDouble' 'glue' 'compareDouble' 'glue' 'min' 'max' 'index' '0' 'i' 'lt' 'size' 'i' 'identifier' 'identifierThis' 'identifierThis' '25.0' 'divideDouble' 'double' 'divideDouble' 'double' 'divideDouble' 'double' 'xl' 'multiplyInt' 'int' 'yl' 'multiplyInt' 'int' 'zl' 'multiplyInt' 'int' 'divideDouble' 'double' 'divideDouble' 'double' 'divideDouble' 'double' 'and' 'compareLow' 'identifier' 'operator' 'identifierThis' 'z' 'ge' '0' '1' 'a' '2' 'b' '3' 'c' '1.0' 'identifierThis' 'identifier' '1.0' 'identifierThis' 'identifier' 'double' '0.0' 'y1' 'le' '1.0' 'y1' 'dy1' 'type' 'identifierVector3d' 'var:y2' 'compareDouble' 'addAssignDouble' 'glue' 'identifier' 'identifier' 'i' 'v1' 'x' 'v1' 'x' 'v1' 'y' 'v1' 'y' 'type' 'type' 'identifier' 'x' 'type' 'type' 'identifier' 'y' 'type' 'type' 'identifier' 'z' 'identifier' 'operator' 'dot' 'assignDouble' 'identifier' 'operator' 'dot' 'assignDouble' 'identifier' 'operator' 'dot' 'assignDouble' 'identifier' 'operator' 'dot' 'assignDouble' 'identifier' 'operator' 'dot' 'assignDouble' 'identifier' 'operator' 'dot' 'assignDouble' 'i' 'mid' 'max' 'dot' 'identifierThis' '0.5' 'dot' 'identifierThis' '0.5' 'dot' 'identifierThis' '0.5' 'int' 'identifierThis' '1' 'int' 'identifierThis' '1' 'int' 'identifierThis' '1' 'dot' 'identifierThis' '0.5' 'dot' 'identifierThis' '0.5' 'dot' 'identifierThis' '0.5' 'compareLow' 'compareInt' 'identifier' 'operator' 'int' 'y' 'lt' 'yl' 't' 'IIuII' 't' 'IIvII' 'Vector3d' 'U' 'type' 'double' 'addDouble' 'operator' 'double' 'identifier' 'identifier' 'call:cube' 'addAssignVector3d' 'U' 'u' 'double' 'const' 'double' 'i' 'double' 'const' 'double' 'i' 'double' 'const' 'double' 'i' 'x' 'lt' 'min' 'x' 'dot' 'identifier' 'y' 'lt' 'min' 'y' 'dot' 'identifier' 'z' 'lt' 'min' 'z' 'dot' 'identifier' 'x' 'gt' 'max' 'x' 'dot' 'identifier' 'y' 'gt' 'max' 'y' 'dot' 'identifier' 'z' 'gt' 'max' 'z' 'dot' 'identifier' 'max' 'x' 'c' 'max' 'y' 'c' 'max' 'z' 'c' '2' 'xr' '2' 'yr' '2' 'zr' 'v1' 'x' 'c' 'v1' 'y' 'c' 'v1' 'z' 'c' 'identifier' 'operator' 'int' 'identifier' 'operator' 'identifierThis' 'y' 'ge' '0' 'double' '0.0' 'identifier' 'identifier' 'le' '1.0' 'y2' 'dy2' 'identifier' 'identifier' 'identifier' 'min' 'x' 'x' 'min' 'y' 'y' 'min' 'z' 'z' 'max' 'x' 'x' 'max' 'y' 'y' 'max' 'z' 'z' 'x' 'ge' '0' 'x' 'lt' 'xl' 'y1' 'y2' 'V' 'V' 'v')
	local -ar parent=(0 0 0 0 0 0 0 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 2 2 2 2 3 3 3 3 4 4 4 4 5 5 5 5 6 6 6 6 7 7 8 9 9 10 11 12 13 14 15 15 16 16 17 17 18 18 19 19 20 20 21 21 22 22 23 23 24 26 27 29 29 29 29 30 30 31 32 33 33 33 34 34 35 36 36 36 37 37 37 37 37 37 37 37 38 38 39 41 41 42 42 42 42 43 44 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59 60 61 62 63 64 65 66 67 68 71 71 72 74 74 75 75 76 76 77 77 78 78 78 79 79 79 79 79 79 79 79 79 79 79 79 81 81 82 82 83 83 84 84 85 85 86 88 88 89 89 90 90 91 91 92 92 93 93 94 94 95 95 96 96 97 97 98 98 98 98 98 98 99 99 100 100 100 100 100 100 102 102 103 103 104 104 105 105 105 106 106 107 134 135 136 136 137 138 139 140 141 142 143 144 145 146 147 148 148 149 149 150 150 150 150 151 151 152 152 152 152 153 153 154 154 155 155 156 156 157 157 158 158 159 159 159 159 159 159 160 161 162 162 163 163 164 164 165 165 166 166 167 167 168 168 169 169 169 170 170 170 171 172 173 174 175 176 177 177 178 179 179 180 181 181 182 183 184 184 185 186 186 187 187 188 189 189 190 191 191 192 192 193 194 194 195 196 196 197 197 197 198 198 198 199 199 200 200 201 201 202 202 203 203 204 204 204 204 205 206 207 207 208 208 209 210 211 212 214 215 216 219 219 220 220 232 234 236 236 237 237 237 238 239 239 239 239 239 239 239 239 239 240 241 241 242 242 243 243 243 244 245 246 247 248 249 249 250 251 252 253 254 255 256 257 258 258 259 259 260 260 261 262 263 268 269 272 273 276 277 278 278 279 279 279 280 281 282 283 284 285 294 294 297 297 300 300 302 303 305 306 309 312 313 314 315 316 317 318 319 320 321 322 323 324 325 326 327 328 329 329 330 330 331 331 332 332 333 334 335 336 337 338 339 339 340 340 340 341 341 342 342 342 355 356 356 357 357 358 358 359 359 362 363 364 365 366 367 368 368 369 369 370 370 371 371 372 372 373 373 374 374 375 375 376 376 378 379 380 381 382 383 384 385 386 386 390 391 395 395 397 397 399 399 400 401 401 402 403 403 404 405 405 409 409 411 411 413 413 415 415 416 416 416 417 418 419 426 427 428 429 430 431 456 457 457 460 461 461 468 469 470 471 472 473 474 475 475 476 476 476 476 477 477 478 479 479 480 480 481 481 482 482 493 493 494 494 495 495 496 496 497 497 498 498 499 499 499 500 501 501 501 502 503 503 503 504 505 505 505 506 507 507 507 508 509 509 509 510 519 520 521 523 523 524 525 525 526 527 527 528 530 530 531 533 533 534 536 536 537 538 538 539 540 540 541 542 542 543 544 544 545 545 545 546 547 548 559 560 562 563 571 572 573 573 574 574 574 575 575 576 576 577 578 588 589 589 590 592 593 593 594 596 597 597 598 600 601 602 602 603 603 604 605 606 606 607 607 608 609 610 610 611 611 612 613 614 614 615 615 616 617 618 618 619 619 620 621 622 622 623 623 627 627 628 630 630 631 633 633 634 636 637 639 640 642 643 645 645 646 648 648 649 651 651 652 654 654 654 655 655 655 656 657 658 668 669 670 670 671 672 673 674 675 676 676 695 695 696 701 701 702 707 707 708 713 713 714 719 719 720 725 725 726 751 752 753 754 755 756 762 763 768 769 770)

	local -Ar od=(' ' '\040' '!' '\041' '"' '\042' '#' '\043' '$' '\044' '%' '\045' '&' '\046' \' '\047' '(' '\050' ')' '\051' '*' '\052' '+' '\053' ',' '\054' '-' '\055' '.' '\056' '/' '\057' '0' '\060' '1' '\061' '2' '\062' '3' '\063' '4' '\064' '5' '\065' '6' '\066' '7' '\067' '8' '\070' '9' '\071' ':' '\072' ';' '\073' '<' '\074' '=' '\075' '>' '\076' '?' '\077' '@' '\100' 'A' '\101' 'B' '\102' 'C' '\103' 'D' '\104' 'E' '\105' 'F' '\106' 'G' '\107' 'H' '\110' 'I' '\111' 'J' '\112' 'K' '\113' 'L' '\114' 'M' '\115' 'N' '\116' 'O' '\117' 'P' '\120' 'Q' '\121' 'R' '\122' 'S' '\123' 'T' '\124' 'U' '\125' 'V' '\126' 'W' '\127' 'X' '\130' 'Y' '\131' 'Z' '\132' '[' '\133' '\' '\134' ']' '\135' '^' '\136' '_' '\137' '`' '\140' 'a' '\141' 'b' '\142' 'c' '\143' 'd' '\144' 'e' '\145' 'f' '\146' 'g' '\147' 'h' '\150' 'i' '\151' 'j' '\152' 'k' '\153' 'l' '\154' 'm' '\155' 'n' '\156' 'o' '\157' 'p' '\160' 'q' '\161' 'r' '\162' 's' '\163' 't' '\164' 'u' '\165' 'v' '\166' 'w' '\167' 'x' '\170' 'y' '\171' 'z' '\172' '{' '\173' '|' '\174' '}' '\175' '~' '\176')

	if [ $# -eq 1 ]
	then
		build $(target "$1") "$1"
	else
		build 0
	fi
}

if [ $# -eq 1 ]
then
	if [ -f "$1" ]
	then
		walk $(awk '{ match($0, /^\t+/); gsub(/^\t+/, ""); print (NR - 1) ":" (RLENGTH > 0 ? RLENGTH : 0) ":0:" $0 }' "$1")
	else
		main "$1"
	fi
elif [ $# -eq 0 ]
then
	main
fi
