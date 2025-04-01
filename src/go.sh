#!/usr/bin/env bash

lvalue () {
	echo $(join '\040' $(emit ${1:?} ${context:0:1}'0'))
}

rvalue () {
	echo $(join '\040' $(emit ${1:?} ${context:0:1}'0'))
}

emit_mesh2cubes () {
	local -a Result
	Result[0]='package\040mesh2cubes\n\n'
	Result[1]='import\040"fmt"\n'
	Result[2]='import\040"math"\n\n'
	local -i size=3

	for child in ${children[@]}
	do
		if [ $child -gt 0 ]
		then
			case ${T[$child]} in
				function:*)
					Result[$(($size - 1))]+='\n'
					;;
			esac

			for built in $(emit $child $context)
			do
				Result[$size]=$built
				size+=1
			done
		fi
	done

	echo ${Result[@]}
}

emit_addAssignDouble () {
	local -r Result=$(lvalue ${1:?})'\040+=\040'$(rvalue ${2:?})

	if [ ${context:1:1} -eq 1 ]
	then
		echo $Result'\n'
	else
		echo $Result
	fi
}

emit_addAssignInt () {
	local -r Result=$(lvalue ${1:?})'\040+=\040'$(rvalue ${2:?})

	if [ ${context:1:1} -eq 1 ]
	then
		echo $Result'\n'
	else
		echo $Result
	fi
}

emit_addAssignVector3d () {
	local -r name=$(lvalue ${1:?})
	local -r value=$(lvalue ${2:?})
	local -a Result

	Result[0]=$name'[0]\040+=\040'$value'[0]\n'
	Result[1]=$name'[1]\040+=\040'$value'[1]\n'
	Result[2]=$name'[2]\040+=\040'$value'[2]\n'

	echo ${Result[@]}
}

emit_addDouble () {
	echo $(rvalue ${1:?})'\040+\040'$(rvalue ${2:?})
}

emit_addInt () {
	echo $(rvalue ${1:?})'\040+\040'$(rvalue ${2:?})
}

emit_addLow () {
	echo $(rvalue ${1:?})
}

emit_and () {
	echo $(rvalue ${1:?})'\040&&\040'$(rvalue ${2:?})
}

emit_assignDouble () {
	echo $(lvalue ${1:?})'\040=\040'$(rvalue ${2:?})'\n'
}

emit_assignGrid () {
	echo 'm2c.Grid[fmt.Sprintf("\045d,\045d,\045d",\040'$(rvalue ${1:?})',\040'$(rvalue ${2:?})',\040'$(rvalue ${3:?})')]\040=\040true\n'
}

emit_assignInt () {
	echo $(lvalue ${1:?})'\040=\040'$(rvalue ${2:?})'\n'
}

emit_assignVector3d () {
	echo $(lvalue ${1:?})'\040=\040'$(rvalue ${2:?})'\n'
}

emit_averageVector3d () {
	local -r name=$(lvalue ${1:?})
	local -r value=$(lvalue ${2:?})

	echo '[3]float64\040{'$name'[0]\040/\0402.0\040+\040'$value'[0]\040/\0402.0,\040'$name'[1]\040/\0402.0\040+\040'$value'[1]\040/\0402.0,\040'$name'[2]\040/\0402.0\040+\040'$value'[2]\040/\0402.0}'
}

emit_call () {
	local -r name=${1:?}
	local -ar children=(${@:2})
	local -ir size=${#children[@]}

	local -i child=0
	local -a Result

	if [ $size -eq 0 ]
	then
		Result[0]=$(octal $name)'()'
	else
		for child in ${children[@]}
		do
			Result[${#Result[@]}]=$(rvalue $child)
		done

		Result[1]=$(join ',\040' ${Result[@]})')'

		case $name in
			length)
				Result[1]='('${Result[1]}
				Result[2]=$(octal ${name@u})
				;;
			sqrt)
				Result[1]='('${Result[1]}
				Result[2]='math.'$(octal ${name@u})
				;;
			*)
				Result[1]='(m2c,\040'${Result[1]}
				Result[2]=$(octal ${name@u})
				;;
		esac

		Result[0]=${Result[2]}${Result[1]}
	fi

	if [ ${context:1:1} -eq 1 ]
	then
		echo ${Result[0]}'\n'
	else
		echo ${Result[0]}
	fi
}

emit_ceil () {
	echo 'uint64(math.Ceil('$(rvalue ${1:?})'))'
}

emit_compareDouble () {
	local -a Result
	Result[0]=$(rvalue ${1:?})
	Result[1]=$(rvalue ${2:?})
	Result[2]=$(rvalue ${3:?})

	echo $(join '\040' ${Result[@]})
}

