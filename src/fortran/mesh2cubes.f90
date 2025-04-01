MODULE mesh2cubes
        IMPLICIT NONE
        REAL (KIND=8), ALLOCATABLE, DIMENSION(:) :: vertices
        INTEGER, ALLOCATABLE, DIMENSION(:) :: elements
        LOGICAL, ALLOCATABLE, DIMENSION(:, :, :) :: grid
        REAL (KIND=8), DIMENSION(3) :: min = 0.0
        REAL (KIND=8), DIMENSION(3) :: max = 0.0
        REAL (KIND=8), DIMENSION(3) :: mid = 0.0
        REAL (KIND=8) :: c = 1.0
        REAL (KIND=8) :: t = 1.0
        INTEGER :: xr = 0
        INTEGER :: yr = 0
        INTEGER :: zr = 0
        INTEGER :: xl = 0
        INTEGER :: yl = 0
        INTEGER :: zl = 0
CONTAINS
        REAL (KIND=8) PURE FUNCTION length(v1)
                REAL (KIND=8), DIMENSION(3), INTENT(IN) :: v1
                length = SQRT(v1(1) * v1(1) + v1(2) * v1(2) + v1(3) * v1(3))
        END FUNCTION length

        SUBROUTINE translate()
                INTEGER :: count = 0
                INTEGER :: i = 0
                REAL (KIND=8) :: x = 0.0
                REAL (KIND=8) :: y = 0.0
                REAL (KIND=8) :: z = 0.0
                count = 3 * (SIZE(vertices) / 9)

                IF (count > 0) THEN
                        min = vertices(1:3)
                        max = vertices(1:3)

                        i = 1
                        DO WHILE (i < count)
                                x = vertices(3 * i + 1)
                                y = vertices(3 * i + 2)
                                z = vertices(3 * i + 3)

                                IF (x < min(1)) THEN
                                        min(1) = x
                                END IF

                                IF (y < min(2)) THEN
                                        min(2) = y
                                END IF

                                IF (z < min(3)) THEN
                                        min(3) = z
                                END IF

                                IF (x > max(1)) THEN
                                        max(1) = x
                                END IF

                                IF (y > max(2)) THEN
                                        max(2) = y
                                END IF

                                IF (z > max(3)) THEN
                                        max(3) = z
                                END IF
                                i = i + 1
                        END DO
                        mid = min / 2.0 + max / 2.0

                        i = 0
                        DO WHILE (i < count)
                                vertices(3 * i + 1:3 * i + 3) = vertices(3 * i + 1:3 * i + 3) - mid(1:3)
                                i = i + 1
                        END DO
                        max = max - mid
                        c = length(max) / 25.0
                        t = c
                        xr = CEILING(max(1) / c - 0.5)
                        yr = CEILING(max(2) / c - 0.5)
                        zr = CEILING(max(3) / c - 0.5)
                        xl = 2 * xr + 1
                        yl = 2 * yr + 1
                        zl = 2 * zr + 1

                        IF (ALLOCATED(grid)) THEN
                                DEALLOCATE(grid)
                        END IF
                        ALLOCATE(grid(xl, yl, zl))
                        grid(1:xl, 1:yl, 1:zl) = .FALSE.
                END IF
        END SUBROUTINE translate

        SUBROUTINE cube(v1)
                REAL (KIND=8), DIMENSION(3), INTENT(IN) :: v1
                INTEGER :: x = 0
                INTEGER :: y = 0
                INTEGER :: z = 0
                x = FLOOR(v1(1) / c + 0.5) + xr
                y = FLOOR(v1(2) / c + 0.5) + yr
                z = FLOOR(v1(3) / c + 0.5) + zr

                IF (x >= 0 .AND. x < xl .AND. y >= 0 .AND. y < yl .AND. z >= 0 .AND. z < zl) THEN
                        grid(x + 1, y + 1, z + 1) = .TRUE.
                END IF
        END SUBROUTINE cube

        SUBROUTINE triangle(a, b, c)
                INTEGER, INTENT(IN) :: a
                INTEGER, INTENT(IN) :: b
                INTEGER, INTENT(IN) :: c
                REAL (KIND=8), DIMENSION(3) :: AA = 0.0
                REAL (KIND=8), DIMENSION(3) :: BB = 0.0
                REAL (KIND=8), DIMENSION(3) :: CC = 0.0
                REAL (KIND=8), DIMENSION(3) :: u = 0.0
                REAL (KIND=8), DIMENSION(3) :: v = 0.0
                REAL (KIND=8) :: IIuII = 0.0
                REAL (KIND=8) :: IIvII = 0.0
                REAL (KIND=8) :: dy1 = 0.0
                REAL (KIND=8) :: dy2 = 0.0
                REAL (KIND=8), DIMENSION(3) :: UU = 0.0
                REAL (KIND=8) :: y1 = 0.0
                REAL (KIND=8), DIMENSION(3) :: VV = 0.0
                REAL (KIND=8) :: y2 = 0.0
                AA = vertices(3 * a + 1:3 * a + 3)
                BB = vertices(3 * b + 1:3 * b + 3)
                CC = vertices(3 * c + 1:3 * c + 3)
                u = BB - AA
                v = CC - AA
                IIuII = length(u)
                IIvII = length(v)

                IF (IIuII > 0.0 .AND. IIvII > 0.0) THEN
                        dy1 = t / IIuII

                        IF (dy1 > 1.0) THEN
                                dy1 = 1.0
                        END IF
                        dy2 = t / IIvII

                        IF (dy2 > 1.0) THEN
                                dy2 = 1.0
                        END IF
                        u = u * dy1
                        v = v * dy2
                        UU = AA(1:3)

                        y1 = 0.0
                        DO WHILE (y1 <= 1.0)
                                VV = UU(1:3)

                                y2 = 0.0
                                DO WHILE (y1 + y2 <= 1.0)
                                        CALL cube(VV)
                                        VV = VV + v
                                        y2 = y2 + dy2
                                END DO
                                UU = UU + u
                                y1 = y1 + dy1
                        END DO
                END IF
        END SUBROUTINE triangle

        SUBROUTINE triangles()
                INTEGER :: i = 0
                INTEGER :: count = 0
                count = SIZE(elements)

                i = 0
                DO WHILE (i < count)
                        CALL triangle(elements(i + 1), elements(i + 2), elements(i + 3))
                        i = i + 3
                END DO
        END SUBROUTINE triangles
END MODULE mesh2cubes
