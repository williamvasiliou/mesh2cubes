#!/usr/bin/env bash

lvalue () {
	echo $(join '\040' $(emit ${1:?} ${context:0:1}'0'))
}

rvalue () {
	echo $(join '\040' $(emit ${1:?} ${context:0:1}'0'))
}

emit_mesh2cubes () {
	local -a Result
	Result[0]='import\040java.lang.Math;\n'
	Result[1]='import\040java.util.ArrayList;\n\n'
	Result[2]='public\040final\040class\040mesh2cubes\040{\n'
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

emit_and () {
	echo $(rvalue ${1:?})'\040&&\040'$(rvalue ${2:?})
}

emit_assignDouble () {
	echo $(lvalue ${1:?})'\040=\040'$(rvalue ${2:?})';\n'
}

emit_assignGrid () {
	echo 'this.grid['$(rvalue ${1:?})'\040+\040xr]['$(rvalue ${2:?})'\040+\040yr]['$(rvalue ${3:?})'\040+\040zr]\040=\040true;\n'
}

emit_assignVector3d () {
	echo $(lvalue ${1:?})'\040=\040'$(rvalue ${2:?})';\n'
}

emit_averageVector3d () {
	local -r name=$(lvalue ${1:?})
	local -r value=$(lvalue ${2:?})

	echo 'new\040double[]\040{'$name'[0]\040/\0402.0\040+\040'$value'[0]\040/\0402.0,\040'$name'[1]\040/\0402.0\040+\040'$value'[1]\040/\0402.0,\040'$name'[2]\040/\0402.0\040+\040'$value'[2]\040/\0402.0}'
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
	fi

	if [ $name = 'sqrt' ]
	then
		Result[0]='Math.'${Result[0]}
	fi

	if [ ${context:1:1} -eq 1 ]
	then
		echo ${Result[0]}';\n'
	else
		echo ${Result[0]}
	fi
}

emit_ceil () {
	echo '(int)\040Math.ceil('$(rvalue ${1:?})')'
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

emit_constructor () {
	local -ar children=${@:1}
	local -i child=0
	local -i size=0
	local -a Result
	local -a parameters
	for child in ${children[@]}
	do
		for built in $(emit $child '1'${context:1})
		do
			Result[$size]=$built
			size+=1
		done
	done

	if [ $size -gt 0 ]
	then
		Result[$(($size - 1))]+='\n'

		Result[$size]='public\040mesh2cubes\040()\040{\n'
		size+=1

		for child in ${children[@]}
		do
			parameters=($(cut ':' ${T[$child]}))
			parameters=($(cut ',' ${parameters[1]}))

			if [ ${#parameters[@]} -gt 2 ]
			then
				for built in $(emit $child '0'${context:1})
				do
					Result[$size]='\tthis.'${built:${#parameters[0]}+4}
					size+=1
				done
			else
				case ${parameters[1]} in
					vertices)
						Result[$size]='\tthis.vertices\040=\040new\040ArrayList<Double>();\n'
						size+=1
						;;
					elements)
						Result[$size]='\tthis.elements\040=\040new\040ArrayList<Integer>();\n'
						size+=1
						;;
					grid)
						;;
					*)
						Result[$size]='\tthis.'${parameters[1]}'\040=\040new\040double[]\040{0.0,\0400.0,\0400.0};\n'
						size+=1
						;;
				esac
			fi
		done

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
			echo 'this.elements.'$parameter'()'
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

emit_dotVertex () {
	local -r name=$(rvalue ${1:?})

	case ${T[${2:?}]} in
		x)
			echo 'this.vertices.get(3\040*\040'$name')'
			;;
		y)
			echo 'this.vertices.get(3\040*\040'$name'\040+\0401)'
			;;
		z)
			echo 'this.vertices.get(3\040*\040'$name'\040+\0402)'
			;;
	esac
}

emit_double () {
	echo ${T[${1:?}]}
}

emit_floor () {
	echo '(int)\040Math.floor('$(rvalue ${1:?})')'
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
	local -ar parameters=${@:2}
	local -i size=${#parameters[@]}
	local -r context='0'${context:1}

	local -a Result=('public\040')
	case $name in
		length)
			Result[0]=${Result[0]}'double'
			;;
		*)
			Result[0]=${Result[0]}'void'
			;;
	esac

	Result[0]=${Result[0]}'\040'$(octal $name)'\040('
	if [ $size -gt 0 ]
	then
		size=0
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
				parameter=${parameter/Vector3d/'double[]'}
			fi

			Result[0]=${Result[0]}$parameter
			size+=1
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

