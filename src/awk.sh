#!/usr/bin/env bash

lvalue () {
	echo $(join '\040' $(emit ${1:?} ${context:0:1}'0'))
}

rvalue () {
	echo $(join '\040' $(emit ${1:?} ${context:0:1}'0'))
}

emit_mesh2cubes () {
	local -a Result
	local -i size=0

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

	Result[0]=$name'[1]\040+=\040'$value'[1];\n'
	Result[1]=$name'[2]\040+=\040'$value'[2];\n'
	Result[2]=$name'[3]\040+=\040'$value'[3];\n'

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
	echo 'grid['$(rvalue ${1:?})'\040","\040'$(rvalue ${2:?})'\040","\040'$(rvalue ${3:?})']\040=\0401;\n'
}

emit_assignInt () {
	echo $(lvalue ${1:?})'\040=\040'$(rvalue ${2:?})';\n'
}

emit_assignVector3d () {
	local -r name=$(lvalue ${1:?})
	local -ar value=($(cut ':' $(rvalue ${2:?})))
	local -a Result

	Result[0]=$name'[1]\040=\040'${value[0]}';\n'
	Result[1]=$name'[2]\040=\040'${value[1]}';\n'
	Result[2]=$name'[3]\040=\040'${value[2]}';\n'

	echo ${Result[@]}
}

emit_averageVector3d () {
	local -r name=$(lvalue ${1:?})
	local -r value=$(lvalue ${2:?})

	echo $name'[1]\040/\0402.0\040+\040'$value'[1]\040/\0402.0:'$name'[2]\040/\0402.0\040+\040'$value'[2]\040/\0402.0:'$name'[3]\040/\0402.0\040+\040'$value'[3]\040/\0402.0'
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
		Result[0]='('$(join ',\040' ${Result[@]})')'

		case $name in
			cube)
				Result[1]=$(octal 'addCube')
				;;
			length)
				Result[1]=$(octal 'lengthVector3d')
				;;
			*)
				Result[1]=$(octal $name)
				;;
		esac

		Result[0]=${Result[1]}${Result[0]}
	fi

	if [ ${context:1:1} -eq 1 ]
	then
		echo ${Result[0]}';\n'
	else
		echo ${Result[0]}
	fi
}

