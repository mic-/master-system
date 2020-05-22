-- Precalculate X and Y coordinates for the rotating vector balls
-- shown in RehaShMS.

without warning

sequence points,points2
sequence faces,order,zNormals,sinTb,cosTb
sequence pal,shades
sequence v,dv
sequence foi,soi,c
integer faceCol
integer XDIM,YDIM,XCENTRE,YCENTRE,SIZE,BPP,key
integer c1,c2
atom vscreen
atom time1,time2,frames
integer wait_retrace
sequence unique


constant zEye=-200

integer camX,camY,camZ,Factor

camX = 0
camY = 0
camZ = -256
Factor = 256

function GetScreenXY(sequence point)
    integer x0,y0
    integer numFaces,facePoints
    sequence retSeq,rs_i,point_ij,xy0
    atom point_ij_add_z

    facePoints = length(point)
    retSeq = repeat({0, 0}, facePoints)

    for j=1 to facePoints do
        point_ij = point[j]
        point_ij_add_z = point_ij[3]+camZ
        if -point_ij[3] != camZ then
            xy0 = {
                floor(camX+((Factor*point_ij[1])/point_ij_add_z)),
                floor(camY+((Factor*point_ij[2])/point_ij_add_z)),point_ij[3]
            }
        else
            xy0 = {camX, camY, point_ij[3]}
        end if
        retSeq[j] = xy0
    end for

    return retSeq
end function

-- Rotate a sequence of points
function rotate(sequence obj, sequence toRotate, sequence a)
    atom xr,yr,zr
    integer objPoints

    objPoints=length(obj)
    for i=1 to objPoints do
        if toRotate[1]=1 then
            yr = (cosTb[a[1]]*obj[i][2]) - (sinTb[a[1]]*obj[i][3])
            zr = (sinTb[a[1]]*obj[i][2]) + (cosTb[a[1]]*obj[i][3])
            obj[i][2..3] = {yr, zr}
        end if
        
        if toRotate[2]=1 then
            xr = (cosTb[a[2]]*obj[i][1]) - (sinTb[a[2]]*obj[i][3])
            zr = (sinTb[a[2]]*obj[i][1]) + (cosTb[a[2]]*obj[i][3])
            obj[i][1] = xr
            obj[i][3] = zr
        end if

        if toRotate[3]=1 then
            xr = (cosTb[a[3]]*obj[i][1]) - (sinTb[a[3]]*obj[i][2])
            yr = (sinTb[a[3]]*obj[i][1]) + (cosTb[a[3]]*obj[i][2])
            obj[i][1..2] = {xr, yr}
        end if
    end for
    return obj
end function


sinTb = {}
cosTb = {}
for i=0 to 255 do
    sinTb &= sin(i*3.1415926/128.0)
    cosTb &= cos(i*3.1415926/128.0)
end for


points2 =
{
 {-1,-1,-1},
 {1,-1,-1},
 {1,1,-1},
 {-1,1,-1},
 {-1,-1,1},
 {1,-1,1},
 {1,1,1},
 {-1,1,1}
} * 16

unique = repeat({}, 8)

v = {1, 1, 1}

while v[1] < 257 do
    points = rotate(points2, {1, 1, 1}, v)
    faces = {
        points[1..4],
        points[5..8]
    }

    for i=1 to length(points) do
        for j=i+1 to length(points) do
            if points[j][3] > points[i][3] then
                c = points[i]
                points[i] = points[j]
                points[j] = c
            end if
        end for
    end for

    points = GetScreenXY(points)

    for i=1 to 8 do
        points[i] = points[i][1..2]
        unique[i] = append(unique[i],points[i])
    end for
 
    v += 1
end while

constant fn = open("cubexy.bin","wb")

printf(1,"Found %d unique vertices\n",length(unique))


for i=1 to 8 do
    for j=1 to length(unique[i]) do
        puts(fn, unique[i][j][1])
    end for
end for

for i=1 to 8 do
    for j=1 to length(unique[i]) do
        puts(fn, unique[i][j][2])
    end for
end for

close(fn)