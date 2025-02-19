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

emit_addDouble () {
	local -ar children=(${@:1:2})
	local -i child=0
	local -a Result
	for child in ${children[@]}
	do
		for built in $(emit $child ${context:0:1}'0')
		do
			Result[${#Result[@]}]=$built
		done
	done

	echo '$(echo\040'$(join '\040' ${Result[@]})'\040|\040awk\040'\''{\040print\040$1\040+\040$2\040}'\'')'
}

emit_assignDouble () {
	local -ar children=(${@:1:2})
	local name=${T[${children[0]}]}
	local value=${T[${children[1]}]}

	if [ $name = 'dot' ]
	then
		name=$(join '\040' $(emit ${children[0]} ${context:0:1}'0'))
	fi

	if [ ${#value} -eq 1 ]
	then
		value='$'$value
	else
		value=$(join '\040' $(emit ${children[1]} ${context:0:1}'0'))
	fi

	echo $name'='$value'\n'
}

emit_assignVector3d () {
	local -ar children=(${@:1:2})

	echo ${T[${children[0]}]}'='$(join '\040' $(emit ${children[1]} ${context:0:1}'0'))'\n'
}

emit_averageVector3d () {
	local -ar children=(${@:1:2})
	local name=${T[${children[0]}]}
	local value=${T[${children[1]}]}

	echo '($(echo\040${'$name'[0]}\040${'$value'[0]}\040|\040awk\040'\''{\040print\040$1\040/\0402\040+\040$2\040/\0402\040}'\'') $(echo\040${'$name'[1]}\040${'$value'[1]}\040|\040awk\040'\''{\040print\040$1\040/\0402\040+\040$2\040/\0402\040}'\'') $(echo\040${'$name'[2]}\040${'$value'[2]}\040|\040awk\040'\''{\040print\040$1\040/\0402\040+\040$2\040/\0402\040}'\''))'
}

emit_compareDouble () {
	local -ar children=(${@:1:3})
	local -a Result
	Result[0]=$(join '\040' $(emit ${children[0]} ${context:0:1}'0'))
	Result[1]=$(join '\040' $(emit ${children[1]} ${context:0:1}'0'))
	Result[1]=${Result[1]/-lt/'<'}
	Result[1]=${Result[1]/-gt/'>'}
	Result[2]=$(join '\040' $(emit ${children[2]} ${context:0:1}'0'))

	echo '[\040$(echo\040'${Result[0]}'\040${'${Result[2]}'}\040|\040awk\040'\''{\040print\040$1\040'${Result[1]}'\040$2\040}'\'')\040-gt\0400\040]'
}

emit_compareInt () {
	local -ar children=(${@:1:3})
	local -i child=0
	local -a Result
	for child in ${children[@]}
	do
		for built in $(emit $child ${context:0:1}'0')
		do
			Result[${#Result[@]}]=$built
		done
	done

	echo '[\040'$(join '\040' ${Result[@]})'\040]'
}

emit_call () {
	local -r name=${1:?}
	local -a children=(${@:2})

	local -i child=0
	local -a Result
	for child in ${children[@]}
	do
		for built in $(emit $child ${context:0:1}'0')
		do
			Result[${#Result[@]}]=$built
		done
	done

	case $name in
		sqrt)
			Result[0]='echo\040'${Result[0]}'\040|\040awk\040'\''{\040print\040sqrt($1)\040}'\'

			;;
		*)
			if [ ${#Result[@]} -eq 0 ]
			then
				Result[0]=$(octal $name)
			else
				Result[0]=$(octal $name)'\040'$(join '\040' ${Result[@]})
			fi

			;;
	esac

	if [ ${context:1:1} -eq 1 ]
	then
		echo ${Result[0]}'\n'
	else
		echo '$('${Result[0]}')'
	fi
}

emit_divideDouble () {
	local -ar children=(${@:1:2})
	local -i child=0
	local -a Result
	for child in ${children[@]}
	do
		for built in $(emit $child ${context:0:1}'0')
		do
			Result[${#Result[@]}]=$built
		done
	done

	echo '$(echo\040'$(join '\040' ${Result[@]})'\040|\040awk\040'\''{\040print\040$1\040/\040$2\040}'\'')'
}

emit_dot() {
	local -ar children=(${@:1:2})
	local -r name=${T[${children[0]}]}
	local -r parameter=${T[${children[1]}]}
	case $name in
		triangles)
			case $parameter in
				size)
					echo '${#elements[@]}'
					;;
			esac
			;;
		v1)
			case $parameter in
				x)
					echo '$1'
					;;
				y)
					echo '$2'
					;;
				z)
					echo '$3'
					;;
			esac
			;;
		vertex)
			case $parameter in
				x)
					echo '${vertices[$((3\040*\040$i))]}'
					;;
				y)
					echo '${vertices[$((3\040*\040$i\040+\0401))]}'
					;;
				z)
					echo '${vertices[$((3\040*\040$i\040+\0402))]}'
					;;
			esac
			;;
		*)
			case $parameter in
				x)
					echo $name'[0]'
					;;
				y)
					echo $name'[1]'
					;;
				z)
					echo $name'[2]'
					;;
			esac
			;;
	esac
}

