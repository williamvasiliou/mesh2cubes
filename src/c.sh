#!/usr/bin/env bash

lvalue () {
	echo $(join '\040' $(emit ${1:?} ${context:0:1}'0'))
}

rvalue () {
	echo $(join '\040' $(emit ${1:?} ${context:0:1}'0'))
}

emit_mesh2cubes () {
	local -a Result
	Result[0]='#ifndef\040MESH2CUBES_H\n'
	Result[1]='#include\040<math.h>\n'
	Result[2]='#include\040<stdint.h>\n'
	Result[3]='#include\040<stdlib.h>\n\n'
	local -i size=4

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
	Result[$size]='\n#endif\040//\040MESH2CUBES_H\n'

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
	echo $(rvalue ${1:?})'\040+\040'$(rvalue ${2:?})
}

emit_and () {
	if [ ${T[${1:?}]} = 'compareLow' ]
	then
		echo $(rvalue ${2:?})
	elif [ ${T[${2:?}]} = 'compareLow' ]
	then
		echo $(rvalue ${1:?})
	else
		echo $(rvalue ${1:?})'\040&&\040'$(rvalue ${2:?})
	fi
}

emit_assignDouble () {
	echo $(lvalue ${1:?})'\040=\040'$(rvalue ${2:?})';\n'
}

emit_assignGrid () {
	local -a Result

	Result[0]='const\040size_t\040i\040=\040m2c->yl\040*\040m2c->zl\040*\040'$(rvalue ${1:?})'\040+\040m2c->zl\040*\040'$(rvalue ${2:?})'\040+\040'$(rvalue ${3:?})';\n\n'
	Result[1]='m2c->grid[i\040>>\0403]\040|=\0401\040<<\040(i\040&\0407);\n'

	echo ${Result[@]}
}

emit_assignInt () {
	echo $(lvalue ${1:?})'\040=\040'$(rvalue ${2:?})';\n'
}

emit_assignVector3d () {
	local -r name=$(lvalue ${1:?})
	local -ar value=($(cut ':' $(rvalue ${2:?})))
	local -a Result

	Result[0]=$name'[0]\040=\040'${value[0]}';\n'
	Result[1]=$name'[1]\040=\040'${value[1]}';\n'
	Result[2]=$name'[2]\040=\040'${value[2]}';\n'

	echo ${Result[@]}
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

		Result[1]=$(join ',\040' ${Result[@]})')'

		case $name in
			length)
				Result[1]='('${Result[1]}
				Result[2]='m2c_'$(octal $name)
				;;
			sqrt)
				Result[1]='('${Result[1]}
				Result[2]=$(octal $name)
				;;
			*)
				Result[1]='(m2c,\040'${Result[1]}
				Result[2]='m2c_'$(octal $name)
				;;
		esac

		Result[0]=${Result[2]}${Result[1]}
	fi

	if [ ${context:1:1} -eq 1 ]
	then
		echo ${Result[0]}';\n'
	else
		echo ${Result[0]}
	fi
}

emit_ceil () {
	echo '(size_t)\040ceil('$(rvalue ${1:?})')'
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
	local -ar children=${@:1}
	local -i child=0

	local -a Result=('typedef\040struct\040{\n')
	local -i size=1
	for child in ${children[@]}
	do
		for built in $(emit $child '1'${context:1})
		do
			Result[$size]='\t'$built
			size+=1
		done
	done
	Result[${#Result[@]}]='}\040m2c_t;\n'
	size+=1

	if [ $size -gt 2 ]
	then
		Result[$(($size - 1))]+='\n'

		Result[$size]='m2c_t\040*m2c_mesh2cubes()\040{\n'
		size+=1

		Result[$size]='\tm2c_t\040*m2c\040=\040(m2c_t\040*)\040calloc((size_t)\0401,\040sizeof(m2c_t));\n\n'
		size+=1

		for child in ${children[@]}
		do
			parameters=($(cut ':' ${T[$child]}))
			parameters=($(cut ',' ${parameters[1]}))

			if [ ${#parameters[@]} -gt 2 ]
			then
				case ${parameters[0]} in
					index*|size*)
						parameters[0]='size_t'
						;;
				esac

				for built in $(emit $child '0'${context:1})
				do
					Result[$size]='\tm2c->'${built:${#parameters[0]}+4}
					size+=1
				done
			else
				case ${parameters[1]} in
					vertices)
						Result[$size]='\tm2c->vertices\040=\040(double\040*)\040NULL;\n'

						size+=1
						;;
					elements)
						Result[$size]='\tm2c->elements\040=\040(size_t\040*)\040NULL;\n'

						size+=1
						;;
					grid)
						Result[$size]='\tm2c->grid\040=\040(uint8_t\040*)\040NULL;\n'

						size+=1
						;;
					*)
						Result[$size]='\tm2c->'${parameters[1]}'[0]\040=\0400.0;\n'
						size+=1

						Result[$size]='\tm2c->'${parameters[1]}'[1]\040=\0400.0;\n'
						size+=1

						Result[$size]='\tm2c->'${parameters[1]}'[2]\040=\0400.0;\n'
						size+=1
						;;
				esac
			fi
		done

		Result[$size]='\n\treturn\040m2c;\n'
		size+=1

		Result[$size]='}\n'
		size+=1
	fi

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
					echo 'm2c->count'
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
					echo 'm2c->'$name'[0]'
					;;
				y)
					echo 'm2c->'$name'[1]'
					;;
				z)
					echo 'm2c->'$name'[2]'
					;;
			esac
			;;
	esac
}