emit_identifierVector3d () {
	local -r name=${T[${1:?}]}
	echo 'new\040double[]\040{'$name'[0],\040'$name'[1],\040'$name'[2]}'
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

	Result[0]='this.vertices.set(3\040*\040'$name',\040this.vertices.get(3\040*\040'$name')\040-\040'$value'[0]);\n'
	Result[1]='this.vertices.set(3\040*\040'$name'\040+\0401,\040this.vertices.get(3\040*\040'$name'\040+\0401)\040-\040'$value'[1]);\n'
	Result[2]='this.vertices.set(3\040*\040'$name'\040+\0402,\040this.vertices.get(3\040*\040'$name'\040+\0402)\040-\040'$value'[2]);\n'

	echo ${Result[@]}
}

emit_minusDouble () {
	echo $(rvalue ${1:?})'\040-\040'$(rvalue ${2:?})
}

emit_minusVector3d () {
	local -r name=$(lvalue ${1:?})
	local -r value=$(lvalue ${2:?})

	echo 'new\040double[]\040{'$name'[0]\040-\040'$value'[0],\040'$name'[1]\040-\040'$value'[1],\040'$name'[2]\040-\040'$value'[2]}'
}

emit_multiplyDouble () {
	echo $(rvalue ${1:?})'\040*\040'$(rvalue ${2:?})
}

emit_newGrid () {
	echo 'this.grid\040=\040new\040boolean[2\040*\040'$(rvalue ${1:?})'\040+\0401][2\040*\040'$(rvalue ${2:?})'\040+\0401][2\040*\040'$(rvalue ${3:?})'\040+\0401];\n'
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
	Result[1]='this.elements.get('${Result[0]}'\040+\0401)'
	Result[2]='this.elements.get('${Result[0]}'\040+\0402)'
	Result[0]='this.elements.get('${Result[0]}')'

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

	local -i child=0
	local Result

	if [ ${context:0:1} -eq 1 ]
	then
		attributes[0]='public'
	fi

	if [ $cut -eq 1 ]
	then
		case ${parameters[0]} in
			*'[]')
				attributes[${#attributes[@]}]=${parameters[0]%'[]'}

				case ${attributes[-1]} in
					int)
						attributes[${#attributes[@]}]='ArrayList<Integer>'
						;;
					*)
						attributes[${#attributes[@]}]='ArrayList<'${attributes[-1]@u}'>'
						;;
				esac

				attributes[-2]='final'
				;;
			Vector3d)
				attributes[${#attributes[@]}]='double[]'
				;;
			Grid)
				attributes[${#attributes[@]}]='boolean[][][]'
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
				attributes[${#attributes[@]}]='final'
				name=${name/'const\040'/}
				;;
		esac

		case $name in
			*Vector3d*)
				attributes[${#attributes[@]}]='double[]'
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

	if [[ -n $name && -n $value ]]
	then
		if [ ${context:0:1} -eq 0 ]
		then
			Result=$name'\040=\040'$value
		else
			Result=$name
		fi
	else
		Result=$name
	fi

	if [ ${#attributes[@]} -gt 0 ]
	then
		Result=$(join '\040' ${attributes[@]})'\040'$Result
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
	local -a Result

	if [ $cut -eq 1 ]
	then
		Result[0]='this.vertices.get('$((3 * $name))')'
		Result[1]='this.vertices.get('$((3 * $name + 1))')'
		Result[2]='this.vertices.get('$((3 * $name + 2))')'
	else
		Result[0]=$(rvalue $name)
		Result[1]='this.vertices.get(3\040*\040'${Result[0]}'\040+\0401)'
		Result[2]='this.vertices.get(3\040*\040'${Result[0]}'\040+\0402)'
		Result[0]='this.vertices.get(3\040*\040'${Result[0]}')'
	fi

	echo 'new\040double[]\040{'$(join ',\040' ${Result[@]})'}'
}

. ./build.sh java
javac ./java/mesh2cubes.java
