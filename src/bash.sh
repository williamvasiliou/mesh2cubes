#!/usr/bin/env bash

lvalue () {
	local -r name=$(join '\040' $(emit ${1:?} ${context:0:1}'0'))

	if [ ${name:0:2} = '${' ]
	then
		echo ${name:2:-1}
	else
		echo ${name:1}
	fi
}

rvalue () {
	echo $(join '\040' $(emit ${1:?} ${context:0:1}'0'))
}

emit_mesh2cubes () {
	local -a Result=('#!/usr/bin/env\040bash\n\n')
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
				Result[$size]=$built
				size+=1
			done
		fi
	done

	echo ${Result[@]}
}

emit_addAssignDouble () {
	local -r name=$(lvalue ${1:?})
	local -r Result=$name'=$(echo\040$'$name'\040'$(rvalue ${2:?})'\040|\040awk\040'\''{\040print\040$1\040+\040$2\040}'\'')'

	if [ ${context:1:1} -eq 1 ]
	then
		echo $Result'\n'
	else
		echo $Result
	fi
}

emit_addAssignInt () {
	local -r Result=$(lvalue ${1:?})'+='$(rvalue ${2:?})

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

	Result[0]=$name'[0]=$(echo\040${'$name'[0]}\040${'$value'[0]}\040|\040awk\040'\''{\040print\040$1\040+\040$2\040}'\'')\n'
	Result[1]=$name'[1]=$(echo\040${'$name'[1]}\040${'$value'[1]}\040|\040awk\040'\''{\040print\040$1\040+\040$2\040}'\'')\n'
	Result[2]=$name'[2]=$(echo\040${'$name'[2]}\040${'$value'[2]}\040|\040awk\040'\''{\040print\040$1\040+\040$2\040}'\'')\n'

	echo ${Result[@]}
}

emit_addDouble () {
	echo '$(echo\040'$(rvalue ${1:?})'\040'$(rvalue ${2:?})'\040|\040awk\040'\''{\040print\040$1\040+\040$2\040}'\'')'
}

emit_addInt () {
	echo '$(('$(rvalue ${1:?})'\040+\040'$(rvalue ${2:?})'))'
}

emit_addLow () {
	echo $(rvalue ${1:?})
}

emit_and () {
	local -a Result=($(rvalue ${1:?}) $(rvalue ${2:?}))

	echo '\133'${Result[0]:0:-4}'&&'${Result[1]:4}'\135'
}

emit_assignDouble () {
	echo $(lvalue ${1:?})'='$(rvalue ${2:?})'\n'
}

emit_assignGrid () {
	echo 'grid["'$(rvalue ${1:?})','$(rvalue ${2:?})','$(rvalue ${3:?})'"]=1\n'
}

emit_assignInt () {
	echo $(lvalue ${1:?})'='$(rvalue ${2:?})'\n'
}

emit_assignVector3d () {
	echo $(lvalue ${1:?})'='$(rvalue ${2:?})'\n'
}

emit_averageVector3d () {
	local -r name=$(lvalue ${1:?})
	local -r value=$(lvalue ${2:?})

	echo '($(echo\040${'$name'[0]}\040${'$value'[0]}\040|\040awk\040'\''{\040print\040$1\040/\0402\040+\040$2\040/\0402\040}'\'') $(echo\040${'$name'[1]}\040${'$value'[1]}\040|\040awk\040'\''{\040print\040$1\040/\0402\040+\040$2\040/\0402\040}'\'') $(echo\040${'$name'[2]}\040${'$value'[2]}\040|\040awk\040'\''{\040print\040$1\040/\0402\040+\040$2\040/\0402\040}'\''))'
}

emit_call () {
	local -r name=${1:?}
	local -ar children=(${@:2})
	local -ir size=${#children[@]}

	local -i child=0
	local -a Result

	case $name in
		cube|length)
			Result[0]=$(octal $name)'\040${'$(lvalue ${2:?})'[@]}'

			;;
		sqrt)
			Result[0]='echo\040'$(rvalue ${2:?})'\040|\040awk\040'\''{\040print\040sqrt($1)\040}'\'

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

				Result[0]=$(octal $name)'\040'$(join '\040' ${Result[@]})
			fi

			;;
	esac

	if [ ${context:1:1} -eq 1 ]
	then
		echo ${Result[0]}'\n'
	else
		echo '$('${Result[0]}')'
	fi
}

