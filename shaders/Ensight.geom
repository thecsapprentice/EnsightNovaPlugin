#version 330 core
layout (points) in;
layout (triangle_strip, max_vertices = 24) out;

uniform mat4 projection;
uniform mat4 model;
uniform mat4 view;
uniform float dx;

out vec4 vertex_color;
out vec2 vertex_uv;
out vec4 n_va, n_vb, n_vc, n_vd;

in VS_OUT {
    uint neighbors;
} gs_in[];

const uint  PXPYPZ=uint(0x1);
const uint  SXPYPZ=uint(0x2);
const uint  NXPYPZ=uint(0x4);
const uint  PXSYPZ=uint(0x8);
const uint  SXSYPZ=uint(0x10);
const uint  NXSYPZ=uint(0x20);
const uint  PXNYPZ=uint(0x40);
const uint  SXNYPZ=uint(0x80);
const uint  NXNYPZ=uint(0x100);
const uint  PXPYSZ=uint(0x200);
const uint  SXPYSZ=uint(0x400);
const uint  NXPYSZ=uint(0x800);
const uint  PXSYSZ=uint(0x1000);
const uint  SXSYSZ=uint(0x2000);
const uint  NXSYSZ=uint(0x4000);
const uint  PXNYSZ=uint(0x8000);
const uint  SXNYSZ=uint(0x10000);
const uint  NXNYSZ=uint(0x20000);
const uint  PXPYNZ=uint(0x40000);
const uint  SXPYNZ=uint(0x80000);
const uint  NXPYNZ=uint(0x100000);
const uint  PXSYNZ=uint(0x200000);
const uint  SXSYNZ=uint(0x400000);
const uint  NXSYNZ=uint(0x800000);
const uint  PXNYNZ=uint(0x1000000);
const uint  SXNYNZ=uint(0x2000000);
const uint  NXNYNZ=uint(0x4000000);
  

const vec4 cubeVerts[8] = vec4[8](
                                  vec4(-1.0 , -1.0, -1.0,0),  //LB   0
                                  vec4(-1.0, 1.0, -1.0,0), //L T   1
                                  vec4(1.0, -1.0, -1.0,0), //R B    2
                                  vec4( 1.0, 1.0, -1.0,0),  //R T   3
                                  //back face
                                  vec4(-1.0, -1.0, 1.0,0), // LB  4
                                  vec4(-1.0, 1.0, 1.0,0), // LT  5
                                  vec4(1.0, -1.0, 1.0,0),  // RB  6
                                  vec4(1.0, 1.0, 1.0,0)  // RT  7
                                  );

const uint side_neighbors[6] = uint[6] (
      SXSYNZ, //front
      PXSYSZ, //right
      SXSYPZ, //back              
      SXNYSZ, //bottom
      NXSYSZ, //left
      SXPYSZ  //top
);                                       

const int  cubeIndices[24]  = int [24]
    (
     0,1,2,3, //front
     7,6,3,2, //right
     7,5,6,4,  //back or whatever
     4,0,6,2, //btm 
     1,0,5,4, //left
     3,1,7,5
     );  

