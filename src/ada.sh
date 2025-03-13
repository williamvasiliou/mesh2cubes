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
	if [ ${#context} -eq 2 ]
	then
		Result[0]='with\040Ada.Strings;\n'
		Result[1]='with\040Ada.Strings.Fixed;\n\n'

		Result[2]='package\040body\040mesh2cubes\040is\n'
	else
		Result[0]='with\040Ada.Containers.Vectors;\n'
		Result[1]='with\040Ada.Containers.Ordered_Sets;\n'
		Result[2]='with\040Ada.Numerics.Generic_Elementary_Functions;\n'
		Result[3]='with\040Ada.Strings.Unbounded;\n\n'

		Result[4]='use\040Ada.Containers;\n\n'

		Result[5]='package\040mesh2cubes\040is\n'
		Result[6]='\ttype\040Double\040is\040digits\04017\040range\040-1.7976931348623157e+308\040..\0401.7976931348623157e+308;\n'
		Result[7]='\tpackage\040Math\040is\040new\040Ada.Numerics.Generic_Elementary_Functions\040(Double);\n'
		Result[8]='\tpackage\040Doubles\040is\040new\040Vectors\040(Positive,\040Double);\n'
		Result[9]='\tpackage\040Indices\040is\040new\040Vectors\040(Positive,\040Natural);\n'
		Result[10]='\tpackage\040SU\040renames\040Ada.Strings.Unbounded;\n'
		Result[11]='\tuse\040type\040SU.Unbounded_String;\n'
		Result[12]='\tpackage\040Grid3\040is\040new\040Ordered_Sets\040(SU.Unbounded_String);\n'
		Result[13]='\ttype\040Vector3d\040is\040array\040(1\040..\0403)\040of\040Double;\n\n'
	fi

	local -i size=${#Result[@]}

	for child in ${children[@]}
	do
		if [ $child -gt 0 ]
		then
			case ${T[$child]} in
				constructor)
					if [ ${#context} -eq 2 ]
					then
						continue
					fi
					;;
				function:*)
					if [ $size -gt 3 ]
					then
						Result[$(($size - 1))]+='\n'
					fi
					;;
			esac

			for built in $(emit $child $context)
			do
				Result[$size]='\t'$built
				size+=1
			done
		fi
	done
	Result[$size]='end\040mesh2cubes;\n'

	if [ ${#context} -eq 3 ]
	then
		Result[$(($size - 1))]+='\n'
	fi

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
	echo $(rvalue ${1:?})
}

emit_and () {
	echo $(rvalue ${1:?})'\040and\040then\040'$(rvalue ${2:?})
}

emit_assignDouble () {
	echo $(lvalue ${1:?})'\040:=\040'$(rvalue ${2:?})';\n'
}

emit_assignGrid () {
	echo 'grid.Include\040(SU.To_Unbounded_String\040(image\040('$(rvalue ${1:?})')\040&\040","\040&\040image\040('$(rvalue ${2:?})')\040&\040","\040&\040image\040('$(rvalue ${3:?})')));\n'
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
		Result[0]=$(octal $name)
	else
		for child in ${children[@]}
		do
			Result[${#Result[@]}]=$(rvalue $child)
		done

		Result[0]='\040('$(join ',\040' ${Result[@]})')'
	fi

	if [ $name = 'sqrt' ]
	then
		Result[0]='Math.'$(octal ${name@u})${Result[0]}
	else
		Result[0]=$(octal $name)${Result[0]}
	fi

	if [ ${context:1:1} -eq 1 ]
	then
		echo ${Result[0]}';\n'
	else
		echo ${Result[0]}
	fi
}

emit_ceil () {
	echo 'Natural\040(Double'\''Ceiling\040('$(rvalue ${1:?})'))'
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
			count|xl|yl|zl)
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

	echo ${Result[@]}
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
					echo 'Natural\040(elements.Length)'
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

emit_dotCount () {
	echo 'count'
}

emit_dotVertex () {
	local -r name=$(rvalue ${1:?})

	case ${T[${2:?}]} in
		x)
			echo 'vertices.Element\040(3\040*\040'$name'\040+\0401)'
			;;
		y)
			echo 'vertices.Element\040(3\040*\040'$name'\040+\0402)'
			;;
		z)
			echo 'vertices.Element\040(3\040*\040'$name'\040+\0403)'
			;;
	esac
}

emit_double () {
	echo ${T[${1:?}]}
}

emit_floor () {
	echo 'Integer\040(Double'\''Floor\040('$(rvalue ${1:?})'))'
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
	local -r parameters=$(rvalue ${3:?})
	local -r context='0'${context:1}

	local -a Result
	Result[0]=$(rvalue ${2:?})
	local -i size=1

	case ${Result[0]} in
		void)
			Result[1]='procedure'
			;;
		*)
			Result[1]='function'
			;;
	esac

	Result[1]+='\040'$(octal $name)
	if [ ${#parameters} -gt 2 ]
	then
		Result[1]+='\040'$parameters
	fi

	case ${Result[0]} in
		void)
			Result[0]=${Result[1]}
			;;
		*)
			Result[0]=${Result[1]}'\040return\040'${Result[0]}
			;;
	esac

	if [ ${#context} -eq 2 ]
	then
		Result[0]+='\040is\n'
		for built in $(emit_glue ${4:?})
		do
			Result[$size]=$built
			size+=1
		done

		if [ $name = 'cube' ]
		then
			Result[$(($size - 1))]+='\n'

			Result[$size]='\tfunction\040image\040(i:\040in\040Integer)\040return\040String\040is\n'
			size+=1
			Result[$size]='\t\tuse\040Ada.Strings;\n'
			size+=1
			Result[$size]='\t\tuse\040Ada.Strings.Fixed;\n'
			size+=1
			Result[$size]='\tbegin\n'
			size+=1
			Result[$size]='\t\treturn\040Trim\040(i'\''Image,\040Left);\n'
			size+=1
			Result[$size]='\tend\040image;\n'
			size+=1
		fi

		Result[$size]='begin\n'
		size+=1
		for built in $(emit_glue ${@:5})
		do
			Result[$size]=$built
			size+=1
		done
		Result[$size]='end\040'$(octal $name)';\n'
		size+=1

		echo ${Result[@]}
	else
		echo ${Result[0]}';'
	fi
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

	echo $Result
}