emit_ceil () {
	echo '$(echo\040'$(rvalue ${1:?})'\040|\040awk\040'\''{\040if\040($1\040>\0400)\040{\040d\040=\040$1\040\045\0401;\040if\040(d\040>\0400)\040{\040print\040$1\040-\040d\040+\0401\040}\040else\040{\040print\040$1\040}\040}\040else\040{\040print\0400\040}\040}'\'')'
}

emit_compareDouble () {
	local -a Result
	Result[0]=$(rvalue ${1:?})
	Result[1]=$(rvalue ${2:?})
	Result[1]=${Result[1]/-le/'<='}
	Result[1]=${Result[1]/-lt/'<'}
	Result[1]=${Result[1]/-gt/'>'}
	Result[2]=$(rvalue ${3:?})

	echo '\133\040$(echo\040'${Result[0]}'\040'${Result[2]}'\040|\040awk\040'\''{\040print($1\040'${Result[1]}'\040$2)\040}'\'')\040-gt\0400\040\135'
}

emit_compareInt () {
	local -ar children=(${@:1:3})
	local -i child=0
	local -a Result
	for child in ${children[@]}
	do
		Result[${#Result[@]}]=$(rvalue $child)
	done

	echo '\133\040'$(join '\040' ${Result[@]})'\040\135'
}

emit_compareLow () {
	echo
}

emit_constructor () {
	local -ar children=${@:1}
	local -i child=0
	local -a Result
	for child in ${children[@]}
	do
		case ${T[$child]} in
			var:size.elements*|var:size.grid*)
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

emit_divideDouble () {
	echo '$(echo\040'$(rvalue ${1:?})'\040'$(rvalue ${2:?})'\040|\040awk\040'\''{\040print\040$1\040/\040$2\040}'\'')'
}

emit_dot() {
	local -r name=${T[${1:?}]}
	local -r parameter=${T[${2:?}]}

	case $name in
		triangles)
			case $parameter in
				size)
					echo '${#elements[@]}'
					;;
			esac
			;;
		v1)
			case $parameter in
				x)
					echo '$1'
					;;
				y)
					echo '$2'
					;;
				z)
					echo '$3'
					;;
			esac
			;;
		*)
			case $parameter in
				x)
					echo '${'$name'[0]}'
					;;
				y)
					echo '${'$name'[1]}'
					;;
				z)
					echo '${'$name'[2]}'
					;;
			esac
			;;
	esac
}

emit_dotVertex () {
	local -r name=$(rvalue ${1:?})

	case ${T[${2:?}]} in
		x)
			echo '${vertices[$((3\040*\040'$name'))]}'
			;;
		y)
			echo '${vertices[$((3\040*\040'$name'\040+\0401))]}'
			;;
		z)
			echo '${vertices[$((3\040*\040'$name'\040+\0402))]}'
			;;
	esac
}

emit_double () {
	echo \'${T[${1:?}]}\'
}

emit_floor () {
	echo '$(echo\040'$(rvalue ${1:?})'\040|\040awk\040'\''{\040if\040($1\040<\0400)\040{\040d\040=\040$1\040\045\0401;\040if\040(d\040<\0400)\040{\040print\040$1\040-\040d\040-\0401\040}\040else\040{\040print\040$1\040}\040}\040else\040{\040print\040$1\040-\040$1\040\045\0401\040}\040}'\'')'
}

