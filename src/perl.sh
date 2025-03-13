#!/usr/bin/env bash

lvalue () {
	local -r name=$(join '\040' $(emit ${1:?} ${context:0:1}'0'))

	case ${name:0:1} in
		@|$)
			echo ${name:1}
			;;
		*)
			echo $name
			;;
	esac
}

rvalue () {
	echo $(join '\040' $(emit ${1:?} ${context:0:1}'0'))
}

emit_mesh2cubes () {
	local -a Result
	Result[0]='package\040mesh2cubes;\n\n'
	Result[1]='use\040strict;\n'
	Result[2]='use\040warnings;\n\n'
	Result[3]='use\040POSIX\040qw(ceil\040floor\040fmin);\n\n'
	Result[4]='use\040Exporter\0405.57\040'\''import'\'';\n'
	Result[5]='our\040@EXPORT\040=\040qw(@elements\040\045grid\040translate\040triangles\040@vertices);\n\n'
	local -i size=6

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
	Result[$size]='\n1;\n'

	echo ${Result[@]}
}

emit_addAssignDouble () {
	local -r Result='$'$(lvalue ${1:?})'\040+=\040'$(rvalue ${2:?})

	if [ ${context:1:1} -eq 1 ]
	then
		echo $Result';\n'
	else
		echo $Result
	fi
}

emit_addAssignInt () {
	local -r Result='$'$(lvalue ${1:?})'\040+=\040'$(rvalue ${2:?})

	if [ ${context:1:1} -eq 1 ]
	then
		echo $Result';\n'
	else
		echo $Result
	fi
}

emit_addAssignVector3d () {
	local -r name='$'$(lvalue ${1:?})
	local -r value=$(rvalue ${2:?})
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
	echo '$'$(lvalue ${1:?})'\040=\040'$(rvalue ${2:?})';\n'
}

emit_assignGrid () {
	echo '$grid{"'$(rvalue ${1:?})','$(rvalue ${2:?})','$(rvalue ${3:?})'"}\040=\0401;\n'
}

emit_assignInt () {
	echo '$'$(lvalue ${1:?})'\040=\040'$(rvalue ${2:?})';\n'
}

emit_assignVector3d () {
	echo '@'$(lvalue ${1:?})'\040=\040'$(rvalue ${2:?})';\n'
}

emit_averageVector3d () {
	local -r name=$(rvalue ${1:?})
	local -r value=$(rvalue ${2:?})

	echo '('$name'[0]\040/\0402\040+\040'$value'[0]\040/\0402,\040'$name'[1]\040/\0402\040+\040'$value'[1]\040/\0402,\040'$name'[2]\040/\0402\040+\040'$value'[2]\040/\0402)'
}

emit_call () {
	local -r name=${1:?}
	local -ar children=(${@:2})
	local -ir size=${#children[@]}

	local -i child=0
	local -a Result

	case $name in
		cube|length)
			Result[0]=$(octal $name)'(@'$(lvalue ${2:?})')'

			;;
		*)
			if [ $size -eq 0 ]
			then
				Result[0]=$(octal $name)
			else
				for child in ${children[@]}
				do
					Result[${#Result[@]}]=$(rvalue $child)
				done

				Result[0]=$(octal $name)'('$(join '\040' ${Result[@]})')'
			fi

			;;
	esac

	if [ $name = 'length' ]
	then
		Result[0]='&'${Result[0]}
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
	local -a Result
	for child in ${children[@]}
	do
		case ${T[$child]:4} in
			count|xl|yl|zl)
				;;
			*)
				for built in $(emit $child '1'${context:1})
				do
					Result[${#Result[@]}]=$built
				done
				;;
		esac
	done

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
					echo '$_[0]'
					;;
				y)
					echo '$_[1]'
					;;
				z)
					echo '$_[2]'
					;;
			esac
			;;
		*)
			case $parameter in
				x)
					echo '$'$name'[0]'
					;;
				y)
					echo '$'$name'[1]'
					;;
				z)
					echo '$'$name'[2]'
					;;
			esac
			;;
	esac
}

emit_dotCount () {
	echo '@elements'
}

