#version 330 core
out vec4 color;
in vec4 vertex_color;
in vec2 vertex_uv;
in vec4 n_va, n_vb, n_vc, n_vd;

float maxcomp( in vec4 v )
{
    return max( max(v.x,v.y), max(v.z,v.w) );
}

float maxcomp( in vec2 v )
{
    return max(v.x,v.y);
}

float isEdge( in vec2 uv, vec4 va, vec4 vb, vec4 vc, vec4 vd )
{
    // float maxcomp( in vec4 v ) { return max( max(v.x,v.y), max(v.z,v.w) ); }    

    vec2 st = 1.0 - uv;

    // sides    
    vec4 wb = smoothstep( 0.85, 0.95, vec4(uv.x,
                                           st.x,
                                           uv.y,
                                           st.y) ) * ( 1.0 - va + va*vc);
    // corners
    vec4 wc = smoothstep( 0.85, 0.95, vec4(uv.x*uv.y,
                                           st.x*uv.y,
                                           st.x*st.y,
                                           uv.x*st.y) ) * (  1.0 - vb + vd*vb );
    return maxcomp( max(wb,wc) );
}

float calcOcc( in vec2 uv, vec4 va, vec4 vb, vec4 vc, vec4 vd )
{
    vec2 st = 1.0 - uv;

    // edges
    vec4 wa = vec4( uv.x, st.x, uv.y, st.y ) * vc;

    // corners
    vec4 wb = vec4(uv.x*uv.y,
                   st.x*uv.y,
                   st.x*st.y,
                   uv.x*st.y)*vd*(1.0-vc.xzyw)*(1.0-vc.zywx);
    
    return wa.x + wa.y + wa.z + wa.w +
           wb.x + wb.y + wb.z + wb.w;

}


void main()
{
    float thickness = 0.01;
    float edge = isEdge( vertex_uv, n_va, n_vb, n_vc, n_vd );
    float raw_occ = calcOcc( vertex_uv, n_va, n_vb, n_vc, n_vd );
    float occulsion = clamp( (1.0 - raw_occ) + 0.5, 0, 1);

    float occ_r = vertex_color.r * occulsion;
    float occ_b = vertex_color.b * (1 - occulsion);
    vec3  occ_color = vec3( occ_r, vertex_color.g, occ_b);
    
    color = mix( vec4(vertex_color.rgb*occulsion, 1.0), vec4(0,0,0,1), edge );   
    
}  
