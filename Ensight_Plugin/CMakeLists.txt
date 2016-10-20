set( ENABLE_ENSIGHT_PLUGIN OFF CACHE BOOL "Enable Ensight Renderable plugin." )

if( ENABLE_ENSIGHT_PLUGIN )
  
  add_library( plugin_Ensight
    main.cpp
  )

  if(WIN32)
    target_compile_definitions( plugin_Ensight PUBLIC OPENGL_3D_WIN32=1)
  endif()
  
  if(UNIX)
    target_compile_definitions( plugin_Ensight PUBLIC OPENGL_3D_LINUX=1)
  endif()
  
  
  target_link_libraries( plugin_Ensight
    PRIVATE
    ${Boost_LIBRARIES}
    PUBLIC
    opengl_3d_kernel
    )
  
  target_compile_features( plugin_Ensight
    PRIVATE
    cxx_auto_type
    )
endif()

