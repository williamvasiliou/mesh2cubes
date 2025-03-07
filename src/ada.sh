#!/usr/bin/env bash

lvalue () {
	echo $(join '\040' $(emit ${1:?} ${context:0:1}'0'))
}

rvalue () {
	echo $(join '\040' $(emit ${1:?} ${context:0:1}'0'))
}

emit_mesh2cubes () {
	local -ir constructor=${children[1]:?}

	local -a Result
	Result[0]='package\040body\040mesh2cubes\040is\n'
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

	if [ $constructor -gt 0 ]
	then
		Result[$size]='begin\n'
		size+=1

		for built in $(emit $constructor '0'${context:1})
		do
			Result[$size]='\t'$built
			size+=1
		done
	fi
	Result[$size]='end\040mesh2cubes;\n'

	echo ${Result[@]}
}

emit_addAssignDouble () {
	local -r name=$(lvalue ${1:?})
	local -r Result=$name'\040:=\040'$name'\040+\040'$(rvalue ${2:?})

	if [ ${context:1:1} -eq 1 ]
	then
		echo $Result';\n'
	else
		echo $Result
	fi
}

emit_addAssignInt () {
	local -r name=$(lvalue ${1:?})
	local -r Result=$name'\040:=\040'$name'\040+\040'$(rvalue ${2:?})

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

	Result[0]=$name'\040(1)\040:=\040'$name'\040(1)\040+\040'$value'\040(1);\n'
	Result[1]=$name'\040(2)\040:=\040'$name'\040(2)\040+\040'$value'\040(2);\n'
	Result[2]=$name'\040(3)\040:=\040'$name'\040(3)\040+\040'$value'\040(3);\n'

	echo ${Result[@]}
}

emit_addDouble () {
	echo $(rvalue ${1:?})'\040+\040'$(rvalue ${2:?})
}

emit_addInt () {
	echo $(rvalue ${1:?})'\040+\040'$(rvalue ${2:?})
}

emit_addLow () {
	echo $(rvalue ${1:?})'\040+\040'$(rvalue ${2:?})
}

emit_and () {
	echo $(rvalue ${1:?})'\040and\040then\040'$(rvalue ${2:?})
}

emit_assignDouble () {
	echo $(lvalue ${1:?})'\040:=\040'$(rvalue ${2:?})';\n'
}

emit_assignGrid () {
	echo 'grid\040('$(rvalue ${1:?})',\040'$(rvalue ${2:?})',\040'$(rvalue ${3:?})')\040:=\040True;\n'
}

emit_assignInt () {
	echo $(lvalue ${1:?})'\040:=\040'$(rvalue ${2:?})';\n'
}

emit_assignVector3d () {
	echo $(lvalue ${1:?})'\040:=\040'$(rvalue ${2:?})';\n'
}

emit_averageVector3d () {
	local -r name=$(lvalue ${1:?})
	local -r value=$(lvalue ${2:?})

	echo '('$name'\040(1)\040/\0402.0\040+\040'$value'\040(1)\040/\0402.0,\040'$name'\040(2)\040/\0402.0\040+\040'$value'\040(2)\040/\0402.0,\040'$name'\040(3)\040/\0402.0\040+\040'$value'\040(3)\040/\0402.0)'
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

		Result[0]=$(octal $name)'\040('$(join ',\040' ${Result[@]})')'
	fi

	if [ ${context:1:1} -eq 1 ]
	then
		echo ${Result[0]}';\n'
	else
		echo ${Result[0]}
	fi
}

emit_ceil () {
	echo 'Ceil('$(rvalue ${1:?})')'
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
	local -a Result
	Result[0]=$(rvalue ${1:?})
	Result[1]=$(rvalue ${2:?})
	Result[2]=$(rvalue ${3:?})

	echo $(join '\040' ${Result[@]})
}

emit_constructor () {
	local -ar children=${@:1}
	local -i child=0
	local -i size=0
	local -a Result
	local -a parameters
	for child in ${children[@]}
	do
		parameters=($(cut ':' ${T[$child]}))
		parameters=($(cut ',' ${parameters[1]}))

		case ${parameters[1]} in
			vertices|elements|grid)
				if [ ${context:0:1} -eq 0 ]
				then
					continue
				fi
				;;
		esac

		case ${T[$child]} in
			var:size.elements*)
				;;
			*)
				for built in $(emit $child $context)
				do
					Result[$size]=$built
					size+=1
				done
				;;
		esac
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
					echo 'elements'\''Range'\''Last'
					;;
			esac
			;;
		*)
			case $parameter in
				x)
					echo $name'\040(1)'
					;;
				y)
					echo $name'\040(2)'
					;;
				z)
					echo $name'\040(3)'
					;;
			esac
			;;
	esac
}

emit_dotVertex () {
	local -r name=$(rvalue ${1:?})

	case ${T[${2:?}]} in
		x)
			echo 'vertices\040(3\040*\040'$name'\040+\0401)'
			;;
		y)
			echo 'vertices\040(3\040*\040'$name'\040+\0402)'
			;;
		z)
			echo 'vertices\040(3\040*\040'$name'\040+\0403)'
			;;
	esac
}

