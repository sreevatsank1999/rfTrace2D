#ifndef RAYTRACE2D_H
#define RAYTRACE2D_H

#include "hqz/ztrace.h"
#include "hqz/path.h"
#include "rapidjson/filereadstream.h"
#include "rapidjson/document.h"
#include <vector>
#include <stdint.h>
#include <time.h>
#include <assert.h>
#include <type_traits>

template<class T>
using matrix=std::vector<std::vector<T>>;

namespace rt2D
{
    class raytrace2D
    {
    private:
        ZTrace pathTracer;      // RayTracing engine
        matrix<Paths> paths_all;            // all Paths from S to D
        const std::vector<Vec2> S,D;    

        uint32_t timelimit;         // Max compute time (seconds)
        uint32_t nbtrace_min;         // min paths to compute 
        uint32_t batchsize;         // batchsize of rays to trace 
    public:
        raytrace2D(FILE* configfile, const std::vector<Vec2> &source, const std::vector<Vec2> &dest, uint32_t min_traces=10, uint32_t limT=100, uint32_t _batchsize=100000);
        raytrace2D(rapidjson::Document system_config, const std::vector<Vec2> &source, const std::vector<Vec2> &dest, uint32_t min_traces=10, uint32_t limT=100, uint32_t _batchsize=100000);
        ~raytrace2D();

        // Trace Paths
        Paths trace();
        
        /*  getter-setter Fn.
        inline void set_timelimit(uint32_t limT);
        inline uint32_t get_timelimit();

        inline void set_nbtrace_min(uint32_t min_traces);
        inline uint32_t get_nbtrace_min();
        */
    private:
        rapidjson::Document get_system_config(FILE* configfile) const;
        Paths trace_all(uint32_t nbRays);

        template<class T, std::enable_if_t<std::is_same<T,Paths>::value,bool> = true>
        void filter_StoD_paths(T&& paths);      //  is_same_type<T,Paths>

        bool is_intersect_circle(Vec2 x1, Vec2 x2, Vec2 O, double r) const;
        
    };
    
    raytrace2D::raytrace2D(FILE* configfile, const std::vector<Vec2> &source, const std::vector<Vec2> &dest, uint32_t min_traces=10, uint32_t limT=100,  uint32_t _batchsize=100000)
        : pathTracer(get_system_config(configfile)),
        S(source), D(dest),
        timelimit(limT), nbtrace_min(min_traces), batchsize(_batchsize)
    {
        paths_all.resize(S.size());
        for(auto &paths_s : paths_all)    paths_s.resize(D.size());
    }
    
    raytrace2D::raytrace2D(rapidjson::Document system_config, const std::vector<Vec2> &source, const std::vector<Vec2> &dest, uint32_t min_traces=10, uint32_t limT=100, uint32_t _batchsize=100000)
        : pathTracer(system_config),
        S(source), D(dest),
        timelimit(limT), nbtrace_min(min_traces), batchsize(_batchsize)
    {
        paths_all.resize(S.size());
        for(auto &paths_s : paths_all)    paths_s.resize(D.size());
    }
    
    raytrace2D::~raytrace2D()
    {
    }
    
    Paths raytrace2D::trace(){
        
        time_t starttime = time(0);

        Paths _P_;        // reused datastructure to forward paths data

        for(int i=0; i<paths_all.size(); i++)
            for(int j=0; j<paths_all[i].size(); j++)
                while (paths_all[i][j].size() < nbtrace_min)
                {                   
                    time_t now = time(0);
                    if (difftime(now,starttime) > timelimit)
                        break;

                    pathTracer.traceRays(_P_,batchsize);
                    filter_StoD_paths(std::move(_P_));

                    _P_.clear();

                }
                

    }

    template<class T, std::enable_if_t<std::is_same<T,Paths>::value,bool>>
    void raytrace2D::filter_StoD_paths(T&& paths){
        
        double thld_r; // Todo: define 

        for(auto &path : paths){
            Vec2 p_1 = path.get_origin();

            for(int i=0; i<path.size(); i++)
                for(int di=0; di<D.size(); di++)    
                    if (is_intersect_circle(p_1,path[i],D[di],thld_r)){
                        int si = std::find(S.begin(),S.end(),p_1) - S.begin();
                        assert(si != S.size());

                        path.erase_last(path.size()-(i+1));     // Erase path beyond the point of intersection
                        path[i] = S[si];                        // Tweak the path to terminate at Destination

                        //move terminated path to output
                        paths_all[si][di] = (std::is_rvalue_reference<T>::value ? std::move(path) : path);
                    }
        }
    }

    bool raytrace2D::is_intersect_circle(Vec2 x1, Vec2 x2, Vec2 O, double r) const {
        Vec2 c = (x2-x1);
        Vec2 d = (O-x1);
        double t = (d.x*c.x + d.y*c.y);
        double sq = (c.x*c.x + c.y*c.y);

        return((c.y*d.x + c.x*d.y)*(c.y*d.x + c.x*d.y) < r*r*sq) && (0 <= t && t <= sq);

    }

    rapidjson::Document raytrace2D::get_system_config(FILE* configfile) const {
        char buff[1024]; 
        rapidjson::FileReadStream config_reader(configfile,buff,1024);
        rapidjson::Document system_config; system_config.ParseStream<0>(config_reader);

        return system_config;
    }

    Paths raytrace2D::trace_all(uint32_t nbRays){

        Paths allPaths;
        pathTracer.traceRays(allPaths,nbRays);

        return allPaths;
    }
/* 
    inline void raytrace2D::set_timelimit(uint32_t limT){
        timelimit = limT;
    }
    inline uint32_t raytrace2D::get_timelimit(){
        return timelimit;
    }

    inline void raytrace2D::set_nbtrace_min(uint32_t min_traces){
        nbtrace_min = min_traces;
    }
    inline uint32_t raytrace2D::get_nbtrace_min(){
        return nbtrace_min;
    }
*/
}















#endif