emit_dotVertex () {
	local -r name=$(rvalue ${1:?})

	case ${T[${2:?}]} in
		x)
			echo 'm2c->vertices[3\040*\040'$name']'
			;;
		y)
			echo 'm2c->vertices[3\040*\040'$name'\040+\0401]'
			;;
		z)
			echo 'm2c->vertices[3\040*\040'$name'\040+\0402]'
			;;
	esac
}

emit_double () {
	echo ${T[${1:?}]}
}

emit_floor () {
	echo '(size_t)\040floor('$(rvalue ${1:?})')'
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
	local -ar parameters=(${@:2})
	local -i size=${#parameters[@]}
	local -r context='0'${context:1}

	local -a Result=('static\040')
	case $name in
		length)
			Result[0]=${Result[0]}'inline\040double'
			;;
		*)
			Result[0]=${Result[0]}'void'
			;;
	esac

	Result[0]=${Result[0]}'\040m2c_'$(octal $name)'('
	if [ $name != 'length' ]
	then
		Result[0]=${Result[0]}'m2c_t\040*m2c'
	fi

	if [ $size -gt 0 ]
	then
		if [ $name = 'length' ]
		then
			size=0
		else
			size=2
		fi

		for parameter in ${parameters[@]}
		do
			if [ $size -gt 0 ]
			then
				if [ $(($size % 2)) -eq 0 ]
				then
					Result[0]=${Result[0]}','
				fi

				Result[0]=${Result[0]}'\040'
			fi

			if [ $(($size % 2)) -eq 0 ]
			then
				parameter=${parameter/Vector3d/double}
				parameter=${parameter/index/size_t}
			fi

			Result[0]=${Result[0]}$parameter
			size+=1

			if [ $(($size % 2)) -eq 0 ]
			then
				case $name in
					length)
						if [ ${parameters[$(($size - 2))]} = 'Vector3d' ]
						then
							Result[0]=${Result[0]}'[]'
						fi
						;;
					*)
						if [ ${parameters[$(($size - 4))]} = 'Vector3d' ]
						then
							Result[0]=${Result[0]}'[]'
						fi
						;;
				esac
			fi
		done
	fi
	Result[0]=${Result[0]}')\040{\n'

	for built in $(emit_glue ${children[@]})
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
	echo 'm2c->'${T[${1:?}]}
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

	for child in ${children[1]:?}
	do
		for built in $(emit $child ${context:0:1}'1')
		do
			Result[${#Result[@]}]=$built
		done
	done

	if [ $size -eq 3 ]
	then
		Result[${#Result[@]}]='}\040else\040{\n'
		for child in ${children[2]}
		do
			for built in $(emit $child ${context:0:1}'1')
			do
				Result[${#Result[@]}]=$built
			done
		done
	fi

	Result[${#Result[@]}]='}\n'

	echo ${Result[@]}
}

emit_ifAssignGrid () {
	echo $(emit_if ${@:1})
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

	Result[0]=$name'[0]\040-=\040'$value'[0];\n'
	Result[1]=$name'[1]\040-=\040'$value'[1];\n'
	Result[2]=$name'[2]\040-=\040'$value'[2];\n'

	echo ${Result[@]}
}

emit_minusAssignVertex () {
	local -r name=$(rvalue ${1:?})
	local -r value=$(lvalue ${2:?})
	local -a Result

	Result[0]='m2c->vertices[3\040*\040'$name']\040-=\040'$value'[0];\n'
	Result[1]='m2c->vertices[3\040*\040'$name'\040+\0401]\040-=\040'$value'[1];\n'
	Result[2]='m2c->vertices[3\040*\040'$name'\040+\0402]\040-=\040'$value'[2];\n'

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
	local -a Result=($(rvalue ${1:?}) $(rvalue ${2:?}) $(rvalue ${3:?}))
	Result[3]='m2c->grid\040=\040(uint8_t\040*)\040calloc(('$(rvalue ${4:?})'\040*\040'$(rvalue ${5:?})'\040*\040'$(rvalue ${6:?})'\040+\0408)\040>>\0403,\040sizeof(uint8_t));\n'

	echo ${Result[@]}
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
	Result[1]='m2c->elements['${Result[0]}'\040+\0401]'
	Result[2]='m2c->elements['${Result[0]}'\040+\0402]'
	Result[0]='m2c->elements['${Result[0]}']'

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
	local -a Result

	if [ $cut -eq 1 ]
	then
		name=$(octal ${parameters[1]})

		case ${parameters[0]} in
			*'[]')
				attributes[0]=${parameters[0]%'[]'}

				case ${attributes[0]} in
					index)
						attributes[0]='size_t'
						name='*'$name
						;;
					*)
						name='*'$name
						;;
				esac
				;;
			Vector3d)
				attributes[0]='double'
				name+='[3]'
				;;
			Grid)
				attributes[0]='uint8_t'
				name='*'$name
				;;
			index|size*)
				attributes[0]='size_t'
				;;
			*)
				attributes[0]=${parameters[0]}
				;;
		esac

		if [ $size -gt 2 ]
		then
			value=$(octal ${parameters[2]})
		fi

		if [[ -n $name && -n $value ]]
		then
			if [ ${context:0:1} -eq 0 ]
			then
				Result=$name'\040=\040'$value
			else
				Result=$name
			fi
		else
			Result[0]=$name
		fi

		if [ ${#attributes[@]} -gt 0 ]
		then
			Result[0]=$(join '\040' ${attributes[@]})'\040'${Result[0]}
		fi

		if [ ${context:1:1} -eq 1 ]
		then
			Result[0]=${Result[0]}';\n'
		fi
	else
		name=$(rvalue ${parameters[0]})

		case $name in
			*Vector3d*)
				if [ $size -gt 2 ]
				then
					attributes=($(cut ':' $(rvalue ${parameters[2]})))
				else
					attributes=('0.0' '0.0' '0.0')
				fi

				if [ ${context:1:1} -eq 1 ]
				then
					Result[0]='double\040'$(lvalue ${parameters[1]})'[3]\040=\040{'${attributes[0]}',\040'${attributes[1]}',\040'${attributes[2]}'};\n'

					case $name in
						*const*)
							Result[0]='const\040'${Result[0]}
							;;
					esac
				fi
				;;
			*)
				case $name in
					*const*)
						attributes[${#attributes[@]}]='const'
						name=${name/'const\040'/}
						;;
				esac

				case $name in
					*index*|*size*)
						attributes[${#attributes[@]}]='size_t'
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

				if [[ -n $name && -n $value ]]
				then
					Result[0]=$name'\040=\040'$value
				elif [ ${context:0:1} -eq 0 ]
				then
					Result[0]=$name
				fi

				if [ ${#attributes[@]} -gt 0 ]
				then
					Result[0]=$(join '\040' ${attributes[@]})'\040'${Result[0]}
				fi

				if [ ${context:1:1} -eq 1 ]
				then
					Result[0]=${Result[0]}';\n'
				fi
				;;
		esac
	fi

	echo ${Result[@]}
}

emit_vertex () {
	local -ir cut=${1:?}
	local -ir name=${2:?}
	local -a Result

	if [ $cut -eq 1 ]
	then
		Result[0]='m2c->vertices['$((3 * $name))']'
		Result[1]='m2c->vertices['$((3 * $name + 1))']'
		Result[2]='m2c->vertices['$((3 * $name + 2))']'
	else
		Result[0]=$(rvalue $name)
		Result[1]='m2c->vertices[3\040\052\040'${Result[0]}'\040+\0401]'
		Result[2]='m2c->vertices[3\040\052\040'${Result[0]}'\040+\0402]'
		Result[0]='m2c->vertices[3\040\052\040'${Result[0]}']'
	fi

	echo $(join ':' ${Result[@]})
}

. ./build.sh c
