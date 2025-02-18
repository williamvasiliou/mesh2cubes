#!/usr/bin/env bash

walk () {
	declare -a NR
	declare -a RLENGTH
	declare -a PARENTS
	declare -a R

	for a in $@
	do
		NR[${#NR[@]}]=$(echo $a | cut -d: -f1)
		RLENGTH[${#RLENGTH[@]}]=$(echo $a | cut -d: -f2)
		PARENTS[${#PARENTS[@]}]=$(echo $a | cut -d: -f3)
		R[${#R[@]}]=$(echo $a | cut -d: -f4-)
	done

	walks=1
	while [ $walks -eq 1 ]
	do
		parent=0
		walks=0

		for N in ${NR[@]}
		do
			depth=${RLENGTH[$N]}

			if [ $depth -eq 0 ]
			then
				parent=$N
				walks=1
			elif [ $depth -eq 1 ]
			then
				PARENTS[$N]=$parent
			fi

			RLENGTH[$N]=$(($depth - 1))
		done
	done

	declare -a T=()
	declare -a parent=()

	for N in ${NR[@]}
	do
		T[$N]=\'${R[$N]}\'
		parent[$N]=${PARENTS[$N]}
	done

	echo 'declare -a T=('${T[@]}')'
	echo 'declare -a parent=('${parent[@]}')'
}

main () {
	declare -A targets=('bash' 0 'java' 1)
	target=${targets[$1]:?}

	declare -a T=('mesh2cubes' 'var:int,size,0' 'var:double[],vertices' 'var:int[],elements' 'var:Grid,grid' 'var:Vector3d,min' 'var:Vector3d,max' 'var:Vector3d,mid' 'var:double,c,1' 'var:double,t,1' 'var:double,xr,0' 'var:double,yr,0' 'var:double,zr,0' 'function:length,Vector3d,v1' 'return' 'call:sqrt' 'addDouble' 'addDouble' 'multiplyDouble' 'dot' 'v1' 'y' 'dot' 'v1' 'y' 'multiplyDouble' 'dot' 'v1' 'z' 'dot' 'v1' 'z' 'multiplyDouble' 'dot' 'v1' 'x' 'dot' 'v1' 'x' 'function:translate' 'if' 'compareInt' 'identifier' 'size' 'operator' 'gt' 'int' '0' 'glue' 'assignVector3d' 'min' 'vertex:0' 'assignVector3d' 'max' 'vertex:0' 'for' 'var' 'type' 'int' 'identifier' 'i' 'int' '1' 'compareInt' 'identifier' 'i' 'operator' 'lt' 'identifier' 'size' 'increment' 'identifier' 'i' 'glue' 'var' 'type' 'double' 'identifier' 'x' 'dot' 'vertex' 'identifier' 'i' 'x' 'var' 'type' 'double' 'identifier' 'y' 'dot' 'vertex' 'identifier' 'i' 'y' 'var' 'type' 'double' 'identifier' 'z' 'dot' 'vertex' 'identifier' 'i' 'z' 'if' 'compareDouble' 'identifier' 'x' 'operator' 'lt' 'dot' 'min' 'x' 'glue' 'assignDouble' 'dot' 'min' 'x' 'identifier' 'x' 'if' 'compareDouble' 'identifier' 'y' 'operator' 'lt' 'dot' 'min' 'y' 'glue' 'assignDouble' 'dot' 'min' 'y' 'identifier' 'y' 'if' 'compareDouble' 'identifier' 'z' 'operator' 'lt' 'dot' 'min' 'z' 'glue' 'assignDouble' 'dot' 'min' 'z' 'identifier' 'z' 'if' 'compareDouble' 'identifier' 'x' 'operator' 'gt' 'dot' 'max' 'x' 'glue' 'assignDouble' 'dot' 'max' 'x' 'identifier' 'x' 'if' 'compareDouble' 'identifier' 'y' 'operator' 'gt' 'dot' 'max' 'y' 'glue' 'assignDouble' 'dot' 'max' 'y' 'identifier' 'y' 'if' 'compareDouble' 'identifier' 'z' 'operator' 'gt' 'dot' 'max' 'z' 'glue' 'assignDouble' 'dot' 'max' 'z' 'identifier' 'z' 'assignVector3d' 'mid' 'averageVector3d' 'min' 'max' 'for' 'var' 'type' 'int' 'identifier' 'i' 'int' '0' 'compareInt' 'identifier' 'i' 'operator' 'lt' 'identifier' 'size' 'increment' 'identifier' 'i' 'glue' 'assignVector3d' 'vertex' 'identifier' 'i' 'minusVector3d' 'vertex' 'identifier' 'i' 'mid' 'assignVector3d' 'max' 'minusVector3d' 'max' 'mid' 'assignDouble' 'c' 'divideDouble' 'call:length' 'max' '25' 'assignDouble' 't' 'c' 'assignDouble' 'xr' 'ceil' 'minusDouble' 'divideDouble' 'dot' 'max' 'x' 'identifier' 'c' 'double' '0.5' 'assignDouble' 'yr' 'ceil' 'minusDouble' 'divideDouble' 'dot' 'max' 'y' 'identifier' 'c' 'double' '0.5' 'assignDouble' 'zr' 'ceil' 'minusDouble' 'divideDouble' 'dot' 'max' 'z' 'identifier' 'c' 'double' '0.5' 'function:cube,Vector3d,v1' 'var' 'type' 'double' 'identifier' 'x' 'floor' 'addDouble' 'divideDouble' 'dot' 'v1' 'x' 'identifier' 'c' '0.5' 'var' 'type' 'double' 'identifier' 'y' 'floor' 'addDouble' 'divideDouble' 'dot' 'v1' 'y' 'identifier' 'c' '0.5' 'var' 'type' 'double' 'identifier' 'z' 'floor' 'addDouble' 'divideDouble' 'dot' 'v1' 'z' 'identifier' 'c' '0.5' 'assignGrid' 'identifier' 'x' 'identifier' 'y' 'identifier' 'z' 'function:triangle,Vector3d,A,Vector3d,B,Vector3d,C' 'var' 'type' 'vector3d' 'identifier' 'u' 'minusVector3d' 'identifier' 'B' 'identifier' 'A' 'var' 'type' 'vector3d' 'identifier' 'v' 'minusVector3d' 'identifier' 'B' 'identifier' 'A' 'var' 'type' 'double' 'identifier' 'IIuII' 'double' 'call:length' 'identifier' 'u' 'var' 'type' 'double' 'identifier' 'IIvII' 'double' 'call:length' 'identifier' 'v' 'function:triangles' 'for' 'var' 'type' 'int' 'identifier' 'i' 'int' '0' 'compareInt' 'identifier' 'i' 'operator' 'lt' 'dot' 'triangles' 'size' 'assignInt' 'identifier' 'i' 'addInt' 'identifier' 'i' 'int' '3' 'glue' 'call:triangle' 'triangle' 'identifier' 'i')
	declare -a parent=(0 0 0 0 0 0 0 0 0 0 0 0 0 0 13 14 15 16 17 18 19 19 18 22 22 17 25 26 26 25 29 29 16 32 33 33 32 36 36 0 39 40 41 42 41 44 41 46 40 48 49 49 48 52 52 48 55 56 57 56 59 56 61 55 63 64 63 66 63 68 55 70 71 55 73 74 75 74 77 74 79 80 81 79 73 84 85 84 87 84 89 90 91 89 73 94 95 94 97 94 99 100 101 99 73 104 105 106 105 108 105 110 110 104 113 114 115 115 114 118 73 120 121 122 121 124 121 126 126 120 129 130 131 131 130 134 73 136 137 138 137 140 137 142 142 136 145 146 147 147 146 150 73 152 153 154 153 156 153 158 158 152 161 162 163 163 162 166 73 168 169 170 169 172 169 174 174 168 177 178 179 179 178 182 73 184 185 186 185 188 185 190 190 184 193 194 195 195 194 198 48 200 200 202 202 48 205 206 207 206 209 206 211 205 213 214 213 216 213 218 205 220 221 205 223 224 225 226 224 228 229 230 228 48 233 233 235 235 48 238 238 240 241 240 48 244 244 48 247 247 249 250 251 252 252 251 255 250 257 48 259 259 261 262 263 264 264 263 267 262 269 48 271 271 273 274 275 276 276 275 279 274 281 0 283 284 285 284 287 284 289 290 291 292 292 291 295 290 283 298 299 298 301 298 303 304 305 306 306 305 309 304 283 312 313 312 315 312 317 318 319 320 320 319 323 318 283 326 327 326 329 326 331 0 333 334 335 334 337 334 339 340 339 342 333 344 345 344 347 344 349 350 349 352 333 354 355 354 357 354 359 360 361 333 363 364 363 366 363 368 369 370 0 372 373 374 375 374 377 374 379 373 381 382 381 384 381 386 386 373 389 390 389 392 393 392 395 373 397 398 399 400)

	for (( NR=0 ; NR < ${#T[@]} ; ++NR ))
	do
		children=()
		echo $NR:${T[$NR]}

		for (( b = 0 ; b < ${#T[@]} ; ++b ))
		do
			if [ $NR -eq ${parent[$b]} ]
			then
				children[${#children[@]}]=${T[$b]}
			fi
		done

		echo ${children[@]}
	done
}

if [ $# -eq 1 ]
then
	if [ -f $1 ]
	then
		walk $(awk '{ match($0, /\t+/); gsub(/\t+/, ""); print (NR - 1) ":" (RLENGTH > 0 ? RLENGTH : 0) ":0:" $0 }' $1)
	else
		main $1
	fi
fi