void main() {    
    vec4 transVerts[8];
    mat4 final_mat =  projection * view * model;

    for (int i=0;i<8; i++) 
        {
            transVerts[i]=final_mat * (dx * (gl_in[0].gl_Position + cubeVerts[i]/2.0));
        }

    uint cardinal_neighbors = gs_in[0].neighbors & ( SXSYPZ | SXPYSZ | PXSYSZ | NXSYSZ | SXNYSZ | SXSYNZ );
    vec4 cube_color = vec4(0.9,0.9,0.9,1.0);

    if( cardinal_neighbors == uint( SXSYPZ | SXPYSZ | PXSYSZ | NXSYSZ | SXNYSZ | SXSYNZ ) )
        return;
   
    if( uint(gs_in[0].neighbors & side_neighbors[0]) == uint(0) ){
        // Front Side
        n_va = clamp(vec4( float(gs_in[0].neighbors & uint(SXNYSZ)),
                           float(gs_in[0].neighbors & uint(SXPYSZ)),
                           float(gs_in[0].neighbors & uint(NXSYSZ)),
                           float(gs_in[0].neighbors & uint(PXSYSZ))),vec4(0.0),vec4(1.0));

        n_vb = clamp(vec4( float(gs_in[0].neighbors & uint(NXNYSZ)),
                           float(gs_in[0].neighbors & uint(NXPYSZ)),
                           float(gs_in[0].neighbors & uint(PXPYSZ)),
                           float(gs_in[0].neighbors & uint(PXNYSZ))),vec4(0.0),vec4(1.0));
    
        n_vc = clamp(vec4( float(gs_in[0].neighbors & uint(SXNYNZ)),
                           float(gs_in[0].neighbors & uint(SXPYNZ)),
                           float(gs_in[0].neighbors & uint(NXSYNZ)),
                           float(gs_in[0].neighbors & uint(PXSYNZ))),vec4(0.0),vec4(1.0));
    
        n_vd = clamp(vec4( float(gs_in[0].neighbors & uint(NXNYNZ)),
                           float(gs_in[0].neighbors & uint(NXPYNZ)),
                           float(gs_in[0].neighbors & uint(PXPYNZ)),
                           float(gs_in[0].neighbors & uint(PXNYNZ))),vec4(0.0),vec4(1.0));

        for( int i = 0; i<4; i++){
            int v = cubeIndices[i];
            gl_Position = transVerts[v];
            vertex_color = cube_color;
            if( i%4 == 0)
                vertex_uv = vec2(1,1);
            if( i%4 == 1)
                vertex_uv = vec2(0,1);
            if( i%4 == 2)
                vertex_uv = vec2(1,0);
            if( i%4 == 3)
                vertex_uv = vec2(0,0);             
            EmitVertex();
        }
        EndPrimitive();
    }

    if( uint(gs_in[0].neighbors & side_neighbors[1]) == uint(0) ){
        // Right Side
        n_va = clamp(vec4( float(gs_in[0].neighbors & uint(SXNYSZ)),
                           float(gs_in[0].neighbors & uint(SXPYSZ)),
                           float(gs_in[0].neighbors & uint(SXSYNZ)),
                           float(gs_in[0].neighbors & uint(SXSYPZ))),vec4(0.0),vec4(1.0));

        n_vb = clamp(vec4( float(gs_in[0].neighbors & uint(SXNYNZ)),
                           float(gs_in[0].neighbors & uint(SXPYNZ)),
                           float(gs_in[0].neighbors & uint(SXPYPZ)),
                           float(gs_in[0].neighbors & uint(SXNYPZ))),vec4(0.0),vec4(1.0));
    
        n_vc = clamp(vec4( float(gs_in[0].neighbors & uint(PXNYSZ)),
                           float(gs_in[0].neighbors & uint(PXPYSZ)),
                           float(gs_in[0].neighbors & uint(PXSYNZ)),
                           float(gs_in[0].neighbors & uint(PXSYPZ))),vec4(0.0),vec4(1.0));
    
        n_vd = clamp(vec4( float(gs_in[0].neighbors & uint(PXNYNZ)),
                           float(gs_in[0].neighbors & uint(PXPYNZ)),
                           float(gs_in[0].neighbors & uint(PXPYPZ)),
                           float(gs_in[0].neighbors & uint(PXNYPZ))),vec4(0.0),vec4(1.0));


        for( int i = 4; i<8; i++){
            int v = cubeIndices[i];
            gl_Position = transVerts[v];
            vertex_color = cube_color;
            if( i%4 == 0)
                vertex_uv = vec2(0,0);
            if( i%4 == 1)
                vertex_uv = vec2(1,0);
            if( i%4 == 2)
                vertex_uv = vec2(0,1);
            if( i%4 == 3)
                vertex_uv = vec2(1,1);             
            EmitVertex();
        }
        EndPrimitive();
    }

    if( uint(gs_in[0].neighbors & side_neighbors[2]) == uint(0) ){
        // Back Side
        n_va = clamp(vec4( float(gs_in[0].neighbors & uint(SXNYSZ)),
                           float(gs_in[0].neighbors & uint(SXPYSZ)),
                           float(gs_in[0].neighbors & uint(PXSYSZ)),
                           float(gs_in[0].neighbors & uint(NXSYSZ))),vec4(0.0),vec4(1.0));

        n_vb = clamp(vec4( float(gs_in[0].neighbors & uint(PXNYSZ)),
                           float(gs_in[0].neighbors & uint(PXPYSZ)),
                           float(gs_in[0].neighbors & uint(NXPYSZ)),
                           float(gs_in[0].neighbors & uint(NXNYSZ))),vec4(0.0),vec4(1.0));
    
        n_vc = clamp(vec4( float(gs_in[0].neighbors & uint(SXNYPZ)),
                           float(gs_in[0].neighbors & uint(SXPYPZ)),
                           float(gs_in[0].neighbors & uint(PXSYPZ)),
                           float(gs_in[0].neighbors & uint(NXSYPZ))),vec4(0.0),vec4(1.0));
    
        n_vd = clamp(vec4( float(gs_in[0].neighbors & uint(PXNYPZ)),
                           float(gs_in[0].neighbors & uint(PXPYPZ)),
                           float(gs_in[0].neighbors & uint(NXPYPZ)),
                           float(gs_in[0].neighbors & uint(NXNYPZ))),vec4(0.0),vec4(1.0));


        for( int i = 8; i<12; i++){
            int v = cubeIndices[i];
            gl_Position = transVerts[v];
            vertex_color = cube_color;
            if( i%4 == 0)
                vertex_uv = vec2(0,1);
            if( i%4 == 1)
                vertex_uv = vec2(0,0);
            if( i%4 == 2)
                vertex_uv = vec2(1,1);
            if( i%4 == 3)
                vertex_uv = vec2(1,0);             
            EmitVertex();
        }
        EndPrimitive();
    }

    if( uint(gs_in[0].neighbors & side_neighbors[3]) == uint(0) ){
        // Bottom Side
        n_va = clamp(vec4( float(gs_in[0].neighbors & uint(SXSYNZ)),
                           float(gs_in[0].neighbors & uint(SXSYPZ)),
                           float(gs_in[0].neighbors & uint(PXSYSZ)),
                           float(gs_in[0].neighbors & uint(NXSYSZ))),vec4(0.0),vec4(1.0));

        n_vb = clamp(vec4( float(gs_in[0].neighbors & uint(PXSYNZ)),
                           float(gs_in[0].neighbors & uint(PXSYPZ)),
                           float(gs_in[0].neighbors & uint(NXSYPZ)),
                           float(gs_in[0].neighbors & uint(NXSYNZ))),vec4(0.0),vec4(1.0));
    
        n_vc = clamp(vec4( float(gs_in[0].neighbors & uint(SXNYNZ)),
                           float(gs_in[0].neighbors & uint(SXNYPZ)),
                           float(gs_in[0].neighbors & uint(PXNYSZ)),
                           float(gs_in[0].neighbors & uint(NXNYSZ))),vec4(0.0),vec4(1.0));
    
        n_vd = clamp(vec4( float(gs_in[0].neighbors & uint(PXNYNZ)),
                           float(gs_in[0].neighbors & uint(PXNYPZ)),
                           float(gs_in[0].neighbors & uint(NXNYPZ)),
                           float(gs_in[0].neighbors & uint(NXNYNZ))),vec4(0.0),vec4(1.0));

        for( int i = 12; i<16; i++){
            int v = cubeIndices[i];
            gl_Position = transVerts[v];
            vertex_color = cube_color;
            if( i%4 == 0)
                vertex_uv = vec2(0,0);  
            if( i%4 == 1)
                vertex_uv = vec2(1,0);
            if( i%4 == 2)
                vertex_uv = vec2(0,1);
            if( i%4 == 3)
                vertex_uv = vec2(1,1);             
            EmitVertex();
        }
        EndPrimitive();
    }

    if( uint(gs_in[0].neighbors & side_neighbors[4]) == uint(0) ){
        // Left Side
        n_va = clamp(vec4( float(gs_in[0].neighbors & uint(SXNYSZ)),
                           float(gs_in[0].neighbors & uint(SXPYSZ)),
                           float(gs_in[0].neighbors & uint(SXSYPZ)),
                           float(gs_in[0].neighbors & uint(SXSYNZ))),vec4(0.0),vec4(1.0));

        n_vb = clamp(vec4( float(gs_in[0].neighbors & uint(SXNYPZ)),
                           float(gs_in[0].neighbors & uint(SXPYPZ)),
                           float(gs_in[0].neighbors & uint(SXPYNZ)),
                           float(gs_in[0].neighbors & uint(SXNYNZ))),vec4(0.0),vec4(1.0));
    
        n_vc = clamp(vec4( float(gs_in[0].neighbors & uint(NXNYSZ)),
                           float(gs_in[0].neighbors & uint(NXPYSZ)),
                           float(gs_in[0].neighbors & uint(NXSYPZ)),
                           float(gs_in[0].neighbors & uint(NXSYNZ))),vec4(0.0),vec4(1.0));
    
        n_vd = clamp(vec4( float(gs_in[0].neighbors & uint(NXNYPZ)),
                           float(gs_in[0].neighbors & uint(NXPYPZ)),
                           float(gs_in[0].neighbors & uint(NXPYNZ)),
                           float(gs_in[0].neighbors & uint(NXNYNZ))),vec4(0.0),vec4(1.0));

        for( int i = 16; i<20; i++){
            int v = cubeIndices[i];
            gl_Position = transVerts[v];
            vertex_color = cube_color;
            if( i%4 == 0)
                vertex_uv = vec2(0,0);
            if( i%4 == 1)
                vertex_uv = vec2(1,0);
            if( i%4 == 2)
                vertex_uv = vec2(0,1);
            if( i%4 == 3)
                vertex_uv = vec2(1,1);             
            EmitVertex();
        }
        EndPrimitive();
    }

    if( uint(gs_in[0].neighbors & side_neighbors[5]) == uint(0) ){
        // Top Side
        n_va = clamp(vec4( float(gs_in[0].neighbors & uint(SXSYNZ)),
                           float(gs_in[0].neighbors & uint(SXSYPZ)),
                           float(gs_in[0].neighbors & uint(NXSYSZ)),
                           float(gs_in[0].neighbors & uint(PXSYSZ))),vec4(0.0),vec4(1.0));

        n_vb = clamp(vec4( float(gs_in[0].neighbors & uint(NXSYNZ)),
                           float(gs_in[0].neighbors & uint(NXSYPZ)),
                           float(gs_in[0].neighbors & uint(PXSYPZ)),
                           float(gs_in[0].neighbors & uint(PXSYNZ))),vec4(0.0),vec4(1.0));
    
        n_vc = clamp(vec4( float(gs_in[0].neighbors & uint(SXPYNZ)),
                           float(gs_in[0].neighbors & uint(SXPYPZ)),
                           float(gs_in[0].neighbors & uint(NXPYSZ)),
                           float(gs_in[0].neighbors & uint(PXPYSZ))),vec4(0.0),vec4(1.0));
    
        n_vd = clamp(vec4( float(gs_in[0].neighbors & uint(NXPYNZ)),
                           float(gs_in[0].neighbors & uint(NXPYPZ)),
                           float(gs_in[0].neighbors & uint(PXPYPZ)),
                           float(gs_in[0].neighbors & uint(PXPYNZ))),vec4(0.0),vec4(1.0));

        for( int i = 20; i<24; i++){
            int v = cubeIndices[i];
            gl_Position = transVerts[v];
            vertex_color = cube_color;
            if( i%4 == 0)
                vertex_uv = vec2(1,0);
            if( i%4 == 1)
                vertex_uv = vec2(1,1);
            if( i%4 == 2)
                vertex_uv = vec2(0,0);
            if( i%4 == 3)
                vertex_uv = vec2(0,1);
            EmitVertex();
        }
        EndPrimitive();
    }

}  
