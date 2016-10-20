#include <RenderableManager.h>
#include <ApplicationFactory.h>
#include <Shader.h>
#include <iostream>
#include <fstream>

#include <glm/gtc/matrix_transform.hpp>
#include <glm/gtc/type_ptr.hpp>

#include <boost/filesystem.hpp>
namespace fs = boost::filesystem;

#include <float.h>

// This only works on linux
#include <endian.h>

namespace Nova {

    class EnsightRenderable : public Renderable {        

        struct Voxel {
            glm::vec3 location;
            uint32_t neighbors;
        };


        uint32_t x_res, y_res, z_res;
        std::vector< std::array<float, 3> > entry_coords;
        std::vector< unsigned int > cell_type;
        float dx;

        std::vector< Voxel > voxels;

        unsigned int VAO, VBO;

    public:
        EnsightRenderable( ApplicationFactory& app ) : Renderable( app )
        {
        }

        virtual ~EnsightRenderable(){           
        }
        
        virtual void load(std::string path){
            fs::path initial_config;
            initial_config /= path;

            std::cout << "Loading " << path << std::endl;
            fs::path load_dir = initial_config.parent_path();            
            std::string basename = initial_config.filename().stem().string();
            
            fs::path geo_filename = load_dir / (fs::path( basename + ".geo" ) );
            std::cout << "Geo File : " << geo_filename << std::endl;
            fs::path mask_filename = load_dir / (fs::path( basename + "_00.Orange_grayvalues.txt" ) );
            std::cout << "Mask File : " << mask_filename << std::endl;


            uint32_t part;
            
            // First read the header
            char header_buf[81];
            header_buf[80] = '\0';   
            std::array<float, 3> min_index{ FLT_MAX,FLT_MAX,FLT_MAX };
            std::array<float, 3> max_index{ FLT_MIN,FLT_MIN,FLT_MIN };         
            

            std::ifstream geo_file( geo_filename.string().c_str(), std::ios::binary );           
            geo_file.read( header_buf, 80 );
            std::cout << header_buf << std::endl;
            geo_file.read( header_buf, 80 );
            std::cout << header_buf << std::endl;
            geo_file.read( header_buf, 80 );
            std::cout << header_buf << std::endl;
            geo_file.read( header_buf, 80 );
            std::cout << header_buf << std::endl;
            geo_file.read( header_buf, 80 );
            std::cout << header_buf << std::endl;
            geo_file.read( header_buf, 80 );
            std::cout << header_buf << std::endl;
            geo_file.read( (char*)&part, 4 ); // Read in a part number, then two more header lines
            part = htobe32(part);
            std::cout << part << std::endl;
            geo_file.read( header_buf, 80 );
            std::cout << header_buf << std::endl;
            geo_file.read( header_buf, 80 );
            std::cout << header_buf << std::endl;

            // Now pull in the dimensions
            geo_file.read( (char*)&y_res, 4 ); // These are written swapped... WTF?
            geo_file.read( (char*)&x_res, 4 );
            geo_file.read( (char*)&z_res, 4 );
            x_res = htobe32(x_res);
            y_res = htobe32(y_res);
            z_res = htobe32(z_res);            

            std::cout << "Grid is [" << x_res << " " << y_res << " " << z_res << "]" << std::endl;

            float* indices = new float[ x_res * y_res * z_res * 3 ];
            
            union {
                uint32_t i;
                float f;
            } float2int;

            for( int dim = 0; dim < 3; dim ++ ){
                for( int offset = 0; offset < x_res * y_res * z_res; offset++){
                    unsigned int index = (dim * x_res * y_res * z_res) + offset;
                    geo_file.read( (char*)&(float2int.i), 4 );
                    float2int.i = htobe32( float2int.i );
                    indices[index] = float2int.f;
                }
            }
            
            entry_coords.reserve( x_res * y_res * z_res );
            for( int offset = 0; offset < x_res * y_res * z_res; offset++){
                std::array<float, 3> coords;
                coords[0] = indices[ offset ];
                coords[1] = indices[ offset +   (x_res * y_res * z_res)];
                coords[2] = indices[ offset + 2*(x_res * y_res * z_res)];
                for( int i = 0; i < 3; i++){
                    if( coords[i] < min_index[i] ) min_index[i] = coords[i];
                    if( coords[i] > max_index[i] ) max_index[i] = coords[i];
                }
                entry_coords.push_back( coords );             
            }
            std::cout << "Min Corner: " << min_index[0] << " " << min_index[1] << " " << min_index[2] <<std::endl;
            std::cout << "Max Corner: " << max_index[0] << " " << max_index[1] << " " << max_index[2] <<std::endl;
            std::cout << "Dx: " <<
                (max_index[0]-min_index[0]) / (x_res-1) << " " <<
                (max_index[1]-min_index[1]) / (y_res-1) << " " <<
                (max_index[2]-min_index[2]) / (z_res-1) << std::endl;
            assert( (max_index[0]-min_index[0]) / (x_res-1) == (max_index[1]-min_index[1]) / (y_res-1)
                    && 
                    (max_index[0]-min_index[0]) / (x_res-1) == (max_index[2]-min_index[2]) / (z_res-1) );
            dx = (max_index[0]-min_index[0]) / (x_res-1);

            //for( auto&& coords : entry_coords ){
            //    std::cout << "Entry: " << coords[0] << " " << coords[1] << " " << coords[2] << std::endl;
            //}
                            
            geo_file.close();
            delete [] indices;

            // Geo File is done. All geometry information is now read and ready.


            std::ifstream mask_file( mask_filename.string().c_str(), std::ios::binary );
            mask_file.read( header_buf, 80 );
            std::cout << header_buf << std::endl;
            mask_file.read( header_buf, 80 );
            std::cout << header_buf << std::endl;
            mask_file.read( (char*)&part, 4 ); // Read in a part number, then two more header lines
            part = htobe32(part);
            mask_file.read( header_buf, 80 );
            std::cout << header_buf << std::endl;

            for( int offset = 0; offset < x_res * y_res * z_res; offset++){
                uint32_t val;
                mask_file.read( (char*)&(val), 4 );
                val = htobe32( val ) > 0 ? 1 : 0;
                cell_type.push_back( val );
            }

            mask_file.close();

            // Now we put together the voxel data structures;

            const unsigned int SX = 0;
            const unsigned int SY = 0;
            const unsigned int SZ = 0;
            const unsigned int PX = y_res;
            const unsigned int NX = -y_res;
            const unsigned int PY = 1;
            const unsigned int NY = -1;
            const unsigned int PZ = x_res*y_res;
            const unsigned int NZ = -x_res*y_res;          
            
            enum NEIGHBORS { PXPYPZ=0x1, SXPYPZ=0x2, NXPYPZ=0x4,
                             PXSYPZ=0x8, SXSYPZ=0x10, NXSYPZ=0x20,
                             PXNYPZ=0x40, SXNYPZ=0x80, NXNYPZ=0x100,

                             PXPYSZ=0x200, SXPYSZ=0x400, NXPYSZ=0x800,
                             PXSYSZ=0x1000, SXSYSZ=0x2000, NXSYSZ=0x4000,
                             PXNYSZ=0x8000, SXNYSZ=0x10000, NXNYSZ=0x20000,

                             PXPYNZ=0x40000, SXPYNZ=0x80000, NXPYNZ=0x100000,
                             PXSYNZ=0x200000, SXSYNZ=0x400000, NXSYNZ=0x800000,
                             PXNYNZ=0x1000000, SXNYNZ=0x2000000, NXNYNZ=0x4000000 };


#define ADD_NEIGHBOR( X_DIR, Y_DIR, Z_DIR ) if( flat_index+(X_DIR+Y_DIR+Z_DIR) >= 0\
                                && flat_index+(X_DIR+Y_DIR+Z_DIR) < (x_res*y_res*z_res)\
                                && cell_type[flat_index+(X_DIR+Y_DIR+Z_DIR)] )\
                                vox.neighbors = vox.neighbors | ( X_DIR ## Y_DIR ## Z_DIR );

            for( int i = 0; i < x_res; i++ ){
                for( int j = 0; j < y_res; j++ ){
                    for( int k = 0; k < z_res; k++ ){
                        unsigned int flat_index = k*(x_res*y_res) + i*(y_res) + j;

                        if( cell_type[flat_index] ){
                            Voxel vox;
                            vox.location.x = i;
                            vox.location.y = j;
                            vox.location.z = k;
                            vox.neighbors = 0;                            
                            // TODO:: Now we need to build all the neighbors
                            
                            ADD_NEIGHBOR(PX,PY,PZ);
                            ADD_NEIGHBOR(SX,PY,PZ);
                            ADD_NEIGHBOR(NX,PY,PZ);
                            ADD_NEIGHBOR(PX,SY,PZ);
                            ADD_NEIGHBOR(SX,SY,PZ);
                            ADD_NEIGHBOR(NX,SY,PZ);
                            ADD_NEIGHBOR(PX,NY,PZ);
                            ADD_NEIGHBOR(SX,NY,PZ);
                            ADD_NEIGHBOR(NX,NY,PZ);

                            ADD_NEIGHBOR(PX,PY,SZ);
                            ADD_NEIGHBOR(SX,PY,SZ);
                            ADD_NEIGHBOR(NX,PY,SZ);
                            ADD_NEIGHBOR(PX,SY,SZ);
                            ADD_NEIGHBOR(SX,SY,SZ);
                            ADD_NEIGHBOR(NX,SY,SZ);
                            ADD_NEIGHBOR(PX,NY,SZ);
                            ADD_NEIGHBOR(SX,NY,SZ);
                            ADD_NEIGHBOR(NX,NY,SZ);

                            ADD_NEIGHBOR(PX,PY,NZ);
                            ADD_NEIGHBOR(SX,PY,NZ);
                            ADD_NEIGHBOR(NX,PY,NZ);
                            ADD_NEIGHBOR(PX,SY,NZ);
                            ADD_NEIGHBOR(SX,SY,NZ);
                            ADD_NEIGHBOR(NX,SY,NZ);
                            ADD_NEIGHBOR(PX,NY,NZ);
                            ADD_NEIGHBOR(SX,NY,NZ);
                            ADD_NEIGHBOR(NX,NY,NZ);

                            voxels.push_back( vox );

                        }
                    }
                }
            }

        }


