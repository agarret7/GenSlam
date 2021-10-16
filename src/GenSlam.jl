module GenSlam

include("scene.jl")
include("model.jl")
include("inference.jl")
include("visualization.jl")

export sample_static_scene,
       sample_dynamic_scene,
       gt_g_to_obs_g,
       make_agent_view,
       Hypers,
       Bounds,
       static_model,
       model,
       pos_kernel,
       orn_kernel,
       pose_kernel,
       do_smc,
       TOPDOWN_VIEW

end # module
