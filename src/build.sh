#!/usr/bin/env bash

cut () {
	local -r delim=${1:?}
	local -r str=${2:?}

	local -ir size=${#str}
	local -i offset=0

	local -a Result
	local field=

	while [ $offset -lt $size ]
	do
		substr=${str:$offset:1}

		if [ $substr = $delim ]
		then
			Result[${#Result[@]}]=$field
			field=
		else
			field+=$substr
		fi

		offset+=1
	done

	Result[${#Result[@]}]=$field

	echo ${Result[@]}
}

join () {
	local -r delim=${1:?}
	local -a parameter=(${@:2})

	local -ir size=${#parameter[@]}
	local -i offset=1
	local Result=

	if [ $size -gt 1 ]
	then
		Result=${parameter[0]}

		while [ $offset -lt $size ]
		do
			Result+=$delim
			Result+=${parameter[$offset]}

			offset+=1
		done

		echo $Result
	else
		echo ${parameter[@]}
	fi
}

walk () {
	local -a C
	local -a B
	local -a NR
	local -a RLENGTH
	local -a PARENTS
	local -a R

	for parameter in $@
	do
		C=($(cut ':' $parameter))
		B[${#B[@]}]=0
		NR[${#NR[@]}]=${C[0]}
		RLENGTH[${#RLENGTH[@]}]=${C[1]}
		PARENTS[${#PARENTS[@]}]=${C[2]}
		R[${#R[@]}]=$(join ':' ${C[@]:3})
	done

	local -a D
	local -i depth=0

	local walks=1
	while [ $walks -eq 1 ]
	do
		walks=0

		for N in ${NR[@]}
		do
			if [ $depth -eq ${RLENGTH[$N]} ]
			then
				B[$N]=${#D[@]}
				D[${#D[@]}]=$N
				walks=1
			fi
		done

		depth+=1
	done

	local -a ancestors=(0)
	for N in ${NR[@]}
	do
		depth=${RLENGTH[$N]}

		if [ $depth -gt 0 ]
		then
			ancestors[$depth]=$N
			PARENTS[$N]=${ancestors[$(($depth - 1))]}
		fi
	done

	local -a T
	local -a parent

	for N in ${NR[@]}
	do
		T[$N]=\'${R[${D[$N]}]}\'
		parent[$N]=${B[${PARENTS[${D[$N]}]}]}
	done

	echo 'local -ar T=('${T[@]}')'
	echo 'local -ar parent=('${parent[@]}')'
}

get_children () {
	local -ir R=${1:?}
	local -ir size=${#T[@]}
	local -i P=0

	local -a children=()

	local -i low=0
	local -i high=$size
	local -i index=0
	local -i found=0

	while [ $low -le $high ]
	do
		if [ $low -eq $high ]
		then
			index=$low

			if [[ $index -ge 0 &&
				$index -lt $size &&
				$R -eq ${parent[$index]} ]]
			then
				found=1
			fi

			break
		else
			index=$(($low / 2 + $high / 2))
			P=${parent[$index]}

			if [ $R -gt $P ]
			then
				low=$(($index + 1))
			elif [ $R -lt $P ]
			then
				high=$(($index - 1))
			else
				found=1
				break
			fi
		fi
	done

	if [ $found -eq 1 ]
	then
		while [[ $index -gt 0 && $R -eq ${parent[$(($index - 1))]} ]]
		do
			index=$(($index - 1))
		done

		while [[ $index -lt $size && $R -eq ${parent[$index]} ]]
		do
			children[${#children[@]}]=$index
			index+=1
		done
	fi

	echo ${children[@]}
}

octal () {
	local -r parameter=${1:?}
	local -ir size=${#parameter}
	local -i offset=0
	local Result=

	while [ $offset -lt $size ]
	do
		Result+=${od[${parameter:$offset:1}]}
		offset+=1
	done

	echo $Result
}

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

emit_and () {
	local -a Result=($(rvalue ${1:?}) $(rvalue ${2:?}))

	echo '['${Result[0]:0:-1}'&&'${Result[1]:1}']'
}

emit_assignDouble () {
	echo $(lvalue ${1:?})'='$(rvalue ${2:?})'\n'
}

emit_assignGrid () {
	echo 'grid["'$(rvalue ${1:?})','$(rvalue ${2:?})','$(rvalue ${3:?})'"]=1\n'
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

	echo '[\040$(echo\040'${Result[0]}'\040'${Result[2]}'\040|\040awk\040'\''{\040print($1\040'${Result[1]}'\040$2)\040}'\'')\040-gt\0400\040]'
}

emit_compareInt () {
	local -ar children=(${@:1:3})
	local -i child=0
	local -a Result
	for child in ${children[@]}
	do
		Result[${#Result[@]}]=$(rvalue $child)
	done

	echo '[\040'$(join '\040' ${Result[@]})'\040]'
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
	parameters=${parameters:6:-5}
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

	echo '\n'${Result[@]}'}\n'
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

emit_identifierVector3d () {
	echo '(${'${T[${1:?}]}'[@]})'
}

emit_if () {
	local -ar children=(${@:1})
	local -ir size=${#children[@]}
	local -i child=0
	local -a Result

	for child in ${children[0]}
	do
		Result[${#Result[@]}]=$(rvalue $child)
	done
	Result='if\040'$(join '\040' ${Result[@]})'\n'

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

	local -i child=0
	local Result

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
			int)
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
			*int*)
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
	local -a Result

	if [ $cut -eq 1 ]
	then
		Result[0]='${vertices['$((3 * $name))']}'
		Result[1]='${vertices['$((3 * $name + 1))']}'
		Result[2]='${vertices['$((3 * $name + 2))']}'
	else
		Result[0]=$(rvalue $name)
		Result[1]='${vertices[$((3\040*\040'${Result[0]}'\040+\0401))]}'
		Result[2]='${vertices[$((3\040*\040'${Result[0]}'\040+\0402))]}'
		Result[0]='${vertices[$((3\040*\040'${Result[0]}'))]}'
	fi

	echo '('$(join '\040' ${Result[@]})')'
}

emit () {
	local -ir R=${1:-0}
	local -r context=${2:-'11'}

	local -r root=${T[$R]}
	local -ar children=($(get_children $R))

	local -a parameters
	local -a Result
	if [ $target -lt 1 ]
	then
		Result[0]=$(octal $root)'\n'

		for child in ${children[@]}
		do
			if [ $child -gt 0 ]
			then
				for built in $(emit $child $context)
				do
					Result[${#Result[@]}]='\t'$built
				done
			fi
		done
	else
		case $root in
			mesh2cubes)
				Result[0]='#!/usr/bin/env\040bash\n\n'
				for child in ${children[@]}
				do
					if [ $child -gt 0 ]
					then
						for built in $(emit $child $context)
						do
							Result[${#Result[@]}]=$built
						done
					fi
				done

				;;
			addAssignDouble)
				Result=($(emit_addAssignDouble ${children[@]:0:2}))

				;;
			addAssignInt)
				Result=($(emit_addAssignInt ${children[@]:0:2}))

				;;
			addAssignVector3d)
				Result=($(emit_addAssignVector3d ${children[@]:0:2}))

				;;
			addDouble)
				Result=($(emit_addDouble ${children[@]:0:2}))

				;;
			and)
				Result=($(emit_and ${children[@]:0:2}))

				;;
			assignDouble)
				Result=($(emit_assignDouble ${children[@]:0:2}))

				;;
			assignGrid)
				Result=($(emit_assignGrid ${children[@]:0:3}))

				;;
			assignVector3d)
				Result=($(emit_assignVector3d ${children[@]:0:2}))

				;;
			averageVector3d)
				Result=($(emit_averageVector3d ${children[@]:0:2}))

				;;
			call:*)
				parameters=($(cut ':' $root))
				Result=($(emit_call ${parameters[1]} ${children[@]}))

				;;
			ceil)
				Result=($(emit_ceil ${children[0]}))

				;;
			compareDouble)
				Result=($(emit_compareDouble ${children[@]:0:3}))

				;;
			compareInt)
				Result=($(emit_compareInt ${children[@]:0:3}))

				;;
			divideDouble)
				Result=($(emit_divideDouble ${children[@]:0:2}))

				;;
			dot)
				Result=($(emit_dot ${children[@]:0:2}))

				;;
			dotVertex)
				Result=($(emit_dotVertex ${children[@]:0:2}))

				;;
			double)
				Result=($(emit_double ${children[0]}))

				;;
			floor)
				Result=($(emit_floor ${children[0]}))

				;;
			for)
				Result=($(emit_for ${children[@]:0:4}))

				;;
			forDouble)
				Result=($(emit_forDouble ${children[@]:0:4}))

				;;
			function:*)
				parameters=($(cut ':' $root))
				parameters=($(cut ',' ${parameters[1]}))
				Result=($(emit_function ${parameters[@]}))

				;;
			glue)
				Result=($(emit_glue ${children[@]}))

				;;
			identifier)
				Result=($(emit_identifier ${children[0]}))

				;;
			identifierVector3d)
				Result=($(emit_identifierVector3d ${children[0]}))

				;;
			if)
				Result=($(emit_if ${children[@]}))

				;;
			increment)
				Result=($(emit_increment ${children[0]}))

				;;
			int)
				Result=($(emit_int ${children[0]}))

				;;
			min)
				Result=($(emit_min ${children[@]:0:2}))

				;;
			minusAssignVector3d)
				Result=($(emit_minusAssignVector3d ${children[@]:0:2}))

				;;
			minusAssignVertex)
				Result=($(emit_minusAssignVertex ${children[@]:0:2}))

				;;
			minusDouble)
				Result=($(emit_minusDouble ${children[@]:0:2}))

				;;
			minusVector3d)
				Result=($(emit_minusVector3d ${children[@]:0:2}))

				;;
			multiplyDouble)
				Result=($(emit_multiplyDouble ${children[@]:0:2}))

				;;
			operator)
				Result=($(emit_operator ${children[0]}))

				;;
			positional)
				Result=($(emit_positional ${children[@]:0:2}))

				;;
			return)
				Result=($(emit_return ${children[0]}))

				;;
			scaleVector3d)
				Result=($(emit_scaleVector3d ${children[@]:0:2}))

				;;
			triangle)
				Result=($(emit_triangle ${children[0]}))

				;;
			type)
				Result=($(emit_type ${children[@]}))

				;;
			var)
				Result=($(emit_var 0 ${children[@]}))

				;;
			var:*)
				parameters=($(cut ':' $root))
				parameters=($(cut ',' ${parameters[1]}))
				Result=($(emit_var 1 ${parameters[@]}))

				;;
			vertex)
				Result=($(emit_vertex 0 ${children[0]}))

				;;
			vertex:*)
				parameters=($(cut ':' $root))
				Result=($(emit_vertex 1 ${parameters[1]}))

				;;
		esac
	fi

	echo ${Result[@]}
}