emit_ceil () {
	echo 'ceil('$(rvalue ${1:?})')'
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

	local -a Result=('BEGIN\040{\n')
	local -i size=1
	for child in ${children[@]}
	do
		case ${T[$child]:4} in
			count|vertices|elements|grid|xl|yl|zl)
				;;
			min|max|mid)
				Result[$size]='\t'${T[$child]:4}'[1]\040=\0400.0;\n'
				size+=1

				Result[$size]='\t'${T[$child]:4}'[2]\040=\0400.0;\n'
				size+=1

				Result[$size]='\t'${T[$child]:4}'[3]\040=\0400.0;\n'
				size+=1
				;;
			*)
				for built in $(emit $child '0'${context:1})
				do
					Result[$size]='\t'$built
					size+=1
				done
				;;
		esac
	done
	Result[${#Result[@]}]='}\n'
	Result[${#Result[@]}]='\n'
	Result[${#Result[@]}]='function\040ceil(x,\040y)\040{\n'
	Result[${#Result[@]}]='\ty\040=\040x\040\045\0401;\n\n'
	Result[${#Result[@]}]='\tif\040(x\040>\0400)\040{\n'
	Result[${#Result[@]}]='\t\tif\040(y\040>\0400)\040{\n'
	Result[${#Result[@]}]='\t\t\treturn\040x\040-\040y\040+\0401;\n'
	Result[${#Result[@]}]='\t\t}\040else\040{\n'
	Result[${#Result[@]}]='\t\t\treturn\040x;\n'
	Result[${#Result[@]}]='\t\t}\n'
	Result[${#Result[@]}]='\t}\040else\040{\n'
	Result[${#Result[@]}]='\t\treturn\040x\040-\040y;\n'
	Result[${#Result[@]}]='\t}\n'
	Result[${#Result[@]}]='}\n'
	Result[${#Result[@]}]='\n'
	Result[${#Result[@]}]='function\040floor(x,\040y)\040{\n'
	Result[${#Result[@]}]='\ty\040=\040x\040\045\0401;\n\n'
	Result[${#Result[@]}]='\tif\040(x\040<\0400)\040{\n'
	Result[${#Result[@]}]='\t\tif\040(y\040<\0400)\040{\n'
	Result[${#Result[@]}]='\t\t\treturn\040x\040-\040y\040-\0401;\n'
	Result[${#Result[@]}]='\t\t}\040else\040{\n'
	Result[${#Result[@]}]='\t\t\treturn\040x;\n'
	Result[${#Result[@]}]='\t\t}\n'
	Result[${#Result[@]}]='\t}\040else\040{\n'
	Result[${#Result[@]}]='\t\treturn\040x\040-\040y;\n'
	Result[${#Result[@]}]='\t}\n'
	Result[${#Result[@]}]='}\n'
	Result[${#Result[@]}]='\n'
	Result[${#Result[@]}]='function\040fmin(x,\040y)\040{\n'
	Result[${#Result[@]}]='\treturn\040(x\040<\040y)\040?\040x\040:\040y;\n'
	Result[${#Result[@]}]='}\n'

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
		*)
			case $parameter in
				x)
					echo $name'[1]'
					;;
				y)
					echo $name'[2]'
					;;
				z)
					echo $name'[3]'
					;;
			esac
			;;
	esac
}

emit_dotCount () {
	echo 'length(elements)'
}

emit_dotVertex () {
	local -r name=$(rvalue ${1:?})

	case ${T[${2:?}]} in
		x)
			echo 'vertices[3\040*\040'$name'\040+\0401]'
			;;
		y)
			echo 'vertices[3\040*\040'$name'\040+\0402]'
			;;
		z)
			echo 'vertices[3\040*\040'$name'\040+\0403]'
			;;
	esac
}

emit_double () {
	echo ${T[${1:?}]}
}

emit_floor () {
	echo 'floor('$(rvalue ${1:?})')'
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
	local -r context='0'${context:1}

	local -a Result=('function\040')
	case $name in
		cube)
			Result[0]=${Result[0]}$(octal 'addCube')
			;;
		length)
			Result[0]=${Result[0]}$(octal 'lengthVector3d')
			;;
		*)
			Result[0]=${Result[0]}$(octal $name)
			;;
	esac
	Result[0]+=$(rvalue ${3:?})'\040{\n'

	for built in $(emit_glue ${@:4})
	do
		Result[${#Result[@]}]=$built
	done
	Result[${#Result[@]}]='}\n'

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
				if|for|forDouble)
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
	echo ${T[${1:?}]}
}

emit_identifierVector3d () {
	local -r name=${T[${1:?}]}
	echo $name'[1]:'$name'[2]:'$name'[3]'
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
	echo 'fmin('$(rvalue ${1:?})',\040'$(rvalue ${2:?})')'
}

emit_minusAssignVector3d () {
	local -r name=$(lvalue ${1:?})
	local -r value=$(lvalue ${2:?})
	local -a Result

	Result[0]=$name'[1]\040-=\040'$value'[1];\n'
	Result[1]=$name'[2]\040-=\040'$value'[2];\n'
	Result[2]=$name'[3]\040-=\040'$value'[3];\n'

	echo ${Result[@]}
}

emit_minusAssignVertex () {
	local -r name=$(rvalue ${1:?})
	local -r value=$(lvalue ${2:?})
	local -a Result

	Result[0]='vertices[3\040*\040'$name'\040+\0401]\040-=\040'$value'[1];\n'
	Result[1]='vertices[3\040*\040'$name'\040+\0402]\040-=\040'$value'[2];\n'
	Result[2]='vertices[3\040*\040'$name'\040+\0403]\040-=\040'$value'[3];\n'

	echo ${Result[@]}
}

emit_minusDouble () {
	echo $(rvalue ${1:?})'\040-\040'$(rvalue ${2:?})
}

emit_minusVector3d () {
	local -r name=$(lvalue ${1:?})
	local -r value=$(lvalue ${2:?})

	echo $name'[1]\040-\040'$value'[1]:'$name'[2]\040-\040'$value'[2]:'$name'[3]\040-\040'$value'[3]'
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

	Result[0]=$name'[1]\040*=\040'$value';\n'
	Result[1]=$name'[2]\040*=\040'$value';\n'
	Result[2]=$name'[3]\040*=\040'$value';\n'

	echo ${Result[@]}
}

emit_triangle () {
	local -a Result

	Result[0]=$(rvalue ${1:?})
	Result[1]='elements['${Result[0]}'\040+\0402]'
	Result[2]='elements['${Result[0]}'\040+\0403]'
	Result[0]='elements['${Result[0]}'\040+\0401]'

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

	echo $(join '\040' ${Result[@]})
}

emit_var() {
	local -r name=${1:?}
	local -ar parameters=(${@:2})
	local -ir size=${#parameters[@]}

	local attributes=$(rvalue ${parameters[0]})
	local value=
	local -a Result

	case $attributes in
		*Vector3d*)
			if [ $size -gt 1 ]
			then
				Result=($(cut ':' $(rvalue ${parameters[1]})))
			else
				Result=('0.0' '0.0' '0.0')
			fi

			if [ ${context:1:1} -eq 1 ]
			then
				Result[0]=$name'[1]\040=\040'${Result[0]}';\n'
				Result[1]=$name'[2]\040=\040'${Result[1]}';\n'
				Result[2]=$name'[3]\040=\040'${Result[2]}';\n'
			fi
			;;
		*)
			if [ $size -gt 1 ]
			then
				value=$(rvalue ${parameters[1]})
			fi

			if [[ -n $name && -n $value ]]
			then
				Result[0]=$name'\040=\040'$value
			elif [ ${context:0:1} -eq 0 ]
			then
				Result[0]=$name
			fi

			if [ ${context:1:1} -eq 1 ]
			then
				Result[0]=${Result[0]}';\n'
			fi
			;;
	esac

	echo ${Result[@]}
}

emit_vertex () {
	local -ir cut=${1:?}
	local -ir name=${2:?}
	local -a Result

	if [ $cut -eq 1 ]
	then
		Result[0]='vertices['$((3 * $name + 1))']'
		Result[1]='vertices['$((3 * $name + 2))']'
		Result[2]='vertices['$((3 * $name + 3))']'
	else
		Result[0]=$(rvalue $name)
		Result[1]='vertices[3\040\052\040'${Result[0]}'\040+\0402]'
		Result[2]='vertices[3\040\052\040'${Result[0]}'\040+\0403]'
		Result[0]='vertices[3\040\052\040'${Result[0]}'\040+\0401]'
	fi

	echo $(join ':' ${Result[@]})
}

build_files () {
	build_file "${@:1:2}" 'awk'
}

. ./build.sh awk