        virtual void initializeBuffers(){

            glGenVertexArrays(1,&VAO);
            glGenBuffers(1,&VBO);
            glBindVertexArray(VAO);
            glBindBuffer(GL_ARRAY_BUFFER,VBO);
            glBufferData(GL_ARRAY_BUFFER,voxels.size()*sizeof(Voxel),&voxels[0],GL_STATIC_DRAW);
            glEnableVertexAttribArray(0);
            glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, sizeof( Voxel ), (GLvoid*)0);
            glEnableVertexAttribArray(1);
            glVertexAttribIPointer(1, 1, GL_UNSIGNED_INT, sizeof( Voxel ) , (GLvoid*)(sizeof(glm::vec3)));
            glBindVertexArray(0);

            for( int i = 0; i < 5 ; i++ ){
                std::cout << "Voxel: " << 
                    voxels.at(i).location.x << " " <<
                    voxels.at(i).location.y << " " <<
                    voxels.at(i).location.z << ":  " <<
                    std::hex <<
                    voxels.at(i).neighbors << std::endl;

            }


        }


        virtual void draw(){
            glm::mat4 projection,view,model;
            view = _app.GetWorld().Get_ViewMatrix();
            model = _app.GetWorld().Get_ModelMatrix();
            projection = _app.GetWorld().Get_ProjectionMatrix();

            auto shader = _app.GetShaderManager().GetShader("Ensight");
            shader->SetMatrix4("projection",projection);
            shader->SetMatrix4("view",view);
            shader->SetMatrix4("model",model);
            shader->SetFloat("dx",dx);

            glBindVertexArray(VAO);
            glDrawArrays(GL_POINTS, 0, voxels.size());
            glBindVertexArray(0);
        }