target () {
	local -Ar targets=('bash' 1 'java' 2)
	echo ${targets[$1]:?}
}

build () {
	local -ir index=$((${1:?} - 1))
	local -ar subdirs=('bash' 'java')
	local -r mesh2cubes='mesh2cubes'
	local -ar extensions=('sh' 'java')

	local -r subdir=${subdirs[$index]}
	local -r extension=${extensions[$index]}
	local -r path="$subdir/$mesh2cubes.$extension"

	if [[ -d $subdir && ! -a $path ]]
	then
		for built in $(emit)
		do
			printf $built >> $path
		done
	fi
}

main () {
	local -ir target=${1:?}

	local -ar T=('mesh2cubes' 'var:int,size,0' 'var:double[],vertices' 'var:int[],elements' 'var:Grid,grid' 'var:Vector3d,min' 'var:Vector3d,max' 'var:Vector3d,mid' 'var:double,c,1.0' 'var:double,t,1.0' 'var:double,xr,0.0' 'var:double,yr,0.0' 'var:double,zr,0.0' 'function:length,Vector3d,v1' 'function:translate' 'function:cube,Vector3d,v1' 'function:triangle,int,a,int,b,int,c' 'function:triangles' 'return' 'if' 'var' 'var' 'var' 'assignGrid' 'var' 'var' 'var' 'var' 'var' 'var' 'var' 'if' 'for' 'call:sqrt' 'compareInt' 'glue' 'type' 'identifier' 'floor' 'type' 'identifier' 'floor' 'type' 'identifier' 'floor' 'identifier' 'identifier' 'identifier' 'type' 'identifier' 'vertex' 'type' 'identifier' 'vertex' 'type' 'identifier' 'vertex' 'type' 'identifier' 'minusVector3d' 'type' 'identifier' 'minusVector3d' 'type' 'identifier' 'call:length' 'type' 'identifier' 'call:length' 'and' 'glue' 'var' 'compareInt' 'addAssignInt' 'glue' 'addDouble' 'identifier' 'operator' 'int' 'assignVector3d' 'assignVector3d' 'for' 'assignVector3d' 'for' 'minusAssignVector3d' 'assignDouble' 'assignDouble' 'assignDouble' 'assignDouble' 'assignDouble' 'const' 'double' 'x' 'addDouble' 'const' 'double' 'y' 'addDouble' 'const' 'double' 'z' 'addDouble' 'x' 'y' 'z' 'const' 'Vector3d' 'A' 'positional' 'const' 'Vector3d' 'B' 'positional' 'const' 'Vector3d' 'C' 'positional' 'Vector3d' 'u' 'identifier' 'identifier' 'Vector3d' 'v' 'identifier' 'identifier' 'const' 'double' 'IIuII' 'identifier' 'const' 'double' 'IIvII' 'identifier' 'compareDouble' 'compareDouble' 'var' 'var' 'scaleVector3d' 'scaleVector3d' 'var' 'forDouble' 'type' 'identifier' 'int' 'identifier' 'operator' 'dot' 'identifier' 'int' 'call:triangle' 'addDouble' 'multiplyDouble' 'size' 'gt' '0' 'identifier' 'vertex:0' 'identifier' 'vertex:0' 'var' 'compareInt' 'increment' 'glue' 'identifier' 'averageVector3d' 'var' 'compareInt' 'increment' 'glue' 'identifier' 'identifier' 'identifier' 'divideDouble' 'identifier' 'identifier' 'identifier' 'ceil' 'identifier' 'ceil' 'identifier' 'ceil' 'divideDouble' 'double' 'divideDouble' 'double' 'divideDouble' 'double' 'identifier' 'identifier' 'identifier' 'identifier' 'identifier' 'identifier' 'B' 'A' 'C' 'A' 'u' 'v' 'identifier' 'operator' 'double' 'identifier' 'operator' 'double' 'type' 'identifier' 'min' 'type' 'identifier' 'min' 'identifier' 'identifier' 'identifier' 'identifier' 'type' 'identifier' 'identifierVector3d' 'var' 'compareDouble' 'addAssignDouble' 'glue' 'int' 'i' '0' 'i' 'lt' 'triangles' 'size' 'i' '3' 'triangle' 'multiplyDouble' 'multiplyDouble' 'dot' 'dot' 'min' 'max' 'type' 'identifier' 'int' 'identifier' 'operator' 'identifier' 'identifier' 'var' 'var' 'var' 'if' 'if' 'if' 'if' 'if' 'if' 'mid' 'identifier' 'identifier' 'type' 'identifier' 'int' 'identifier' 'operator' 'identifier' 'identifier' 'minusAssignVertex' 'max' 'mid' 'c' 'call:length' 'double' 't' 'c' 'xr' 'minusDouble' 'yr' 'minusDouble' 'zr' 'minusDouble' 'dot' 'identifier' '0.5' 'dot' 'identifier' '0.5' 'dot' 'identifier' '0.5' '1' 'a' '2' 'b' '3' 'c' 'IIuII' 'gt' '0.0' 'IIvII' 'gt' '0.0' 'const' 'double' 'dy1' 'double' 'divideDouble' 'const' 'double' 'dy2' 'double' 'divideDouble' 'u' 'dy1' 'v' 'dy2' 'Vector3d' 'U' 'A' 'type' 'identifier' 'double' 'identifier' 'operator' 'double' 'identifier' 'identifier' 'var' 'forDouble' 'addAssignVector3d' 'identifier' 'dot' 'dot' 'dot' 'dot' 'v1' 'x' 'v1' 'x' 'int' 'i' '1' 'i' 'lt' 'size' 'i' 'type' 'identifier' 'dotVertex' 'type' 'identifier' 'dotVertex' 'type' 'identifier' 'dotVertex' 'compareDouble' 'glue' 'compareDouble' 'glue' 'compareDouble' 'glue' 'compareDouble' 'glue' 'compareDouble' 'glue' 'compareDouble' 'glue' 'min' 'max' 'int' 'i' '0' 'i' 'lt' 'size' 'i' 'identifier' 'identifier' 'identifier' '25.0' 'divideDouble' 'double' 'divideDouble' 'double' 'divideDouble' 'double' 'v1' 'x' 'c' 'v1' 'y' 'c' 'v1' 'z' 'c' '1.0' 'identifier' 'identifier' '1.0' 'identifier' 'identifier' 'double' 'y1' '0.0' 'y1' 'le' '1.0' 'y1' 'dy1' 'type' 'identifier' 'identifierVector3d' 'var' 'compareDouble' 'addAssignDouble' 'glue' 'identifier' 'identifier' 'i' 'v1' 'y' 'v1' 'y' 'v1' 'z' 'v1' 'z' 'double' 'x' 'identifier' 'x' 'double' 'y' 'identifier' 'y' 'double' 'z' 'identifier' 'z' 'identifier' 'operator' 'dot' 'assignDouble' 'identifier' 'operator' 'dot' 'assignDouble' 'identifier' 'operator' 'dot' 'assignDouble' 'identifier' 'operator' 'dot' 'assignDouble' 'identifier' 'operator' 'dot' 'assignDouble' 'identifier' 'operator' 'dot' 'assignDouble' 'i' 'mid' 'max' 'dot' 'identifier' '0.5' 'dot' 'identifier' '0.5' 'dot' 'identifier' '0.5' 't' 'IIuII' 't' 'IIvII' 'Vector3d' 'V' 'U' 'type' 'identifier' 'double' 'addDouble' 'operator' 'double' 'identifier' 'identifier' 'call:cube' 'addAssignVector3d' 'U' 'u' 'i' 'i' 'i' 'x' 'lt' 'min' 'x' 'dot' 'identifier' 'y' 'lt' 'min' 'y' 'dot' 'identifier' 'z' 'lt' 'min' 'z' 'dot' 'identifier' 'x' 'gt' 'max' 'x' 'dot' 'identifier' 'y' 'gt' 'max' 'y' 'dot' 'identifier' 'z' 'gt' 'max' 'z' 'dot' 'identifier' 'max' 'x' 'c' 'max' 'y' 'c' 'max' 'z' 'c' 'double' 'y2' '0.0' 'identifier' 'identifier' 'le' '1.0' 'y2' 'dy2' 'identifier' 'identifier' 'identifier' 'min' 'x' 'x' 'min' 'y' 'y' 'min' 'z' 'z' 'max' 'x' 'x' 'max' 'y' 'y' 'max' 'z' 'z' 'y1' 'y2' 'V' 'V' 'v')
	local -ar parent=(0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 13 14 15 15 15 15 16 16 16 16 16 16 16 16 17 18 19 19 20 20 20 21 21 21 22 22 22 23 23 23 24 24 24 25 25 25 26 26 26 27 27 27 28 28 28 29 29 29 30 30 30 31 31 32 32 32 32 33 34 34 34 35 35 35 35 35 35 35 35 35 35 35 36 36 37 38 39 39 40 41 42 42 43 44 45 46 47 48 48 49 50 51 51 52 53 54 54 55 56 57 58 59 59 60 61 62 62 63 63 64 65 66 66 67 68 69 69 70 70 70 70 70 70 71 71 71 72 72 72 73 73 74 75 75 76 77 78 79 79 80 80 81 81 81 81 82 82 83 83 83 83 84 84 85 85 86 86 87 87 88 88 89 89 93 93 97 97 101 101 108 108 112 112 116 116 119 120 123 124 128 132 133 133 133 134 134 134 135 135 135 136 136 136 137 137 138 138 139 139 139 140 140 140 140 141 142 143 144 145 146 146 147 148 149 150 150 151 151 155 157 159 159 159 160 160 160 161 162 162 162 162 162 162 162 162 162 163 164 164 165 165 165 166 166 166 167 168 169 170 171 172 172 173 174 175 176 177 178 179 180 181 181 182 183 183 184 185 185 186 187 188 189 190 191 192 199 200 201 202 203 204 205 205 206 207 207 208 208 209 210 210 211 212 213 214 215 216 217 218 218 218 219 219 219 220 220 221 221 221 231 232 232 233 233 234 234 235 235 238 239 240 241 242 243 244 245 245 245 246 246 246 247 247 247 248 248 249 249 250 250 251 251 252 252 253 253 255 256 257 258 259 260 261 262 263 264 264 268 269 273 273 275 275 277 277 278 278 279 281 281 282 284 284 285 302 303 303 307 308 308 316 317 318 319 320 321 322 323 324 324 324 325 325 325 325 326 326 327 328 328 329 329 330 330 331 331 343 344 345 345 346 347 348 348 349 350 351 351 352 352 352 353 354 354 354 355 356 356 356 357 358 358 358 359 360 360 360 361 362 362 362 363 373 374 375 377 377 378 379 379 380 381 381 382 393 394 396 397 406 407 408 409 409 409 410 410 410 411 411 412 412 413 414 426 430 434 436 437 438 438 439 439 440 441 442 442 443 443 444 445 446 446 447 447 448 449 450 450 451 451 452 453 454 454 455 455 456 457 458 458 459 459 463 463 464 466 466 467 469 469 470 479 480 481 482 482 483 484 485 486 487 488 488 498 498 499 504 504 505 510 510 511 516 516 517 522 522 523 528 528 529 542 543 548 549 550)

	local -Ar od=(' ' '\040' '!' '\041' '"' '\042' '#' '\043' '$' '\044' '%' '\045' '&' '\046' \' '\047' '(' '\050' ')' '\051' '*' '\052' '+' '\053' ',' '\054' '-' '\055' '.' '\056' '/' '\057' '0' '\060' '1' '\061' '2' '\062' '3' '\063' '4' '\064' '5' '\065' '6' '\066' '7' '\067' '8' '\070' '9' '\071' ':' '\072' ';' '\073' '<' '\074' '=' '\075' '>' '\076' '?' '\077' '@' '\100' 'A' '\101' 'B' '\102' 'C' '\103' 'D' '\104' 'E' '\105' 'F' '\106' 'G' '\107' 'H' '\110' 'I' '\111' 'J' '\112' 'K' '\113' 'L' '\114' 'M' '\115' 'N' '\116' 'O' '\117' 'P' '\120' 'Q' '\121' 'R' '\122' 'S' '\123' 'T' '\124' 'U' '\125' 'V' '\126' 'W' '\127' 'X' '\130' 'Y' '\131' 'Z' '\132' '[' '\133' '\' '\134' ']' '\135' '^' '\136' '_' '\137' '`' '\140' 'a' '\141' 'b' '\142' 'c' '\143' 'd' '\144' 'e' '\145' 'f' '\146' 'g' '\147' 'h' '\150' 'i' '\151' 'j' '\152' 'k' '\153' 'l' '\154' 'm' '\155' 'n' '\156' 'o' '\157' 'p' '\160' 'q' '\161' 'r' '\162' 's' '\163' 't' '\164' 'u' '\165' 'v' '\166' 'w' '\167' 'x' '\170' 'y' '\171' 'z' '\172' '{' '\173' '|' '\174' '}' '\175' '~' '\176')

	if [ $target -gt 0 ]
	then
		build $target
	else
		for built in $(emit)
		do
			printf $built
		done
	fi
}

if [ $# -eq 1 ]
then
	if [ -f $1 ]
	then
		walk $(awk '{ match($0, /^\t+/); gsub(/^\t+/, ""); print (NR - 1) ":" (RLENGTH > 0 ? RLENGTH : 0) ":0:" $0 }' $1)
	else
		main $(target $1)
	fi
elif [ $# -eq 0 ]
then
	main 0
fi
