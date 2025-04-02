#!/usr/bin/env bash

lvalue () {
	echo $(join '\040' $(emit ${1:?} ${context:0:1}'0'))
}

rvalue () {
	echo $(join '\040' $(emit ${1:?} ${context:0:1}'0'))
}

emit_mesh2cubes () {
	local -a Result
	Result[0]='export\040class\040mesh2cubes\040{\n'
	local -i size=1

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
				Result[$size]='\t'$built
				size+=1
			done
		fi
	done
	Result[$size]='}\n'

	echo ${Result[@]}
}

emit_addAssignDouble () {
	local -r Result=$(lvalue ${1:?})'\040+=\040'$(rvalue ${2:?})

	if [ ${context:1:1} -eq 1 ]
	then
		echo $Result';\n'
	else
		echo $Result
	fi
}

emit_addAssignInt () {
	local -r Result=$(lvalue ${1:?})'\040+=\040'$(rvalue ${2:?})

	if [ ${context:1:1} -eq 1 ]
	then
		echo $Result';\n'
	else
		echo $Result
	fi
}

emit_addAssignVector3d () {
	local -r name=$(lvalue ${1:?})
	local -r value=$(lvalue ${2:?})
	local -a Result

	Result[0]=$name'[0]\040+=\040'$value'[0];\n'
	Result[1]=$name'[1]\040+=\040'$value'[1];\n'
	Result[2]=$name'[2]\040+=\040'$value'[2];\n'

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
	echo $(lvalue ${1:?})'\040=\040'$(rvalue ${2:?})';\n'
}

emit_assignGrid () {
	echo 'this.grid[`${'$(rvalue ${1:?})'},${'$(rvalue ${2:?})'},${'$(rvalue ${3:?})'}`]\040=\040true;\n'
}

emit_assignInt () {
	echo $(lvalue ${1:?})'\040=\040'$(rvalue ${2:?})';\n'
}

emit_assignVector3d () {
	local -ar value=($(cut ':' $(rvalue ${2:?})))

	echo $(lvalue ${1:?})'\040=\040['${value[0]}',\040'${value[1]}',\040'${value[2]}'];\n'
}

emit_averageVector3d () {
	local -r name=$(lvalue ${1:?})
	local -r value=$(lvalue ${2:?})

	echo $name'[0]\040/\0402.0\040+\040'$value'[0]\040/\0402.0:'$name'[1]\040/\0402.0\040+\040'$value'[1]\040/\0402.0:'$name'[2]\040/\0402.0\040+\040'$value'[2]\040/\0402.0'
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

		Result[0]=$(octal $name)'('$(join ',\040' ${Result[@]})')'

		case $name in
			length)
				Result[0]='mesh2cubes.'${Result[0]}
				;;
			sqrt)
				Result[0]='Math.'${Result[0]}
				;;
			*)
				Result[0]='this.'${Result[0]}
				;;
		esac
	fi

	if [ ${context:1:1} -eq 1 ]
	then
		echo ${Result[0]}';\n'
	else
		echo ${Result[0]}
	fi
}

emit_ceil () {
	echo 'Math.ceil('$(rvalue ${1:?})')'
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

	local -a Result=('constructor()\040{\n')
	local -i size=1
	for child in ${children[@]}
	do
		case ${T[$child]:4} in
			count|xl|yl|zl)
				continue
				;;
		esac

		for built in $(emit $child '0'${context:1})
		do
			Result[$size]='\tthis.'${built#[^\\]*\\040}
			size+=1
		done
	done
	Result[$size]='}\n'

	echo ${Result[@]}
}

emit_declarations () {
	echo
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
					echo 'this.'$name'[0]'
					;;
				y)
					echo 'this.'$name'[1]'
					;;
				z)
					echo 'this.'$name'[2]'
					;;
			esac
			;;
	esac
}

emit_dotCount () {
	echo 'this.elements.length'
}

emit_dotVertex () {
	local -r name=$(rvalue ${1:?})

	case ${T[${2:?}]} in
		x)
			echo 'this.vertices[3\040*\040'$name']'
			;;
		y)
			echo 'this.vertices[3\040*\040'$name'\040+\0401]'
			;;
		z)
			echo 'this.vertices[3\040*\040'$name'\040+\0402]'
			;;
	esac
}

emit_double () {
	echo ${T[${1:?}]}
}

emit_floor () {
	echo 'Math.floor('$(rvalue ${1:?})')'
}