emit_compareInt () {
	local -a Result
	Result[0]=$(rvalue ${1:?})
	Result[1]=$(rvalue ${2:?})
	Result[2]=$(rvalue ${3:?})

	echo $(join '\040' ${Result[@]})
}

emit_compareLow () {
	echo
}

emit_constructor () {
	local -ar children=(${@:1})
	local -i child=0

	local -a Result
	Result[0]='type\040T\040struct\040{\n'
	local -i size=1
	for child in ${children[@]}
	do
		case ${T[$child]:4} in
			count|xl|yl|zl)
				;;
			*)
				for built in $(emit $child '1'${context:1})
				do
					Result[$size]=${built#var\\040}
					Result[$size]='\t'${Result[$size]@u}
					size+=1
				done
				;;
		esac
	done
	Result[$size]='}\n'
	size+=1

	if [ $size -gt 2 ]
	then
		Result[$(($size - 1))]+='\n'

		Result[$size]='func\040New()\040*T\040{\n'
		size+=1
		Result[$size]='\tvar\040m2c\040*T\040=\040new(T)\n'
		size+=1

		for child in ${children[@]}
		do
			case ${T[$child]:4} in
				count|vertices|elements|xl|yl|zl)
					continue
					;;
			esac

			for built in $(emit $child '0'${context:1})
			do
				Result[$size]=${built#[^\\]*\\040}
				Result[$size]='\tm2c.'${Result[$size]@u}
				Result[$size]=${Result[$size]/\\040*\\040=\\040/\\040=\\040}
				size+=1
			done
		done

		Result[$size]='\treturn\040m2c\n'
		size+=1
		Result[$size]='}\n'
		size+=1
	fi

	echo ${Result[@]}
}

emit_declarations () {
	local -ar children=(${@:1})
	local -i child=0
	local -a Result
	for child in ${children[@]}
	do
		for built in $(emit $child $context)
		do
			case ${built:7} in
				i*|count*|y1*|y2*)
					Result[${#Result[@]}]=$built
					;;
			esac
		done
	done

	echo ${Result[@]}
}

emit_declarationsBody () {
	local -ar children=(${@:1})
	local -i child=0
	local -a Result
	for child in ${children[@]}
	do
		for built in $(emit $child $context)
		do
			Result[${#Result[@]}]=$built
		done
	done

	echo ${Result[@]}
}

emit_divideDouble () {
	echo $(rvalue ${1:?})'\040/\040'$(rvalue ${2:?})
}

emit_dot() {
	local -r name=${T[${1:?}]}
	local -r parameter=${T[${2:?}]}

	case $name in
		triangles)
			case $parameter in
				size)
					echo 'uint64(len(m2c.Elements))'
					;;
			esac
			;;
		v1)
			case $parameter in
				x)
					echo 'v1[0]'
					;;
				y)
					echo 'v1[1]'
					;;
				z)
					echo 'v1[2]'
					;;
			esac
			;;
		*)
			case $parameter in
				x)
					echo 'm2c.'${name@u}'[0]'
					;;
				y)
					echo 'm2c.'${name@u}'[1]'
					;;
				z)
					echo 'm2c.'${name@u}'[2]'
					;;
			esac
			;;
	esac
}

emit_dotCount () {
	echo 'count'
}

emit_dotVertex () {
	local -r name=$(rvalue ${1:?})

	case ${T[${2:?}]} in
		x)
			echo 'm2c.Vertices[3\040*\040'$name']'
			;;
		y)
			echo 'm2c.Vertices[3\040*\040'$name'\040+\0401]'
			;;
		z)
			echo 'm2c.Vertices[3\040*\040'$name'\040+\0402]'
			;;
	esac
}

emit_double () {
	echo ${T[${1:?}]}
}

emit_floor () {
	echo 'int64(math.Floor('$(rvalue ${1:?})'))'
}

