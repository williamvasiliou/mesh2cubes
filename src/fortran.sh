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
	Result[0]='MODULE\040mesh2cubes\n'
	Result[1]='\040\040\040\040\040\040\040\040IMPLICIT\040NONE\n'

	local -i size=2

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
				Result[$size]='\040\040\040\040\040\040\040\040'$built
				size+=1
			done

			case ${T[$child]} in
				constructor)
					Result[$(($size - 1))]+='CONTAINS'
					;;
			esac
		fi
	done
	Result[$size]='END\040MODULE\040mesh2cubes\n'

	echo ${Result[@]}
}

emit_addAssignDouble () {
	local -r name=$(lvalue ${1:?})
	local -r Result=$name'\040=\040'$name'\040+\040'$(rvalue ${2:?})

	if [ ${context:1:1} -eq 1 ]
	then
		echo $Result'\n'
	else
		echo $Result
	fi
}

emit_addAssignInt () {
	local -r name=$(lvalue ${1:?})
	local -r Result=$name'\040=\040'$name'\040+\040'$(rvalue ${2:?})

	if [ ${context:1:1} -eq 1 ]
	then
		echo $Result'\n'
	else
		echo $Result
	fi
}

emit_addAssignVector3d () {
	local -r name=$(lvalue ${1:?})

	echo $name'\040=\040'$name'\040+\040'$(lvalue ${2:?})'\n'
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
	echo $(rvalue ${1:?})'\040.AND.\040'$(rvalue ${2:?})
}

emit_assignDouble () {
	echo $(lvalue ${1:?})'\040=\040'$(rvalue ${2:?})'\n'
}

emit_assignGrid () {
	echo 'grid('$(rvalue ${1:?})'\040+\0401,\040'$(rvalue ${2:?})'\040+\0401,\040'$(rvalue ${3:?})'\040+\0401)\040=\040.TRUE.\n'
}

emit_assignInt () {
	echo $(lvalue ${1:?})'\040=\040'$(rvalue ${2:?})'\n'
}

emit_assignVector3d () {
	echo $(lvalue ${1:?})'\040=\040'$(rvalue ${2:?})'\n'
}

emit_averageVector3d () {
	echo $(lvalue ${1:?})'\040/\0402.0\040+\040'$(lvalue ${2:?})'\040/\0402.0'
}

emit_call () {
	local -r name=${1:?}
	local -ar children=(${@:2})
	local -ir size=${#children[@]}

	local -i child=0
	local -a Result

	if [ $size -eq 0 ]
	then
		Result[0]=$(octal $name)
	else
		for child in ${children[@]}
		do
			Result[${#Result[@]}]=$(rvalue $child)
		done

		Result[0]='('$(join ',\040' ${Result[@]})')'
	fi

	if [ $name = 'sqrt' ]
	then
		Result[0]=$(octal ${name@U})${Result[0]}
	else
		Result[0]=$(octal $name)${Result[0]}
		if [ $name != 'length' ]
		then
			Result='CALL\040'${Result[0]}
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
	echo 'CEILING('$(rvalue ${1:?})')'
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
	local -ar children=(${@:1})
	local -i child=0
	local -i size=0
	local -a Result
	for child in ${children[@]}
	do
		case ${T[$child]:4} in
			size|count)
				;;
			*)
				for built in $(emit $child '1'${context:1})
				do
					Result[$size]=$built
					size+=1
				done
				;;
		esac
	done

	echo ${Result[@]}
}

emit_declarations () {
	local -ar children=(${@:1})
	local -i child=0
	local -a Result
	for child in ${children[@]}
	do
		for built in $(emit $child '1'${context:1})
		do
			Result[${#Result[@]}]=$built
		done
	done

	echo $(join '!' ${Result[@]})
}

emit_declarationsBody () {
	local -ar children=(${@:1})
	local -i child=0
	local -a Result
	for child in ${children[@]}
	do
		for built in $(emit $child '1'${context:1})
		do
			Result[${#Result[@]}]=$built
		done
	done

	echo $(join '!' ${Result[@]})
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
					echo 'SIZE(elements)'
					;;
			esac
			;;
		*)
			case $parameter in
				x)
					echo $name'(1)'
					;;
				y)
					echo $name'(2)'
					;;
				z)
					echo $name'(3)'
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
			echo 'vertices(3\040*\040'$name'\040+\0401)'
			;;
		y)
			echo 'vertices(3\040*\040'$name'\040+\0402)'
			;;
		z)
			echo 'vertices(3\040*\040'$name'\040+\0403)'
			;;
	esac
}