emit_for () {
	local -a Result=('for\040('$(rvalue ${1:?})';\040'$(rvalue ${2:?})';\040'$(rvalue ${3:?})')\040{\n')

	for built in $(emit ${4:?} ${context:0:1}'1')
	do
		Result[${#Result[@]}]=$built
	done
	Result[${#Result[@]}]='}\n'

	echo ${Result[@]}
}

emit_forDouble () {
	local -a Result=('for\040('$(rvalue ${1:?})';\040'$(rvalue ${2:?})';\040'$(rvalue ${3:?})')\040{\n')

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
	Result[1]=$(octal $name)$parameters'\040{\n'
	local -i size=1

	case ${Result[0]} in
		*static*)
			Result[0]='static\040'${Result[1]}
			;;
		*)
			Result[0]=${Result[1]}
			;;
	esac

	for built in $(emit_glue ${@:4})
	do
		Result[$size]=$built
		size+=1
	done
	Result[$size]='}\n'

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
	echo 'this.'${T[${1:?}]}
}

emit_identifierVector3d () {
	local -r name=${T[${1:?}]}
	echo $name'[0]:'$name'[1]:'$name'[2]'
}

emit_if () {
	local -ar children=(${@:1})
	local -ir size=${#children[@]}
	local -i child=0
	local -a Result

	Result[0]='if\040('$(rvalue ${children[0]:?})')\040{\n'

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
	echo '++'$(lvalue ${1:?})
}

emit_int () {
	echo ${T[${1:?}]}
}

emit_min () {
	echo 'Math.min('$(rvalue ${1:?})',\040'$(rvalue ${2:?})')'
}

emit_minusAssignVector3d () {
	local -r name=$(lvalue ${1:?})
	local -r value=$(lvalue ${2:?})
	local -a Result

	Result[0]=$name'[0]\040-=\040'$value'[0];\n'
	Result[1]=$name'[1]\040-=\040'$value'[1];\n'
	Result[2]=$name'[2]\040-=\040'$value'[2];\n'

	echo ${Result[@]}
}

emit_minusAssignVertex () {
	local -r name=$(rvalue ${1:?})
	local -r value=$(lvalue ${2:?})
	local -a Result

	Result[0]='this.vertices[3\040*\040'$name']\040-=\040'$value'[0];\n'
	Result[1]='this.vertices[3\040*\040'$name'\040+\0401]\040-=\040'$value'[1];\n'
	Result[2]='this.vertices[3\040*\040'$name'\040+\0402]\040-=\040'$value'[2];\n'

	echo ${Result[@]}
}

emit_minusDouble () {
	echo $(rvalue ${1:?})'\040-\040'$(rvalue ${2:?})
}

emit_minusVector3d () {
	local -r name=$(lvalue ${1:?})
	local -r value=$(lvalue ${2:?})

	echo $name'[0]\040-\040'$value'[0]:'$name'[1]\040-\040'$value'[1]:'$name'[2]\040-\040'$value'[2]'
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
			echo '==='
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
			echo '!=='
			;;
	esac
}

emit_parameter () {
	echo $(rvalue ${2:?})
}

emit_parameters () {
	local -ar children=(${@:1})
	local -i child=0
	local -a Result
	for child in ${children[@]}
	do
		Result[${#Result[@]}]=$(rvalue $child)
	done

	echo '('$(join ',\040' ${Result[@]})')'
}

emit_positional () {
	echo $(rvalue ${2:?})
}

emit_return () {
	echo 'return\040'$(rvalue ${1:?})';\n'
}

emit_scaleVector3d () {
	local -r name=$(lvalue ${1:?})
	local -r value=$(rvalue ${2:?})
	local -a Result

	Result[0]=$name'[0]\040*=\040'$value';\n'
	Result[1]=$name'[1]\040*=\040'$value';\n'
	Result[2]=$name'[2]\040*=\040'$value';\n'

	echo ${Result[@]}
}

emit_triangle () {
	local -a Result

	Result[0]=$(rvalue ${1:?})
	Result[1]='this.elements['${Result[0]}'\040+\0401]'
	Result[2]='this.elements['${Result[0]}'\040+\0402]'
	Result[0]='this.elements['${Result[0]}']'

	echo $(join ',\040' ${Result[@]})
}

emit_type() {
	local -ar children=(${@:1})
	local -i child=0
	local -a Result
	for child in ${children[@]}
	do
		Result[${#Result[@]}]=${T[$child]}
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
		*'[]'*)
			if [ $size -gt 1 ]
			then
				value=$(rvalue ${parameters[1]})
			else
				value='[]'
			fi
			;;
		*Grid*)
			if [ $size -gt 1 ]
			then
				value=$(rvalue ${parameters[1]})
			else
				value='{}'
			fi
			;;
		*Vector3d*)
			if [ $size -gt 1 ]
			then
				value=$(rvalue ${parameters[1]})
				Result=($(cut ':' $value))

				if [ ${#Result[@]} -eq 3 ]
				then
					value='['${Result[0]}',\040'${Result[1]}',\040'${Result[2]}']'
				fi
			else
				value='[0.0,\0400.0,\0400.0]'
			fi
			;;
		*)
			if [ $size -gt 1 ]
			then
				value=$(rvalue ${parameters[1]})
			fi
			;;
	esac

	if [[ -n $name && -n $value ]]
	then
		Result[0]=$name'\040=\040'$value
	else
		Result[0]=$name
	fi

	case ${attributes[@]} in
		*const*)
			Result[0]='const\040'${Result[0]}
			;;
		*)
			Result[0]='let\040'${Result[0]}
			;;
	esac

	if [ ${context:1:1} -eq 1 ]
	then
		Result[0]=${Result[0]}';\n'
	fi

	echo ${Result[0]}
}

emit_vertex () {
	local -ir cut=${1:?}
	local -ir name=${2:?}
	local -a Result

	if [ $cut -eq 1 ]
	then
		Result[0]='this.vertices['$((3 * $name))']'
		Result[1]='this.vertices['$((3 * $name + 1))']'
		Result[2]='this.vertices['$((3 * $name + 2))']'
	else
		Result[0]=$(rvalue $name)
		Result[1]='this.vertices[3\040\052\040'${Result[0]}'\040+\0401]'
		Result[2]='this.vertices[3\040\052\040'${Result[0]}'\040+\0402]'
		Result[0]='this.vertices[3\040\052\040'${Result[0]}']'
	fi

	echo $(join ':' ${Result[@]})
}

build_files () {
	build_file "${@:1:2}" 'mjs'
}

. ./build.sh javascript