emit_for () {
	local -a Result=('for\040'$(rvalue ${1:?})';\040'$(rvalue ${2:?})';\040'$(rvalue ${3:?})'\040{\n')

	for built in $(emit ${4:?} ${context:0:1}'1')
	do
		Result[${#Result[@]}]=$built
	done
	Result[${#Result[@]}]='}\n'

	echo ${Result[@]}
}

emit_forDouble () {
	local -a Result=('for\040'$(rvalue ${1:?})';\040'$(rvalue ${2:?})';\040'$(rvalue ${3:?})'\040{\n')

	for built in $(emit ${4:?} ${context:0:1}'1')
	do
		Result[${#Result[@]}]=$built
	done
	Result[${#Result[@]}]='}\n'

	echo ${Result[@]}
}

emit_function () {
	local -r name=${1:?}
	local -r parameters=$(rvalue ${3:?})
	local -r context='0'${context:1}

	local -a Result
	Result[0]=$(rvalue ${2:?})
	Result[1]='func\040'$(octal ${name@u})$parameters
	local -i size=1

	if [ $name != 'length' ]
	then
		if [ $parameters = '()' ]
		then
			Result[1]=${Result[1]/\(/\(m2c\\040*T}
		else
			Result[1]=${Result[1]/\(/\(m2c\\040*T,\\040}
		fi
	fi

	case ${Result[0]} in
		void)
			Result[0]=${Result[1]}
			;;
		*)
			Result[0]=${Result[1]}'\040'${Result[0]}
			;;
	esac
	Result[0]+='\040{\n'

	for built in $(emit_glue ${@:4})
	do
		Result[$size]=$built
		size+=1
	done
	Result[$size]='}\n'
	size+=1

	echo ${Result[@]}
}

emit_glue () {
	local -ar children=(${@:1})
	local -i child=0
	local -i size=0
	local -a Result
	for child in ${children[@]}
	do
		if [ $size -gt 0 ]
		then
			case ${T[$child]} in
				if|ifAssignGrid|for|forDouble)
					Result[$(($size - 1))]+='\n'
					;;
			esac
		fi

		for built in $(emit $child ${context:0:1}'1')
		do
			Result[$size]='\t'$built
			size+=1
		done
	done

	echo ${Result[@]}
}

emit_identifier () {
	echo ${T[${1:?}]}
}

emit_identifierThis () {
	echo 'm2c.'${T[${1:?}]@u}
}

emit_identifierVector3d () {
	local -r name=${T[${1:?}]}

	echo '[3]float64\040{'$name'[0],\040'$name'[1],\040'$name'[2]}'
}

emit_if () {
	local -ar children=(${@:1})
	local -ir size=${#children[@]}
	local -i child=0
	local -a Result

	Result[0]='if\040'$(rvalue ${children[0]:?})'\040{\n'

	for built in $(emit ${children[1]:?} ${context:0:1}'1')
	do
		Result[${#Result[@]}]=$built
	done

	if [ $size -eq 3 ]
	then
		Result[${#Result[@]}]='}\040else\040{\n'
		for built in $(emit ${children[2]:?} ${context:0:1}'1')
		do
			Result[${#Result[@]}]=$built
		done
	fi

	Result[${#Result[@]}]='}\n'

	echo ${Result[@]}
}

emit_ifAssignGrid () {
	local -r Result=$(rvalue ${2:?})

	echo ${Result:2}
}

emit_increment () {
	echo $(lvalue ${1:?})'\040+=\0401'
}

emit_int () {
	echo ${T[${1:?}]}
}

emit_min () {
	echo 'math.Min('$(rvalue ${1:?})',\040'$(rvalue ${2:?})')'
}

emit_minusAssignVector3d () {
	local -r name=$(lvalue ${1:?})
	local -r value=$(lvalue ${2:?})
	local -a Result

	Result[0]=$name'[0]\040-=\040'$value'[0]\n'
	Result[1]=$name'[1]\040-=\040'$value'[1]\n'
	Result[2]=$name'[2]\040-=\040'$value'[2]\n'

	echo ${Result[@]}
}

emit_minusAssignVertex () {
	local -r name=$(rvalue ${1:?})
	local -r value=$(lvalue ${2:?})
	local -a Result

	Result[0]='m2c.Vertices[3\040*\040'$name']\040-=\040'$value'[0]\n'
	Result[1]='m2c.Vertices[3\040*\040'$name'\040+\0401]\040-=\040'$value'[1]\n'
	Result[2]='m2c.Vertices[3\040*\040'$name'\040+\0402]\040-=\040'$value'[2]\n'

	echo ${Result[@]}
}

emit_minusDouble () {
	echo $(rvalue ${1:?})'\040-\040'$(rvalue ${2:?})
}

emit_minusVector3d () {
	local -r name=$(lvalue ${1:?})
	local -r value=$(lvalue ${2:?})

	echo '[3]float64\040{'$name'[0]\040-\040'$value'[0],\040'$name'[1]\040-\040'$value'[1],\040'$name'[2]\040-\040'$value'[2]}'
}

emit_multiplyDouble () {
	echo $(rvalue ${1:?})'\040*\040'$(rvalue ${2:?})
}

emit_multiplyInt () {
	echo $(rvalue ${1:?})'\040*\040'$(rvalue ${2:?})
}

emit_newGrid () {
	echo
}

emit_operator () {
	case ${T[${1:?}]} in
		eq)
			echo '=='
			;;
		ge)
			echo '>='
			;;
		gt)
			echo '>'
			;;
		le)
			echo '<='
			;;
		lt)
			echo '<'
			;;
		ne)
			echo '!='
			;;
	esac
}

emit_parameter () {
	echo $(rvalue ${2:?})'\040'$(rvalue ${1:?})
}

emit_parameters () {
	local -ar children=(${@:1})
	local -i child=0
	local -a Result
	for child in ${children[@]}
	do
		Result[${#Result[@]}]=$(rvalue $child)

		case ${Result[-1]} in
			v1\\040Vector3d)
				Result[-1]=${Result[-1]/Vector3d/[3]float64}
				;;
		esac
	done

	echo '('$(join ',\040' ${Result[@]})')'
}

emit_positional () {
	echo $(rvalue ${2:?})
}

emit_return () {
	echo 'return\040'$(rvalue ${1:?})'\n'
}

emit_scaleVector3d () {
	local -r name=$(lvalue ${1:?})
	local -r value=$(rvalue ${2:?})
	local -a Result

	Result[0]=$name'[0]\040*=\040'$value'\n'
	Result[1]=$name'[1]\040*=\040'$value'\n'
	Result[2]=$name'[2]\040*=\040'$value'\n'

	echo ${Result[@]}
}

emit_triangle () {
	local -a Result

	Result[0]=$(rvalue ${1:?})
	Result[1]='m2c.Elements['${Result[0]}'\040+\0401]'
	Result[2]='m2c.Elements['${Result[0]}'\040+\0402]'
	Result[0]='m2c.Elements['${Result[0]}']'

	echo $(join ',\040' ${Result[@]})
}

emit_type() {
	local -ar children=(${@:1})
	local -i child=0
	local -a Result
	for child in ${children[@]}
	do
		Result[${#Result[@]}]=${T[$child]}

		case ${Result[-1]} in
			*'[]')
				Result[-1]=${Result[-1]%'[]'}

				case ${Result[-1]} in
					index)
						Result[-1]='[]uint64'
						;;
					double)
						Result[-1]='[]float64'
						;;
					*)
						Result[-1]='[]'${Result[-1]}
						;;
				esac
				;;
			Grid)
				Result[-1]='map[string]bool'
				;;
			double)
				Result[-1]='float64'
				;;
			index|size*)
				Result[-1]='uint64'
				;;
			index.grid)
				Result[-1]='int64'
				;;
			static|const)
				Result[-1]=
				;;
		esac
	done

	echo ${Result[@]}
}

emit_var() {
	local name=${1:?}
	local -ar parameters=(${@:2})
	local -ir size=${#parameters[@]}

	local -a attributes=($(rvalue ${parameters[0]}))
	local value=
	local -a Result

	case ${attributes[@]} in
		*Vector3d*)
			if [ $size -gt 1 ]
			then
				value=$(rvalue ${parameters[1]})
			else
				value='[3]float64\040{0.0,\0400.0,\0400.0}'
			fi

			attributes=${attributes[@]/Vector3d/[3]float64}
			;;
		*map*)
			if [ $size -lt 2 ]
			then
				value='make(map[string]bool)'
			else
				value=$(rvalue ${parameters[1]})
			fi
			;;
		*)
			if [ $size -gt 1 ]
			then
				value=$(rvalue ${parameters[1]})
			fi
			;;
	esac

	if [ ${context:1:1} -eq 1 ]
	then
		Result[0]='var\040'$name

		if [ ${#attributes[@]} -gt 0 ]
		then
			Result[0]+='\040'$(join '\040' ${attributes[@]})
		fi
	else
		Result[0]=$name
	fi

	if [[ ${context:0:1} -eq 0 && -n $value ]]
	then
		Result[0]+='\040=\040'$value
	fi

	if [ ${context:1:1} -eq 1 ]
	then
		Result[0]=${Result[0]}'\n'
	fi

	echo ${Result[0]}
}

emit_vertex () {
	local -ir cut=${1:?}
	local -ir name=${2:?}
	local -a Result

	if [ $cut -eq 1 ]
	then
		Result[0]='m2c.Vertices['$((3 * $name))']'
		Result[1]='m2c.Vertices['$((3 * $name + 1))']'
		Result[2]='m2c.Vertices['$((3 * $name + 2))']'
	else
		Result[0]=$(rvalue $name)
		Result[1]='m2c.Vertices[3\040\052\040'${Result[0]}'\040+\0401]'
		Result[2]='m2c.Vertices[3\040\052\040'${Result[0]}'\040+\0402]'
		Result[0]='m2c.Vertices[3\040\052\040'${Result[0]}']'
	fi

	echo '[3]float64\040{'$(join ',\040' ${Result[@]})'}'
}

build_files () {
	build_file "${@:1:2}" 'go'
}

. ./build.sh go
