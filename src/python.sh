#!/usr/bin/env bash

lvalue () {
	echo $(join '\040' $(emit ${1:?} ${context:0:1}'0'))
}

rvalue () {
	echo $(join '\040' $(emit ${1:?} ${context:0:1}'0'))
}

emit_mesh2cubes () {
	local -a Result
	Result[0]='#!/usr/bin/env\040python3\n\n'
	Result[1]='from\040math\040import\040ceil,\040floor,\040sqrt\n\n'
	Result[2]='class\040mesh2cubes:\n'
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
				Result[$size]='\t'$built
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
	echo $(rvalue ${1:?})'\040and\040'$(rvalue ${2:?})
}

emit_assignDouble () {
	echo $(lvalue ${1:?})'\040=\040'$(rvalue ${2:?})'\n'
}

emit_assignGrid () {
	echo 'self.grid.add(f'\''{'$(rvalue ${1:?})'},{'$(rvalue ${2:?})'},{'$(rvalue ${3:?})'}'\'')\n'
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

	echo '['$name'[0]\040/\0402.0\040+\040'$value'[0]\040/\0402.0,\040'$name'[1]\040/\0402.0\040+\040'$value'[1]\040/\0402.0,\040'$name'[2]\040/\0402.0\040+\040'$value'[2]\040/\0402.0]'
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

		if [ $name != 'sqrt' ]
		then
			Result[0]='self.'${Result[0]}
		fi
	fi

	if [ ${context:1:1} -eq 1 ]
	then
		echo ${Result[0]}'\n'
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

	local -a Result=('def\040__init__(self):\n')
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
			Result[$size]='\tself.'$built
			size+=1
		done
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
					echo 'self.'$name'[0]'
					;;
				y)
					echo 'self.'$name'[1]'
					;;
				z)
					echo 'self.'$name'[2]'
					;;
			esac
			;;
	esac
}

emit_dotCount () {
	echo 'len(self.elements)'
}

emit_dotVertex () {
	local -r name=$(rvalue ${1:?})

	case ${T[${2:?}]} in
		x)
			echo 'self.vertices[3\040*\040'$name']'
			;;
		y)
			echo 'self.vertices[3\040*\040'$name'\040+\0401]'
			;;
		z)
			echo 'self.vertices[3\040*\040'$name'\040+\0402]'
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
	local -a Result
	Result[0]=$(rvalue ${1:?})'\n'
	Result[1]='while\040'$(rvalue ${2:?})':\n'

	for built in $(emit ${4:?} ${context:0:1}'1')
	do
		Result[${#Result[@]}]=$built
	done
	Result[${#Result[@]}]='\t'$(rvalue ${3:?})'\n'

	echo ${Result[@]}
}

emit_forDouble () {
	local -a Result
	Result[0]=$(rvalue ${1:?})'\n'
	Result[1]='while\040'$(rvalue ${2:?})':\n'

	for built in $(emit ${4:?} ${context:0:1}'1')
	do
		Result[${#Result[@]}]=$built
	done
	Result[${#Result[@]}]='\t'$(rvalue ${3:?})'\n'

	echo ${Result[@]}
}

emit_function () {
	local -r name=${1:?}
	local -r parameters=$(rvalue ${3:?})
	local -r context='0'${context:1}

	local -a Result=('def\040'$(octal $name)$parameters'\040->\040'$(rvalue ${2:?})':\n')

	case ${Result[0]} in
		*'\040->\040static\040'*)
			Result[1]=${Result[0]/static\\040/}
			Result[0]='@staticmethod\n'
			;;
		*)
			if [ $parameters = '()' ]
			then
				Result[0]=${Result[0]/\(\)/'(self)'}
			else
				Result[0]=${Result[0]/\(/'(self,\040'}
			fi
			;;
	esac

	for built in $(emit_glue ${@:4})
	do
		Result[${#Result[@]}]=$built
	done

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
	echo 'self.'${T[${1:?}]}
}

emit_identifierVector3d () {
	echo ${T[${1:?}]}'[0:3]'
}

emit_if () {
	local -ar children=(${@:1})
	local -ir size=${#children[@]}
	local -i child=0
	local -a Result

	Result[0]='if\040'$(rvalue ${children[0]:?})':\n'

	for built in $(emit ${children[1]:?} ${context:0:1}'1')
	do
		Result[${#Result[@]}]=$built
	done

	if [ $size -eq 3 ]
	then
		Result[${#Result[@]}]='else:\n'
		for built in $(emit ${children[2]:?} ${context:0:1}'1')
		do
			Result[${#Result[@]}]=$built
		done
	fi

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
	echo 'min('$(rvalue ${1:?})',\040'$(rvalue ${2:?})')'
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

	Result[0]='self.vertices[3\040*\040'$name']\040-=\040'$value'[0]\n'
	Result[1]='self.vertices[3\040*\040'$name'\040+\0401]\040-=\040'$value'[1]\n'
	Result[2]='self.vertices[3\040*\040'$name'\040+\0402]\040-=\040'$value'[2]\n'

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
	echo $(rvalue ${2:?})':\040'$(rvalue ${1:?})
}

emit_parameters () {
	local -ar children=(${@:1})
	local -i child=0
	local -a Result
	for child in ${children[@]}
	do
		Result[${#Result[@]}]=$(rvalue $child)

		case ${Result[-1]} in
			v1:\\040Vector3d)
				Result[-1]=${Result[-1]/Vector3d/list[float]}
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
	Result[1]='self.elements['${Result[0]}'\040+\0401]'
	Result[2]='self.elements['${Result[0]}'\040+\0402]'
	Result[0]='self.elements['${Result[0]}']'

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
						Result[-1]='list[int]'
						;;
					double)
						Result[-1]='list[float]'
						;;
				esac
				;;
			Grid)
				Result[-1]='set[str]'
				;;
			const)
				Result[-1]=
				;;
			double)
				Result[-1]='float'
				;;
			index*|size*)
				Result[-1]='int'
				;;
			void)
				Result[-1]='None'
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
		*list*)
			if [ $size -gt 1 ]
			then
				value=$(rvalue ${parameters[1]})
			else
				value='[]'
			fi
			;;
		*set*)
			if [ $size -gt 1 ]
			then
				value=$(rvalue ${parameters[1]})
			else
				value='set()'
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

			attributes=${attributes[@]/Vector3d/list[float]}
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
		if [ ${#attributes[@]} -gt 0 ]
		then
			Result[0]=$name':\040'$(join '\040' ${attributes[@]})
		else
			Result[0]=$name
		fi

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
	local Result=

	if [ $cut -eq 1 ]
	then
		Result='self.vertices['$((3 * $name))':'$((3 * $name + 3))']'
	else
		Result=$(rvalue $name)
		Result='self.vertices[3\040\052\040'${Result[0]}':3\040\052\040'${Result[0]}'\040+\0403]'
	fi

	echo $Result
}

build_files () {
	build_file "${@:1:2}" 'py'
}

. ./build.sh python
