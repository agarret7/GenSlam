module GenSlam

include("model.jl")
include("inference.jl")
include("visualization.jl")

export sample_scene,
       make_agent_view,
       Hypers,
       Bounds,
       static_model,
       pos_kernel,
       orn_kernel,
       pose_kernel,
       TOPDOWN_VIEW

end # module