emit_double () {
	echo ${T[${1:?}]}
}

emit_floor () {
	echo 'FLOOR('$(rvalue ${1:?})')'
}

emit_for () {
	local -a Result
	Result[0]=$(rvalue ${1:?})'\n'
	Result[1]='DO\040WHILE\040('$(rvalue ${2:?})')\n'

	for built in $(emit ${4:?} ${context:0:1}'1')
	do
		Result[${#Result[@]}]=$built
	done
	Result[${#Result[@]}]='\040\040\040\040\040\040\040\040'$(rvalue ${3:?})'\n'
	Result[${#Result[@]}]='END\040DO\n'

	echo ${Result[@]}
}

emit_forDouble () {
	local -a Result
	Result[0]=$(rvalue ${1:?})'\n'
	Result[1]='DO\040WHILE\040('$(rvalue ${2:?})')\n'

	for built in $(emit ${4:?} ${context:0:1}'1')
	do
		Result[${#Result[@]}]=$built
	done
	Result[${#Result[@]}]='\040\040\040\040\040\040\040\040'$(rvalue ${3:?})'\n'
	Result[${#Result[@]}]='END\040DO\n'

	echo ${Result[@]}
}

emit_function () {
	local -r name=${1:?}
	local -r parameters=$(rvalue ${3:?})
	local -r context='0'${context:1}

	local -a Result
	Result[0]=$(rvalue ${2:?})
	local -i size=1

	case ${Result[0]} in
		void)
			Result[1]='SUBROUTINE'
			;;
		*)
			Result[1]=${Result[0]}'\040PURE\040FUNCTION'
			;;
	esac
	Result[0]=${Result[1]}'\040'$(octal $name)$parameters'\n'

	case $parameters in
		*v1*)
			Result[1]='\040\040\040\040\040\040\040\040REAL\040(KIND=8),\040DIMENSION(3),\040INTENT(IN)\040::\040v1\n'
			size+=1
			;;
		*a*b*c*)
			Result[1]='\040\040\040\040\040\040\040\040INTEGER,\040INTENT(IN)\040::\040a\n'
			size+=1
			Result[2]='\040\040\040\040\040\040\040\040INTEGER,\040INTENT(IN)\040::\040b\n'
			size+=1
			Result[3]='\040\040\040\040\040\040\040\040INTEGER,\040INTENT(IN)\040::\040c\n'
			size+=1
			;;
	esac

	if [ $name = 'translate' ]
	then
		Result[$size]='\040\040\040\040\040\040\040\040INTEGER\040::\040count\040=\0400\n'
		size+=1
	fi

	local parameter=
	for built in $(emit_glue ${4:?})
	do
		for parameter in $(cut '!' ${built:32})
		do
			Result[$size]='\040\040\040\040\040\040\040\040'${parameter%\\040=*}

			case $parameter in
				*REAL*)
					Result[$size]+='\040=\0400.0\n'
					;;
				*INTEGER*)
					Result[$size]+='\040=\0400\n'
					;;
			esac

			size+=1
		done

		for parameter in $(cut '!' ${built:32})
		do
			case $parameter in
				*REAL*)
					case $parameter in
						*'\040=\0400.0\n')
							;;
						*)
							Result[$size]='\040\040\040\040\040\040\040\040'${parameter#*\\040::\\040}
							;;
					esac
					;;
				*INTEGER*)
					case $parameter in
						*'\040=\0400\n')
							;;
						*)
							Result[$size]='\040\040\040\040\040\040\040\040'${parameter#*\\040::\\040}
							;;
					esac
					;;
			esac

			size+=1
		done
	done

	if [ $name = 'translate' ]
	then
		Result[$size]='\040\040\040\040\040\040\040\040count\040=\0403\040*\040(SIZE(vertices)\040/\0409)\n'
		size+=1
	fi

	case ${Result[0]} in
		SUBROUTINE*)
			Result[-1]=${Result[-1]/'\n'*/'\n\n'}
			;;
	esac

	for built in $(emit_glue ${@:5})
	do
		Result[$size]=$built
		size+=1
	done

	case ${Result[0]} in
		SUBROUTINE*)
			Result[$size]='END\040SUBROUTINE\040'$(octal $name)'\n'
			size+=1
			;;
		*)
			Result[-1]=${Result[-1]/RETURN/$(octal $name)'\040='}
			Result[$size]='END\040FUNCTION\040'$(octal $name)'\n'
			size+=1
			;;
	esac

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
			Result[$size]='\040\040\040\040\040\040\040\040'$built
			size+=1
		done
	done

	echo ${Result[@]}
}