emit_identifierVector3d () {
	local -r name=${T[${1:?}]}
	local Result=$name

	if [[ ${#name} -eq 1 && ${name@u} = $name ]]
	then
		Result+=$name
	fi

	echo $Result'\040(1\040..\0403)'
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
	echo $(rvalue ${1:?})':'$(rvalue ${2:?})
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

	Result[0]='vertices.Replace_Element\040(3\040*\040'$name'\040+\0401,\040vertices.Element\040(3\040*\040'$name'\040+\0401)\040-\040'$value'\040(1));\n'
	Result[1]='vertices.Replace_Element\040(3\040*\040'$name'\040+\0402,\040vertices.Element\040(3\040*\040'$name'\040+\0402)\040-\040'$value'\040(2));\n'
	Result[2]='vertices.Replace_Element\040(3\040*\040'$name'\040+\0403,\040vertices.Element\040(3\040*\040'$name'\040+\0403)\040-\040'$value'\040(3));\n'

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
	echo
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

emit_parameter () {
	echo $(rvalue ${2:?})':\040in\040'$(rvalue ${1:?})
}

emit_parameters () {
	local -ar children=(${@:1})
	local -i child=0
	local -a Result
	for child in ${children[@]}
	do
		Result[${#Result[@]}]=$(rvalue $child)
	done

	echo '('$(join ';\040' ${Result[@]})')'
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
	Result[1]='elements.Element\040(Positive\040('${Result[0]}'\040+\0402))'
	Result[2]='elements.Element\040(Positive\040('${Result[0]}'\040+\0403))'
	Result[0]='elements.Element\040(Positive\040('${Result[0]}'\040+\0401))'

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
						Result[-1]='Indices'
						;;
					*)
						Result[-1]=${Result[-1]@u}'s'
						;;
				esac

				Result[-1]+='.Vector'
				;;
			Grid)
				Result[-1]+='3.Set'
				;;
			const)
				Result[-1]+='ant'
				;;
			double)
				Result[-1]=${Result[-1]@u}
				;;
			index|size*)
				Result[-1]='Natural'
				;;
			index.grid)
				Result[-1]='Integer'
				;;
			static)
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
		Doubles.*|Indices.*|Grid3.*)
			if [ $size -lt 2 ]
			then
				value=${value/'.'/'.Empty_'}
			fi
			;;
		*Vector3d*)
			if [ $size -lt 2 ]
			then
				value='(0.0,\0400.0,\0400.0)'
			fi
			;;
		Double)
			if [ $size -lt 2 ]
			then
				value='0.0'
			fi
			;;
		Natural)
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
			Result[1]='if\040'$name'\040>\040'${Result[0]}'\040then\n'
			Result[2]='\t'$name'\040:=\040'${Result[0]}';\n'
			Result[3]='end\040if;\n'
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
		Result[0]+=':\040'$(join '\040' ${attributes[@]})
	fi

	if [ -n $value ]
	then
		Result[0]+='\040:=\040'$value
	fi

	if [ ${context:1:1} -eq 1 ]
	then
		Result[0]+=';\n'

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
	local -a Result

	if [ $cut -eq 1 ]
	then
		Result[0]='vertices.Element\040('$((3 * $name + 1))')'
		Result[1]='vertices.Element\040('$((3 * $name + 2))')'
		Result[2]='vertices.Element\040('$((3 * $name + 3))')'
	else
		Result[0]=$(rvalue $name)
		Result[1]='vertices.Element\040(3\040*\040'${Result[0]}'\040+\0402)'
		Result[2]='vertices.Element\040(3\040*\040'${Result[0]}'\040+\0403)'
		Result[0]='vertices.Element\040(3\040*\040'${Result[0]}'\040+\0401)'
	fi

	echo '('$(join ',\040' ${Result[@]})')'
}

build_files () {
	build_file "${@:1:2}" 'adb'
	build_file "${@:1:2}" 'ads' '111'
}

. ./build.sh ada