emit_double () {
	echo ${T[${1:?}]}
}

emit_for () {
	local -ar children=(${@:1})
	local -i child=0
	local -a Result=('for\040((')

	local parameters=$(join '\040' $(emit ${children[0]} ${context:0:1}'0'))
	Result[0]=${Result[0]}'\040'$parameters

	parameters=$(join '\040' $(emit ${children[1]} ${context:0:1}'0'))
	parameters=${parameters:6:-2}
	parameters=${parameters/-lt/'<'}
	Result[0]=${Result[0]}'\040;\040'$parameters

	parameters=$(join '\040' $(emit ${children[2]} ${context:0:1}'0'))
	Result[0]=${Result[0]}'\040;\040'$parameters'\040))\n'

	Result[1]='do\n'
	for built in $(emit ${children[3]} ${context:0:1}'1')
	do
		Result[${#Result[@]}]=$built
	done
	Result[${#Result[@]}]='done\n'

	echo ${Result[@]}
}

emit_function () {
	local -a Result=($(octal ${1:?})'\040()\040{\n')
	local -i child=0

	for child in ${children[@]}
	do
		for built in $(emit $child '0'${context:1})
		do
			Result[${#Result[@]}]='\t'$built
		done
	done

	echo '\n'${Result[@]}'}\n'
}

emit_glue () {
	local -ar children=(${@:1})
	local -i child=0
	local -a Result
	for child in ${children[@]}
	do
		for built in $(emit $child ${context:0:1}'1')
		do
			Result[${#Result[@]}]='\t'$built
		done
	done

	echo ${Result[@]}
}

emit_identifier () {
	echo '$'${T[${1:?}]}
}

emit_if () {
	local -ar children=(${@:1})
	local -i size=${#children[@]}
	local -i child=0
	local -a Result

	for child in ${children[0]}
	do
		for built in $(emit $child ${context:0:1}'0')
		do
			Result[${#Result[@]}]=$built
		done
	done
	Result='if\040'$(join '\040' ${Result[@]})'\n'

	Result[${#Result[@]}]='then\n'
	for child in ${children[1]}
	do
		for built in $(emit $child ${context:0:1}'1')
		do
			Result[${#Result[@]}]=$built
		done
	done

	if [ $size -eq 3 ]
	then
		Result[${#Result[@]}]='else\n'
		for child in ${children[2]}
		do
			for built in $(emit $child ${context:0:1}'1')
			do
				Result[${#Result[@]}]=$built
			done
		done
	fi

	Result[${#Result[@]}]='fi\n'

	echo ${Result[@]}
}

emit_increment () {
	local Result=$(emit ${1:?} ${context:0:1}'0')
	echo '++'${Result:1}
}

emit_int () {
	echo ${T[${1:?}]}
}

emit_minusDouble () {
	local -ar children=(${@:1:2})
	local -i child=0
	local -a Result
	for child in ${children[@]}
	do
		for built in $(emit $child ${context:0:1}'0')
		do
			Result[${#Result[@]}]=$built
		done
	done

	echo '$(echo\040'$(join '\040' ${Result[@]})'\040|\040awk\040'\''{\040print\040$1\040-\040$2\040}'\'')'
}

emit_minusVector3d () {
	local -ar children=(${@:1:2})
	local name=${T[${children[0]}]}
	local value=${T[${children[1]}]}

	echo '($(echo\040${'$name'[0]}\040${'$value'[0]}\040|\040awk\040'\''{\040print\040$1\040-\040$2\040}'\'') $(echo\040${'$name'[1]}\040${'$value'[1]}\040|\040awk\040'\''{\040print\040$1\040-\040$2\040}'\'') $(echo\040${'$name'[2]}\040${'$value'[2]}\040|\040awk\040'\''{\040print\040$1\040-\040$2\040}'\''))'
}

emit_multiplyDouble () {
	local -ar children=(${@:1:2})
	local -i child=0
	local -a Result
	for child in ${children[@]}
	do
		for built in $(emit $child ${context:0:1}'0')
		do
			Result[${#Result[@]}]=$built
		done
	done

	echo '$(echo\040'$(join '\040' ${Result[@]})'\040|\040awk\040'\''{\040print\040$1\040*\040$2\040}'\'')'
}

emit_operator () {
	local -r name=${T[${1:?}]}
	case $name in
		eq)
			echo '-eq'
			;;
		ge)
			echo '-ge'
			;;
		gt)
			echo '-gt'
			;;
		le)
			echo '-le'
			;;
		lt)
			echo '-lt'
			;;
		ne)
			echo '-ne'
			;;
	esac
}

emit_return () {
	local -r child=${1:?}
	local -a Result

	for built in $(emit $child ${context:0:1}'0')
	do
		Result[${#Result[@]}]=$built
	done

	echo 'echo\040'${Result[@]}'\n'
}

emit_type() {
	local -ar children=(${@:1})
	local -i child=0
	local -a Result
	for child in ${children[@]}
	do
		Result[${#Result[@]}]=${T[$child]}
	done

	echo $(join '\040' ${Result[@]})
}

emit_var() {
	local -i cut=${1:?}
	local -a parameters=(${@:2})
	local -i size=${#parameters[@]}

	local -a attributes
	local name=
	local value=

	local -i child=0
	local Result

	if [ ${context:0:1} -eq 1 ]
	then
		attributes[0]='declare'
	else
		attributes[0]='local'
	fi

	if [ $cut -eq 1 ]
	then
		case ${parameters[0]} in
			*'[]')
				attributes[1]='-a'
				;;
			Vector3d)
				attributes[1]='-a'

				if [ $size -lt 3 ]
				then
					value='(0\0400\0400)'
				fi
				;;
			Grid)
				attributes[1]='-A'
				;;
		esac

		case ${parameters[0]} in
			int)
				attributes[${#attributes[@]}]='-i'
				;;
		esac

		name=${parameters[1]}

		if [ $size -gt 2 ]
		then
			value=${parameters[2]}
		fi
	else
		name=$(join '\040' $(emit ${parameters[1]} $context))
		name=${name:1}

		if [ $size -gt 2 ]
		then
			value=$(join '\040' $(emit ${parameters[2]} $context))
		fi
	fi

	if [[ -n $name && -n $value ]]
	then
		Result=$name'='$value
	else
		Result=$name
	fi

	if [ ${context:1:1} -eq 1 ]
	then
		if [ ${#attributes[@]} -gt 0 ]
		then
			Result=$(join '\040' ${attributes[@]})'\040'$Result
		fi
		Result=$Result'\n'
	fi

	echo $Result
}

emit_vertex () {
	local -i name=${1:?}

	echo '($vertices[$((3\040*\040'$name'))]\040$vertices[$((3\040*\040'$name'\040+\0401))]\040$vertices[$((3\040*\040'$name'\040+\0402))])'
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
				for child in ${children[@]}
				do
					if [ $child -gt 0 ]
					then
						for built in $(emit $child $context)
						do
							Result[${#Result[@]}]=$built
						done
					fi
				done

				;;
			addDouble)
				Result=($(emit_addDouble ${children[@]}))

				;;
			assignDouble)
				Result=($(emit_assignDouble ${children[@]:0:2}))

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
			compareDouble)
				Result=($(emit_compareDouble ${children[@]}))

				;;
			compareInt)
				Result=($(emit_compareInt ${children[@]}))

				;;
			divideDouble)
				Result=($(emit_divideDouble ${children[@]}))

				;;
			dot)
				Result=($(emit_dot ${children[@]}))

				;;
			double)
				Result=($(emit_double ${children[@]:0:1}))

				;;
			for)
				Result=($(emit_for ${children[@]}))

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
				Result=($(emit_identifier ${children[@]:0:1}))

				;;
			if)
				Result=($(emit_if ${children[@]}))

				;;
			increment)
				Result=($(emit_increment ${children[@]:0:1}))

				;;
			int)
				Result=($(emit_int ${children[@]:0:1}))

				;;
			minusDouble)
				Result=($(emit_minusDouble ${children[@]}))

				;;
			minusVector3d)
				Result=($(emit_minusVector3d ${children[@]:0:2}))

				;;
			multiplyDouble)
				Result=($(emit_multiplyDouble ${children[@]}))

				;;
			operator)
				Result=($(emit_operator ${children[@]:0:1}))

				;;
			return)
				Result=($(emit_return ${children[0]}))
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
			vertex:*)
				parameters=($(cut ':' $root))
				Result=($(emit_vertex ${parameters[1]}))

				;;
		esac
	fi

	echo ${Result[@]}
}

target () {
	local -Ar targets=('bash' 1 'java' 2)
	echo ${targets[$1]:?}
}

build () {
	local -ir index=$((${1:?} - 1))
	local -ar subdirs=('bash' 'java')
	local -r mesh2cubes='mesh2cubes'
	local -ar extensions=('sh' 'java')

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

	local -ar T=('mesh2cubes' 'var:int,size,0' 'var:double[],vertices' 'var:int[],elements' 'var:Grid,grid' 'var:Vector3d,min' 'var:Vector3d,max' 'var:Vector3d,mid' 'var:double,c,1' 'var:double,t,1' 'var:double,xr,0' 'var:double,yr,0' 'var:double,zr,0' 'function:length,Vector3d,v1' 'function:translate' 'function:cube,Vector3d,v1' 'function:triangle,Vector3d,A,Vector3d,B,Vector3d,C' 'function:triangles' 'return' 'if' 'var' 'var' 'var' 'assignGrid' 'var' 'var' 'var' 'var' 'for' 'call:sqrt' 'compareInt' 'glue' 'type' 'identifier' 'floor' 'type' 'identifier' 'floor' 'type' 'identifier' 'floor' 'identifier' 'identifier' 'identifier' 'type' 'identifier' 'minusVector3d' 'type' 'identifier' 'minusVector3d' 'type' 'identifier' 'double' 'type' 'identifier' 'double' 'var' 'compareInt' 'assignInt' 'glue' 'addDouble' 'identifier' 'operator' 'int' 'assignVector3d' 'assignVector3d' 'for' 'assignVector3d' 'for' 'assignVector3d' 'assignDouble' 'assignDouble' 'assignDouble' 'assignDouble' 'assignDouble' 'double' 'x' 'addDouble' 'double' 'y' 'addDouble' 'double' 'z' 'addDouble' 'x' 'y' 'z' 'vector3d' 'u' 'identifier' 'identifier' 'vector3d' 'v' 'identifier' 'identifier' 'double' 'IIuII' 'call:length' 'double' 'IIvII' 'call:length' 'type' 'identifier' 'int' 'identifier' 'operator' 'dot' 'identifier' 'addInt' 'call:triangle' 'addDouble' 'multiplyDouble' 'size' 'gt' '0' 'min' 'vertex:0' 'max' 'vertex:0' 'var' 'compareInt' 'increment' 'glue' 'mid' 'averageVector3d' 'var' 'compareInt' 'increment' 'glue' 'max' 'minusVector3d' 'c' 'divideDouble' 't' 'c' 'xr' 'ceil' 'yr' 'ceil' 'zr' 'ceil' 'divideDouble' '0.5' 'divideDouble' '0.5' 'divideDouble' '0.5' 'B' 'A' 'B' 'A' 'identifier' 'identifier' 'int' 'i' '0' 'i' 'lt' 'triangles' 'size' 'i' 'identifier' 'int' 'triangle' 'multiplyDouble' 'multiplyDouble' 'dot' 'dot' 'type' 'identifier' 'int' 'identifier' 'operator' 'identifier' 'identifier' 'var' 'var' 'var' 'if' 'if' 'if' 'if' 'if' 'if' 'min' 'max' 'type' 'identifier' 'int' 'identifier' 'operator' 'identifier' 'identifier' 'assignVector3d' 'max' 'mid' 'call:length' '25' 'minusDouble' 'minusDouble' 'minusDouble' 'dot' 'identifier' 'dot' 'identifier' 'dot' 'identifier' 'u' 'v' 'i' '3' 'identifier' 'dot' 'dot' 'dot' 'dot' 'v1' 'x' 'v1' 'x' 'int' 'i' '1' 'i' 'lt' 'size' 'i' 'type' 'identifier' 'dot' 'type' 'identifier' 'dot' 'type' 'identifier' 'dot' 'compareDouble' 'glue' 'compareDouble' 'glue' 'compareDouble' 'glue' 'compareDouble' 'glue' 'compareDouble' 'glue' 'compareDouble' 'glue' 'int' 'i' '0' 'i' 'lt' 'size' 'i' 'vertex' 'minusVector3d' 'max' 'divideDouble' 'double' 'divideDouble' 'double' 'divideDouble' 'double' 'v1' 'x' 'c' 'v1' 'y' 'c' 'v1' 'z' 'c' 'i' 'v1' 'y' 'v1' 'y' 'v1' 'z' 'v1' 'z' 'double' 'x' 'vertex' 'x' 'double' 'y' 'vertex' 'y' 'double' 'z' 'vertex' 'z' 'identifier' 'operator' 'dot' 'assignDouble' 'identifier' 'operator' 'dot' 'assignDouble' 'identifier' 'operator' 'dot' 'assignDouble' 'identifier' 'operator' 'dot' 'assignDouble' 'identifier' 'operator' 'dot' 'assignDouble' 'identifier' 'operator' 'dot' 'assignDouble' 'identifier' 'vertex' 'mid' 'dot' 'identifier' '0.5' 'dot' 'identifier' '0.5' 'dot' 'identifier' '0.5' 'identifier' 'identifier' 'identifier' 'x' 'lt' 'min' 'x' 'dot' 'identifier' 'y' 'lt' 'min' 'y' 'dot' 'identifier' 'z' 'lt' 'min' 'z' 'dot' 'identifier' 'x' 'gt' 'max' 'x' 'dot' 'identifier' 'y' 'gt' 'max' 'y' 'dot' 'identifier' 'z' 'gt' 'max' 'z' 'dot' 'identifier' 'i' 'identifier' 'max' 'x' 'c' 'max' 'y' 'c' 'max' 'z' 'c' 'i' 'i' 'i' 'min' 'x' 'x' 'min' 'y' 'y' 'min' 'z' 'z' 'max' 'x' 'x' 'max' 'y' 'y' 'max' 'z' 'z' 'i')
	local -ar parent=(0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 13 14 15 15 15 15 16 16 16 16 17 18 19 19 20 20 20 21 21 21 22 22 22 23 23 23 24 24 24 25 25 25 26 26 26 27 27 27 28 28 28 28 29 30 30 30 31 31 31 31 31 31 31 31 31 31 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 46 47 48 49 49 50 51 52 53 54 55 56 56 56 57 57 57 58 58 59 60 60 61 62 63 64 64 65 65 66 66 66 66 67 67 68 68 68 68 69 69 70 70 71 71 72 72 73 73 74 74 77 77 80 80 83 83 89 90 93 94 97 100 101 102 103 104 105 106 106 107 108 108 109 110 110 111 111 119 119 119 120 120 120 121 122 122 122 122 122 122 122 122 122 124 124 125 125 125 126 126 126 127 128 130 130 132 132 136 138 140 141 141 143 143 145 145 151 152 161 162 163 164 164 165 165 166 166 167 167 168 169 170 171 172 173 174 175 175 175 176 176 176 177 177 177 178 178 179 179 180 180 181 181 182 182 183 183 186 187 188 189 190 191 192 193 193 196 198 198 199 199 200 200 201 201 202 203 203 204 205 205 206 211 212 212 213 213 214 214 215 215 227 228 229 229 230 231 232 232 233 234 235 235 236 236 236 237 238 238 238 239 240 240 240 241 242 242 242 243 244 244 244 245 246 246 246 247 255 256 256 258 258 259 260 260 261 262 262 263 284 288 292 294 295 296 296 297 297 298 299 300 300 301 301 302 303 304 304 305 305 306 307 308 308 309 309 310 311 312 312 313 313 314 315 316 316 317 317 318 319 321 321 322 324 324 325 327 327 328 330 331 332 337 337 338 343 343 344 349 349 350 355 355 356 361 361 362 367 367 368 370)

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
	if [ -f $1 ]
	then
		walk $(awk '{ match($0, /^\t+/); gsub(/^\t+/, ""); print (NR - 1) ":" (RLENGTH > 0 ? RLENGTH : 0) ":0:" $0 }' $1)
	else
		main $(target $1)
	fi
elif [ $# -eq 0 ]
then
	main 0
fi