emit_identifier () {
	local -r name=${T[${1:?}]}
	local Result=$name

	if [[ ${#name} -eq 1 && ${name@u} = $name ]]
	then
		Result+=$name
	fi

	echo $Result
}

emit_identifierThis () {
	local -r name=${T[${1:?}]}
	local Result=$name

	if [[ ${#name} -eq 1 && ${name@u} = $name ]]
	then
		Result+=$name
	fi

	echo ${Result/size/count}
}

emit_identifierVector3d () {
	local -r name=${T[${1:?}]}
	local Result=$name

	if [[ ${#name} -eq 1 && ${name@u} = $name ]]
	then
		Result+=$name
	fi

	echo $Result'(1:3)'
}

emit_if () {
	local -ar children=(${@:1})
	local -ir size=${#children[@]}
	local -i child=0
	local -a Result

	Result[0]='IF\040('$(rvalue ${children[0]:?})')\040THEN\n'

	for built in $(emit ${children[1]:?} ${context:0:1}'1')
	do
		Result[${#Result[@]}]=$built
	done

	if [ $size -eq 3 ]
	then
		Result[${#Result[@]}]='ELSE\n'
		for built in $(emit ${children[2]:?} ${context:0:1}'1')
		do
			Result[${#Result[@]}]=$built
		done
	fi

	Result[${#Result[@]}]='END\040IF\n'

	echo ${Result[@]}
}

emit_ifAssignGrid () {
	echo $(emit_if ${@:1})
}

emit_increment () {
	local -r name=$(lvalue ${1:?})
	echo $name'\040=\040'$name'\040+\0401'
}

emit_int () {
	echo ${T[${1:?}]}
}

emit_min () {
	echo $(rvalue ${1:?})':'$(rvalue ${2:?})
}

emit_minusAssignVector3d () {
	local -r name=$(lvalue ${1:?})

	echo $name'\040=\040'$name'\040-\040'$(lvalue ${2:?})'\n'
}

emit_minusAssignVertex () {
	local -r name=$(rvalue ${1:?})
	local -r value=$(lvalue ${2:?})

	echo 'vertices(3\040*\040'$name'\040+\0401:3\040*\040'$name'\040+\0403)\040=\040vertices(3\040*\040'$name'\040+\0401:3\040*\040'$name'\040+\0403)\040-\040'$value'(1:3)\n'
}

emit_minusDouble () {
	echo $(rvalue ${1:?})'\040-\040'$(rvalue ${2:?})
}

emit_minusVector3d () {
	echo $(lvalue ${1:?})'\040-\040'$(lvalue ${2:?})
}

emit_multiplyDouble () {
	echo $(rvalue ${1:?})'\040*\040'$(rvalue ${2:?})
}

emit_multiplyInt () {
	echo $(rvalue ${1:?})'\040*\040'$(rvalue ${2:?})
}

emit_newGrid () {
	local -ar parameters=($(rvalue ${4:?}) $(rvalue ${5:?}) $(rvalue ${6:?}))
	local -a Result=($(rvalue ${1:?}) $(rvalue ${2:?}) $(rvalue ${3:?}))
	Result[2]+='\n'
	Result[3]='IF\040(ALLOCATED(grid))\040THEN\n'
	Result[4]='\040\040\040\040\040\040\040\040DEALLOCATE(grid)\n'
	Result[5]='END\040IF\n'
	Result[6]='ALLOCATE(grid('${parameters[0]}',\040'${parameters[1]}',\040'${parameters[2]}'))\n'
	Result[7]='grid(1:'${parameters[0]}',\0401:'${parameters[1]}',\0401:'${parameters[2]}')\040=\040.FALSE.\n'

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
			echo '/='
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
	echo 'RETURN\040'$(rvalue ${1:?})'\n'
}

emit_scaleVector3d () {
	local -r name=$(lvalue ${1:?})

	echo $name'\040=\040'$name'\040*\040'$(rvalue ${2:?})'\n'
}

emit_triangle () {
	local -a Result

	Result[0]=$(rvalue ${1:?})
	Result[1]='elements('${Result[0]}'\040+\0402)'
	Result[2]='elements('${Result[0]}'\040+\0403)'
	Result[0]='elements('${Result[0]}'\040+\0401)'

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
						Result[-1]='INTEGER'
						;;
					double)
						Result[-1]='REAL\040(KIND=8)'
						;;
				esac

				Result[-1]+=',\040ALLOCATABLE,\040DIMENSION(:)'
				;;
			Grid)
				Result[-1]='LOGICAL,\040ALLOCATABLE,\040DIMENSION(:,\040:,\040:)'
				;;
			double)
				Result[-1]='REAL\040(KIND=8)'
				;;
			index*|size*)
				Result[-1]='INTEGER'
				;;
			static|const)
				Result[-1]=
				;;
		esac
	done

	echo ${Result[@]}
}

emit_var() {
	local -r name=${1:?}
	local -ar parameters=(${@:2})
	local -ir size=${#parameters[@]}

	local -a attributes
	local value=$(rvalue ${2:?})
	local -a Result

	attributes[0]=$value
	case $value in
		*Vector3d*)
			if [ $size -lt 2 ]
			then
				value='0.0'
			fi

			attributes[0]='REAL\040(KIND=8),\040DIMENSION(3)'
			;;
		*REAL*)
			if [ $size -lt 2 ]
			then
				value='0.0'
			fi
			;;
		*INTEGER*)
			if [ $size -lt 2 ]
			then
				value='0'
			fi
			;;
	esac

	if [ $size -gt 1 ]
	then
		value=$(rvalue ${parameters[1]})

		if [ ${T[${parameters[1]}]} = 'min' ]
		then
			Result=($(cut ':' $value))
			value=${Result[1]}
			Result[1]='IF\040('$name'\040>\040'${Result[0]}')\040THEN\n'
			Result[2]='\040\040\040\040\040\040\040\040'$name'\040=\040'${Result[0]}'\n'
			Result[3]='END\040IF\n'
		fi
	fi

	if [ -n $name ]
	then
		Result[0]=$name

		if [[ ${#name} -eq 1 && ${name@u} = $name ]]
		then
			Result[0]+=$name
		fi
	fi

	if [[ ${context:0:1} -eq 1 && ${#attributes[@]} -gt 0 ]]
	then
		Result[0]=$(join '\040' ${attributes[@]})'\040::\040'${Result[0]}
	fi

	case ${Result[0]} in
		*ALLOCATABLE*)
			;;
		*)
			Result[0]+='\040=\040'$value
			;;
	esac

	if [ ${context:1:1} -eq 1 ]
	then
		Result[0]+='\n'

		if [ ${#Result[@]} -gt 1 ]
		then
			Result[0]+='\n'
		fi
	fi

	echo ${Result[@]}
}

emit_vertex () {
	local -ir cut=${1:?}
	local -ir name=${2:?}
	local Result=

	if [ $cut -eq 1 ]
	then
		Result='vertices('$((3 * $name + 1))':'$((3 * $name + 3))')'
	else
		Result=$(rvalue $name)
		Result='vertices(3\040\052\040'$Result'\040+\0401:3\040\052\040'$Result'\040+\0403)'
	fi

	echo $Result
}

build_files () {
	build_file "${@:1:2}" 'f90'
}

. ./build.sh fortran