emit_dotVertex () {
	local -r name=$(rvalue ${1:?})

	case ${T[${2:?}]} in
		x)
			echo '$vertices[3\040*\040'$name']'
			;;
		y)
			echo '$vertices[3\040*\040'$name'\040+\0401]'
			;;
		z)
			echo '$vertices[3\040*\040'$name'\040+\0402]'
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

	local -a Result=('sub\040'$(octal ${1:?})'\040{\n')
	if [ $name = 'triangle' ]
	then
		Result[1]='\tmy\040($a,\040$b,\040$c)\040=\040@_;\n'
		Result[2]='\t$a\040*=\0403;\n'
		Result[3]='\t$b\040*=\0403;\n'
		Result[4]='\t$c\040*=\0403;\n\n'
	fi

	for built in $(emit_glue ${@:4})
	do
		Result[${#Result[@]}]=$built
	done

	echo ${Result[@]}'}\n'
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
	echo '$'${T[${1:?}]}
}

emit_identifierThis () {
	echo '$'${T[${1:?}]}
}

emit_identifierVector3d () {
	echo '@'${T[${1:?}]}'[0..2]'
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
	echo '++$'$(lvalue ${1:?})
}

emit_int () {
	echo ${T[${1:?}]}
}

emit_min () {
	echo 'fmin('$(rvalue ${1:?})',\040'$(rvalue ${2:?})')'
}

emit_minusAssignVector3d () {
	local -r name='$'$(lvalue ${1:?})
	local -r value=$(rvalue ${2:?})
	local -a Result

	Result[0]=$name'[0]\040-=\040'$value'[0];\n'
	Result[1]=$name'[1]\040-=\040'$value'[1];\n'
	Result[2]=$name'[2]\040-=\040'$value'[2];\n'

	echo ${Result[@]}
}

emit_minusAssignVertex () {
	local -r name=$(rvalue ${1:?})
	local -r value=$(rvalue ${2:?})
	local -a Result

	Result[0]='$vertices[3\040*\040'$name']\040-=\040'$value'[0];\n'
	Result[1]='$vertices[3\040*\040'$name'\040+\0401]\040-=\040'$value'[1];\n'
	Result[2]='$vertices[3\040*\040'$name'\040+\0402]\040-=\040'$value'[2];\n'

	echo ${Result[@]}
}

emit_minusDouble () {
	echo $(rvalue ${1:?})'\040-\040'$(rvalue ${2:?})
}

emit_minusVector3d () {
	local -r name=$(rvalue ${1:?})
	local -r value=$(rvalue ${2:?})

	echo '('$name'[0]\040-\040'$value'[0],\040'$name'[1]\040-\040'$value'[1],\040'$name'[2]\040-\040'$value'[2])'
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
	echo
}

emit_parameters () {
	echo
}

emit_positional () {
	echo $(rvalue ${2:?})
}

emit_return () {
	echo 'return\040'$(rvalue ${1:?})';\n'
}

emit_scaleVector3d () {
	local -r name='$'$(lvalue ${1:?})
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
	Result[1]='$elements['${Result[0]}'\040+\0401]'
	Result[2]='$elements['${Result[0]}'\040+\0402]'
	Result[0]='$elements['${Result[0]}']'

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

	local -a attributes
	local value=$(rvalue ${2:?})
	local Result=

	if [ ${context:0:1} -eq 1 ]
	then
		attributes[0]='our'
	else
		attributes[0]='my'
	fi

	case $value in
		*'[]')
			attributes[1]='@'

			if [ $size -lt 2 ]
			then
				value='()'
			fi
			;;
		*Vector3d*)
			attributes[1]='@'

			if [ $size -lt 2 ]
			then
				value='(0.0,\0400.0,\0400.0)'
			fi
			;;
		Grid)
			attributes[1]='\045'

			if [ $size -lt 2 ]
			then
				value='()'
			fi
			;;
		*)
			attributes[1]='$'
			;;
	esac

	if [ $size -gt 1 ]
	then
		value=$(rvalue ${parameters[1]})
	fi

	if [[ -n $name && -n $value ]]
	then
		Result=$name'\040=\040'$value
	else
		Result=$name
	fi

	Result=${attributes[0]}'\040'$(join '\040' ${attributes[@]:1})$Result

	if [ ${context:1:1} -eq 1 ]
	then
		Result+=';\n'
	fi

	echo $Result
}

emit_vertex () {
	local -ir cut=${1:?}
	local -ir name=${2:?}
	local Result=

	if [ $cut -eq 1 ]
	then
		Result='@vertices['$((3 * $name))'..'$((3 * $name + 2))']'
	else
		Result=$(rvalue $name)
		Result='@vertices['$Result'..'$Result'\040+\0402]'
	fi

	echo $Result
}

build_files () {
	build_file "${@:1:2}" 'pm'
}

. ./build.sh perl