emit_for () {
	local -a Result=('for\040((\040'$(rvalue ${1:?}))

	local parameters=$(rvalue ${2:?})
	parameters=${parameters:9:-8}
	parameters=${parameters/-lt/'<'}
	Result[0]=${Result[0]}'\040;\040'$parameters

	parameters=$(rvalue ${3:?})
	Result[0]=${Result[0]}'\040;\040'$parameters'\040))\n'

	Result[1]='do\n'
	for built in $(emit ${4:?} ${context:0:1}'1')
	do
		Result[${#Result[@]}]=$built
	done
	Result[${#Result[@]}]='done\n'

	echo ${Result[@]}
}

emit_forDouble () {
	local -a Result
	Result[0]=$(join '\040' $(emit ${1:?} ${context:0:1}'1'))
	Result[1]='while\040'$(rvalue ${2:?})'\n'

	Result[2]='do\n'
	for built in $(emit ${4:?} ${context:0:1}'1')
	do
		Result[${#Result[@]}]=$built
	done
	Result[${#Result[@]}]='\t'$(rvalue ${3:?})'\n'
	Result[${#Result[@]}]='done\n'

	echo ${Result[@]}
}

emit_function () {
	local -a Result=($(octal ${1:?})'\040()\040{\n')
	local -r context='0'${context:1}

	for built in $(emit_glue ${children[@]})
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
	echo '(${'${T[${1:?}]}'[@]})'
}

emit_if () {
	local -ar children=(${@:1})
	local -ir size=${#children[@]}
	local -i child=0
	local -a Result=('if\040'$(rvalue ${children[0]})'\n')

	Result[${#Result[@]}]='then\n'
	for child in ${children[1]}
	do
		for built in $(emit $child ${context:0:1}'1')
		do
			Result[${#Result[@]}]=$built
		done
	done

	if [ $size -eq 3 ]
	then
		Result[${#Result[@]}]='else\n'
		for child in ${children[2]}
		do
			for built in $(emit $child ${context:0:1}'1')
			do
				Result[${#Result[@]}]=$built
			done
		done
	fi

	Result[${#Result[@]}]='fi\n'

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
	echo '$(echo\040'$(rvalue ${1:?})'\040'$(rvalue ${2:?})'\040|\040awk\040'\''{\040if\040($1\040<\040$2)\040{\040print\040$1\040}\040else\040{\040print\040$2\040}\040}'\'')'
}

emit_minusAssignVector3d () {
	local -r name=$(lvalue ${1:?})
	local -r value=$(lvalue ${2:?})
	local -a Result

	Result[0]=$name'[0]=$(echo\040${'$name'[0]}\040${'$value'[0]}\040|\040awk\040'\''{\040print\040$1\040-\040$2\040}'\'')\n'
	Result[1]=$name'[1]=$(echo\040${'$name'[1]}\040${'$value'[1]}\040|\040awk\040'\''{\040print\040$1\040-\040$2\040}'\'')\n'
	Result[2]=$name'[2]=$(echo\040${'$name'[2]}\040${'$value'[2]}\040|\040awk\040'\''{\040print\040$1\040-\040$2\040}'\'')\n'

	echo ${Result[@]}
}

emit_minusAssignVertex () {
	local -r name=$(rvalue ${1:?})
	local -r value=$(lvalue ${2:?})
	local -a Result

	Result[0]='vertices[$((3\040*\040'$name'))]=$(echo\040${vertices[$((3\040*\040'$name'))]}\040${'$value'[0]}\040|\040awk\040'\''{\040print\040$1\040-\040$2\040}'\'')\n'
	Result[1]='vertices[$((3\040*\040'$name'\040+\0401))]=$(echo\040${vertices[$((3\040*\040'$name'\040+\0401))]}\040${'$value'[1]}\040|\040awk\040'\''{\040print\040$1\040-\040$2\040}'\'')\n'
	Result[2]='vertices[$((3\040*\040'$name'\040+\0402))]=$(echo\040${vertices[$((3\040*\040'$name'\040+\0402))]}\040${'$value'[2]}\040|\040awk\040'\''{\040print\040$1\040-\040$2\040}'\'')\n'

	echo ${Result[@]}
}

emit_minusDouble () {
	echo '$(echo\040'$(rvalue ${1:?})'\040'$(rvalue ${2:?})'\040|\040awk\040'\''{\040print\040$1\040-\040$2\040}'\'')'
}

emit_minusVector3d () {
	local -r name=$(lvalue ${1:?})
	local -r value=$(lvalue ${2:?})

	echo '($(echo\040${'$name'[0]}\040${'$value'[0]}\040|\040awk\040'\''{\040print\040$1\040-\040$2\040}'\'') $(echo\040${'$name'[1]}\040${'$value'[1]}\040|\040awk\040'\''{\040print\040$1\040-\040$2\040}'\'') $(echo\040${'$name'[2]}\040${'$value'[2]}\040|\040awk\040'\''{\040print\040$1\040-\040$2\040}'\''))'
}

emit_multiplyDouble () {
	echo '$(echo\040'$(rvalue ${1:?})'\040'$(rvalue ${2:?})'\040|\040awk\040'\''{\040print\040$1\040*\040$2\040}'\'')'
}

emit_multiplyInt () {
	echo '$(('$(rvalue ${1:?})'\040*\040'$(rvalue ${2:?})'))'
}

emit_newGrid () {
	echo
}

emit_operator () {
	case ${T[${1:?}]} in
		eq)
			echo '-eq'
			;;
		ge)
			echo '-ge'
			;;
		gt)
			echo '-gt'
			;;
		le)
			echo '-le'
			;;
		lt)
			echo '-lt'
			;;
		ne)
			echo '-ne'
			;;
	esac
}

emit_positional () {
	echo $(rvalue ${1:?})
}

emit_return () {
	echo 'echo\040'$(rvalue ${1:?})'\n'
}

emit_scaleVector3d () {
	local -r name=$(lvalue ${1:?})
	local -r value=$(rvalue ${2:?})
	local -a Result

	Result[0]=$name'[0]=$(echo\040${'$name'[0]}\040'$value'\040|\040awk\040'\''{\040print\040$1\040*\040$2\040}'\'')\n'
	Result[1]=$name'[1]=$(echo\040${'$name'[1]}\040'$value'\040|\040awk\040'\''{\040print\040$1\040*\040$2\040}'\'')\n'
	Result[2]=$name'[2]=$(echo\040${'$name'[2]}\040'$value'\040|\040awk\040'\''{\040print\040$1\040*\040$2\040}'\'')\n'

	echo ${Result[@]}
}

emit_triangle () {
	local -a Result

	Result[0]=$(rvalue ${1:?})
	Result[1]='${elements[$(('${Result[0]}'\040+\0401))]}'
	Result[2]='${elements[$(('${Result[0]}'\040+\0402))]}'
	Result[0]='${elements['${Result[0]}']}'

	echo $(join '\040' ${Result[@]})
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

	if [ ${context:0:1} -eq 1 ]
	then
		attributes[0]='declare'
	else
		attributes[0]='local'
	fi

	if [ $cut -eq 1 ]
	then
		case ${parameters[0]} in
			*'[]')
				attributes[1]='-a'
				;;
			Vector3d)
				attributes[1]='-a'

				if [ $size -lt 3 ]
				then
					value='(0\0400\0400)'
				fi
				;;
			Grid)
				attributes[1]='-A'
				;;
		esac

		case ${parameters[0]} in
			index|size*)
				attributes[${#attributes[@]}]='-i'
				;;
		esac

		name=$(octal ${parameters[1]})

		if [ $size -gt 2 ]
		then
			value=$(octal ${parameters[2]})

			case ${parameters[0]} in
				double)
					value=\'$value\'
					;;
			esac
		fi
	else
		name=$(rvalue ${parameters[0]})

		case $name in
			*'[]')
				attributes[1]='-a'
				;;
			*Vector3d*)
				attributes[1]='-a'

				if [ $size -lt 3 ]
				then
					value='(0\0400\0400)'
				fi
				;;
		esac

		case $name in
			*index*|*size*)
				if [ ${#attributes[@]} -gt 1 ]
				then
					attributes[-1]+='i'
				else
					attributes[1]='-i'
				fi
				;;
		esac

		case $name in
			*const*)
				if [ ${#attributes[@]} -gt 1 ]
				then
					attributes[-1]+='r'
				else
					attributes[1]='-r'
				fi
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
		Result=$name'='$value
	else
		Result=$name
	fi

	if [ ${context:1:1} -eq 1 ]
	then
		if [ ${#attributes[@]} -gt 0 ]
		then
			Result=$(join '\040' ${attributes[@]})'\040'$Result
		fi
		Result=$Result'\n'
	fi

	echo $Result
}

emit_vertex () {
	local -ir cut=${1:?}
	local -ir name=${2:?}

	if [ $cut -eq 1 ]
	then
		echo '(${vertices[@]:'$((3 * $name))':3})'
	else
		echo '(${vertices[@]:3\040*\040'$(rvalue $name)':3})'
	fi
}

. ./build.sh bash
