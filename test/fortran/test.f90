PROGRAM TEST
        USE mesh2cubes
        IMPLICIT NONE
        INTEGER :: ios = 0
        REAL (KIND=8) :: v = 0.0
        REAL (KIND=8), ALLOCATABLE, DIMENSION(:) :: buffer
        INTEGER :: count = 0
        INTEGER :: capacity = 128
        CHARACTER(LEN=15), DIMENSION(5) :: line
        INTEGER :: x = 0
        INTEGER :: y = 0
        INTEGER :: z = 0

        ALLOCATE(buffer(capacity))
        DO
                READ (UNIT=5, FMT=*, IOSTAT=ios) v
                IF (ios == 0) THEN
                        count = count + 1
                        buffer(count) = v

                        IF (count >= capacity) THEN
                                ALLOCATE(vertices(capacity))
                                vertices(1:capacity) = buffer(1:capacity)

                                DEALLOCATE(buffer)
                                ALLOCATE(buffer(capacity * 2))
                                buffer(1:capacity) = vertices(1:capacity)

                                capacity = capacity * 2
                                DEALLOCATE(vertices)
                        END IF
                ELSE
                        EXIT
                END IF
        END DO

        ALLOCATE(vertices(count))
        vertices(1:count) = buffer(1:count)
        DEALLOCATE(buffer)

        count = 3 * (SIZE(vertices) / 9)
        ALLOCATE(elements(count))

        x = 0
        DO WHILE (x < count)
                elements(x + 1) = x
                elements(x + 2) = x + 1
                elements(x + 3) = x + 2
                x = x + 3
        END DO

        CALL translate
        CALL triangles

        DEALLOCATE(elements)
        DEALLOCATE(vertices)

        IF (ALLOCATED(grid)) THEN
                WRITE (UNIT=line(1), FMT='(F15.7)') max(1)
                WRITE (UNIT=line(2), FMT='(F15.7)') max(2)
                WRITE (UNIT=line(3), FMT='(F15.7)') max(3)
                WRITE (UNIT=line(4), FMT='(F15.7)') t
                WRITE (UNIT=line(5), FMT='(F15.7)') c
                PRINT '(4(A, A1), A)', TRIM(ADJUSTL(line(1))), ',', TRIM(ADJUSTL(line(2))), ',', TRIM(ADJUSTL(line(3))), ',', TRIM(ADJUSTL(line(4))), ',', TRIM(ADJUSTL(line(5)))
                PRINT '(2(I0, A1), I0)', xr, ',', yr, ',', zr

                y = 1
                DO WHILE (y <= yl)
                        z = 1
                        DO WHILE (z <= zl)
                                x = 1
                                DO WHILE (x <= xl)
                                        IF (grid(x, y, z)) THEN
                                                PRINT '(2(I0, A1), I0)', (x - xr - 1), ',', (y - yr - 1), ',', (z - zr - 1)
                                        END IF
                                        x = x + 1
                                END DO
                                z = z + 1
                        END DO
                        y = y + 1
                END DO
                DEALLOCATE(grid)
        END IF
END PROGRAM TEST