        virtual bool selectable() { return false; };

        virtual float hit_test( glm::vec3 start_point, glm::vec3 end_point )
        {
        }

        virtual glm::vec4 bounding_sphere()
        {
        }

        virtual void assign_selection( glm::vec3 start_point, glm::vec3 end_point, glm::vec3 intersection )
        {
        }

        virtual void unassign_selection()
        {
        }
    };

  
  class EnsightRenderableFactory : public RenderableFactory {
  public:
    EnsightRenderableFactory() : RenderableFactory()
    {}
    
    virtual ~EnsightRenderableFactory() {}

    virtual std::unique_ptr<Renderable> Create( ApplicationFactory& app, std::string path ){
      EnsightRenderable* renderable = new EnsightRenderable(app);
      renderable->load( path );
      renderable->initializeBuffers();
      return std::unique_ptr<Renderable>( renderable );
    }
    
    virtual bool AcceptExtension(std::string ext) const {
        if( ext == "case" )
            return true;
    };

  };

}


extern "C" void registerPlugin(Nova::ApplicationFactory& app) {
  app.GetRenderableManager().AddFactory( std::move( std::unique_ptr<Nova::RenderableFactory>( new Nova::EnsightRenderableFactory() )));
}

extern "C" int getEngineVersion() {
  return Nova::API_VERSION;
}