emit_double () {
	echo ${T[${1:?}]}
}

emit_floor () {
	echo 'Floor('$(rvalue ${1:?})')'
}

emit_for () {
	local -a Result
	Result[0]=$(rvalue ${1:?})';\n'
	Result[1]='while\040'$(rvalue ${2:?})'\040loop\n'

	for built in $(emit ${4:?} ${context:0:1}'1')
	do
		Result[${#Result[@]}]=$built
	done
	Result[${#Result[@]}]='\t'$(rvalue ${3:?})';\n'
	Result[${#Result[@]}]='end\040loop;\n'

	echo ${Result[@]}
}

emit_forDouble () {
	local -a Result
	Result[0]=$(rvalue ${1:?})';\n'
	Result[1]='while\040'$(rvalue ${2:?})'\040loop\n'

	for built in $(emit ${4:?} ${context:0:1}'1')
	do
		Result[${#Result[@]}]=$built
	done
	Result[${#Result[@]}]='\t'$(rvalue ${3:?})';\n'
	Result[${#Result[@]}]='end\040loop;\n'

	echo ${Result[@]}
}

emit_function () {
	local -r name=${1:?}
	local -ar parameters=(${@:2})
	local -i size=${#parameters[@]}
	local -r context='0'${context:1}

	local -a Result
	case $name in
		length)
			Result[0]='function'
			;;
		*)
			Result[0]='procedure'
			;;
	esac

	Result[0]=${Result[0]}'\040'$(octal $name)
	if [ $size -gt 0 ]
	then
		Result[0]=${Result[0]}'\040('

		size=0
		for parameter in ${parameters[@]}
		do
			if [ $(($size % 2)) -eq 0 ]
			then
				if [ $size -gt 1 ]
				then
					Result[0]=${Result[0]}',\040'
				fi

				Result[1]=${parameter/index/Index}
			else
				Result[0]=${Result[0]}$parameter':\040in\040'${Result[1]}
			fi

			size+=1
		done

		Result[0]=${Result[0]}')'
	fi

	case $name in
		length)
			Result[0]=${Result[0]}'\040return\040double\040is\n'
			;;
		*)
			Result[0]=${Result[0]}'\040is\n'
			;;
	esac

	Result[1]='begin\n'
	for built in $(emit_glue ${children[@]})
	do
		Result[${#Result[@]}]=$built
	done
	Result[${#Result[@]}]='end\040'$(octal $name)';\n'

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
	echo ${T[${1:?}]}
}

emit_identifierVector3d () {
	echo ${T[${1:?}]}'\040(1\040..\0403)'
}

emit_if () {
	local -ar children=(${@:1})
	local -ir size=${#children[@]}
	local -i child=0
	local -a Result

	Result[0]='if\040'$(rvalue ${children[0]:?})'\040then\n'

	for built in $(emit ${children[1]:?} ${context:0:1}'1')
	do
		Result[${#Result[@]}]=$built
	done

	if [ $size -eq 3 ]
	then
		Result[${#Result[@]}]='else\n'
		for built in $(emit ${children[2]:?} ${context:0:1}'1')
		do
			Result[${#Result[@]}]=$built
		done
	fi

	Result[${#Result[@]}]='end\040if;\n'

	echo ${Result[@]}
}

emit_ifAssignGrid () {
	local -r Result=$(rvalue ${2:?})

	echo ${Result:2}
}

emit_increment () {
	local -r name=$(lvalue ${1:?})
	echo $name'\040:=\040'$name'\040+\0401'
}

emit_int () {
	echo ${T[${1:?}]}
}

emit_min () {
	echo 'Min('$(rvalue ${1:?})',\040'$(rvalue ${2:?})')'
}

emit_minusAssignVector3d () {
	local -r name=$(lvalue ${1:?})
	local -r value=$(lvalue ${2:?})
	local -a Result

	Result[0]=$name'\040(1)\040:=\040'$name'\040(1)\040-\040'$value'\040(1);\n'
	Result[1]=$name'\040(2)\040:=\040'$name'\040(2)\040-\040'$value'\040(2);\n'
	Result[2]=$name'\040(3)\040:=\040'$name'\040(3)\040-\040'$value'\040(3);\n'

	echo ${Result[@]}
}

emit_minusAssignVertex () {
	local -r name=$(rvalue ${1:?})
	local -r value=$(lvalue ${2:?})
	local -a Result

	Result[0]='vertices\040(3\040*\040'$name'\040+\0401)\040:=\040vertices\040(3\040*\040'$name'\040+\0401)\040-\040'$value'\040(1);\n'
	Result[1]='vertices\040(3\040*\040'$name'\040+\0402)\040:=\040vertices\040(3\040*\040'$name'\040+\0402)\040-\040'$value'\040(2);\n'
	Result[2]='vertices\040(3\040*\040'$name'\040+\0403)\040:=\040vertices\040(3\040*\040'$name'\040+\0403)\040-\040'$value'\040(3);\n'

	echo ${Result[@]}
}

emit_minusDouble () {
	echo $(rvalue ${1:?})'\040-\040'$(rvalue ${2:?})
}

emit_minusVector3d () {
	local -r name=$(lvalue ${1:?})
	local -r value=$(lvalue ${2:?})

	echo '('$name'\040(1)\040-\040'$value'\040(1),\040'$name'\040(2)\040-\040'$value'\040(2),\040'$name'\040(3)\040-\040'$value'\040(3))'
}

emit_multiplyDouble () {
	echo $(rvalue ${1:?})'\040*\040'$(rvalue ${2:?})
}

emit_multiplyInt () {
	echo $(rvalue ${1:?})'\040*\040'$(rvalue ${2:?})
}

emit_newGrid () {
	local -a Result=($(rvalue ${1:?}) $(rvalue ${2:?}) $(rvalue ${3:?}))
	Result[3]='grid:\040Grid(1\040..\040'$(rvalue ${4:?})',\0401\040..\040'$(rvalue ${5:?})',\0401\040..\040'$(rvalue ${6:?})')\040:=\040(others\040=>\040False);\n'

	echo ${Result[@]}
}

emit_operator () {
	case ${T[${1:?}]} in
		eq)
			echo '='
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
			echo '/='
			;;
	esac
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

	Result[0]=$name'\040(1)\040:=\040'$name'\040(1)\040*\040'$value';\n'
	Result[1]=$name'\040(2)\040:=\040'$name'\040(2)\040*\040'$value';\n'
	Result[2]=$name'\040(3)\040:=\040'$name'\040(3)\040*\040'$value';\n'

	echo ${Result[@]}
}

emit_triangle () {
	local -a Result

	Result[0]=$(rvalue ${1:?})
	Result[1]='elements\040('${Result[0]}'\040+\0402)'
	Result[2]='elements\040('${Result[0]}'\040+\0403)'
	Result[0]='elements\040('${Result[0]}'\040+\0401)'

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
	local -ir cut=${1:?}
	local -ar parameters=(${@:2})
	local -ir size=${#parameters[@]}

	local -a attributes
	local name=
	local value=
	local Result=

	if [ $cut -eq 1 ]
	then
		case ${parameters[0]} in
			*'[]')
				attributes[${#attributes[@]}]=${parameters[0]%'[]'}

				case ${attributes[-1]} in
					*)
						attributes[${#attributes[@]}]='array\040(Positive\040range\040<>)\040of\040'${attributes[-1]@u}
						;;
				esac
				;;
			Vector3d)
				attributes[${#attributes[@]}]=${parameters[0]}

				if [ $size -lt 3 ]
				then
					value='(0.0,\0400.0,\0400.0)'
				fi
				;;
			Grid)
				attributes[${#attributes[@]}]='Grid'
				;;
			double)
				attributes[${#attributes[@]}]='Double'
				;;
			index|size*)
				attributes[${#attributes[@]}]='Index'
				;;
			*)
				attributes[${#attributes[@]}]=${parameters[0]}
				;;
		esac

		name=$(octal ${parameters[1]})

		if [ $size -gt 2 ]
		then
			value=$(octal ${parameters[2]})
		fi
	else
		name=$(rvalue ${parameters[0]})

		case $name in
			*const*)
				attributes[${#attributes[@]}]='constant'
				name=${name/'const\040'/}
				;;
		esac

		case $name in
			*double*)
				attributes[${#attributes[@]}]='Double'
				;;
			*index*|*size*)
				attributes[${#attributes[@]}]='Index'
				;;
			*)
				attributes[${#attributes[@]}]=$name
				;;
		esac

		name=$(lvalue ${parameters[1]})

		if [ $size -gt 2 ]
		then
			value=$(rvalue ${parameters[2]})
		fi
	fi

	if [ ${#attributes[@]} -gt 0 ]
	then
		name+=':\040'$(join '\040' ${attributes[@]})
	fi

	if [[ -n $name && -n $value ]]
	then
		if [ ${context:0:1} -eq 0 ]
		then
			Result=$name'\040:=\040'$value
		else
			Result=$name
		fi
	else
		Result=$name
	fi

	if [ ${context:1:1} -eq 1 ]
	then
		Result=$Result';\n'
	fi

	echo $Result
}

emit_vertex () {
	local -ir cut=${1:?}
	local -ir name=${2:?}
	local Result=

	if [ $cut -eq 1 ]
	then
		Result='vertices\040('$((3 * $name + 1))'\040..\040'$((3 * $name + 3))')'
	else
		Result=$(rvalue $name)
		Result='vertices\040(3\040*\040'${Result[0]}'\040+\0401\040..\0403\040*\040'${Result[0]}'\040+\0403)'
	fi

	echo $Result
}

. ./build.sh ada
